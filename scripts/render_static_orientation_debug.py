#!/usr/bin/env python3
"""Render software direction-field previews for the static fingerprint image."""

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MEM_PATH = ROOT / "fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/fingerprint_static_256.mem"
OUT_DIR = ROOT / "fingerprint_direction_fpga/previews"
IMAGE_W = 256
IMAGE_H = 256
BLOCK = 16
SCALE = 2


def png_chunk(chunk_type, data):
    body = chunk_type + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def write_png(rgb, width, height, path):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        start = y * width * 3
        raw.extend(rgb[start:start + width * 3])

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = zlib.compress(bytes(raw), level=9)
    with path.open("wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(png_chunk(b"IHDR", ihdr))
        f.write(png_chunk(b"IDAT", data))
        f.write(png_chunk(b"IEND", b""))


def read_mem(path):
    values = [int(line.strip(), 16) for line in path.read_text(encoding="ascii").splitlines() if line.strip()]
    if len(values) != IMAGE_W * IMAGE_H:
        raise ValueError(f"expected {IMAGE_W * IMAGE_H} pixels, got {len(values)}")
    return values


def pixel(gray, x, y):
    return gray[y * IMAGE_W + x]


def sobel(gray, x, y):
    p00 = pixel(gray, x - 1, y - 1)
    p01 = pixel(gray, x, y - 1)
    p02 = pixel(gray, x + 1, y - 1)
    p10 = pixel(gray, x - 1, y)
    p12 = pixel(gray, x + 1, y)
    p20 = pixel(gray, x - 1, y + 1)
    p21 = pixel(gray, x, y + 1)
    p22 = pixel(gray, x + 1, y + 1)
    gx = -p00 + p02 - 2 * p10 + 2 * p12 - p20 + p22
    gy = p00 + 2 * p01 + p02 - p20 - 2 * p21 - p22
    return gx, gy


def angle_to_bin(theta_deg):
    theta_deg %= 180.0
    return int(math.floor((theta_deg + 11.25) / 22.5)) & 7


def bin_to_angle(direction):
    return direction * 22.5


def display_bin(direction):
    return {1: 7, 2: 6, 3: 5, 5: 3, 6: 2, 7: 1}.get(direction, direction)


def current_pixel_mode_map(gray, rotate_to_tangent):
    bins = [[0 for _ in range(16)] for _ in range(16)]
    for by in range(16):
        for bx in range(16):
            counts = [0] * 8
            for y in range(max(1, by * BLOCK), min(IMAGE_H - 1, (by + 1) * BLOCK)):
                for x in range(max(1, bx * BLOCK), min(IMAGE_W - 1, (bx + 1) * BLOCK)):
                    gx, gy = sobel(gray, x, y)
                    if gx == 0 and gy == 0:
                        continue
                    theta = math.degrees(math.atan2(gy, gx))
                    if rotate_to_tangent:
                        theta += 90.0
                    counts[angle_to_bin(theta)] += 1
            bins[by][bx] = max(range(8), key=lambda i: counts[i])
    return bins


def structure_tensor_map(gray):
    bins = [[0 for _ in range(16)] for _ in range(16)]
    for by in range(16):
        for bx in range(16):
            v_x = 0
            v_y = 0
            for y in range(max(1, by * BLOCK), min(IMAGE_H - 1, (by + 1) * BLOCK)):
                for x in range(max(1, bx * BLOCK), min(IMAGE_W - 1, (bx + 1) * BLOCK)):
                    gx, gy = sobel(gray, x, y)
                    # Match the RTL: rotate Sobel normal (Gx, Gy) to ridge
                    # tangent (-Gy, Gx) before tensor accumulation.
                    v_x += gy * gy - gx * gx
                    v_y -= 2 * gx * gy
            ridge_theta = 0.5 * math.degrees(math.atan2(v_y, v_x))
            bins[by][bx] = display_bin(angle_to_bin(ridge_theta))
    return bins


def synthetic_phase_tangent_map():
    bins = [[0 for _ in range(16)] for _ in range(16)]
    cx = (IMAGE_W - 1) / 2.0
    cy = (IMAGE_H - 1) / 2.0
    for by in range(16):
        for bx in range(16):
            # Use the center of the local block. This is only a diagnostic
            # reference for the generated static image, not a hardware input.
            x = bx * BLOCK + BLOCK / 2.0
            y = by * BLOCK + BLOCK / 2.0
            dx = x - cx
            dy = y - cy
            radius2 = dx * dx + dy * dy
            radius = math.sqrt(radius2)
            if radius < 1.0:
                bins[by][bx] = 0
                continue
            dphase_dx = 0.27 * dx / radius - 3.6 * dy / radius2 + 0.018
            dphase_dy = 0.27 * dy / radius + 3.6 * dx / radius2 - 0.012
            normal_theta = math.degrees(math.atan2(dphase_dy, dphase_dx))
            bins[by][bx] = angle_to_bin(normal_theta + 90.0)
    return bins


def draw_line(rgb, width, height, cx, cy, angle_deg, length=22, color=(255, 255, 255)):
    rad = math.radians(angle_deg)
    dx = math.cos(rad)
    dy = math.sin(rad)
    for step in range(-length // 2, length // 2 + 1):
        x = int(round(cx + dx * step))
        y = int(round(cy + dy * step))
        for yy in range(y - 1, y + 2):
            for xx in range(x - 1, x + 2):
                if 0 <= xx < width and 0 <= yy < height:
                    idx = (yy * width + xx) * 3
                    rgb[idx:idx + 3] = bytes(color)


def render_overlay(gray, bins, path, repeat=1):
    width = IMAGE_W * SCALE
    height = IMAGE_H * SCALE
    rgb = bytearray(width * height * 3)
    for y in range(height):
        for x in range(width):
            v = gray[(y // SCALE) * IMAGE_W + (x // SCALE)]
            idx = (y * width + x) * 3
            rgb[idx:idx + 3] = bytes((v, v, v))

    offsets = [(0, 0)] if repeat == 1 else [(-4, -4), (4, -4), (-4, 4), (4, 4)]
    for by in range(16):
        for bx in range(16):
            base_x = (bx * BLOCK + BLOCK / 2) * SCALE
            base_y = (by * BLOCK + BLOCK / 2) * SCALE
            for ox, oy in offsets:
                draw_line(rgb, width, height, base_x + ox * SCALE, base_y + oy * SCALE, bin_to_angle(bins[by][bx]))
    write_png(rgb, width, height, path)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    gray = read_mem(MEM_PATH)

    maps = {
        "debug_gradient_normal_overlay.png": current_pixel_mode_map(gray, rotate_to_tangent=False),
        "debug_pixel_tangent_overlay.png": current_pixel_mode_map(gray, rotate_to_tangent=True),
        "debug_tensor_tangent_overlay.png": structure_tensor_map(gray),
        "debug_synthetic_truth_tangent_overlay.png": synthetic_phase_tangent_map(),
    }
    for filename, direction_map in maps.items():
        render_overlay(gray, direction_map, OUT_DIR / filename)
    render_overlay(gray, maps["debug_tensor_tangent_overlay.png"], OUT_DIR / "debug_tensor_tangent_dense_overlay.png", repeat=4)
    for filename in maps:
        print(f"WROTE {OUT_DIR / filename}")
    print(f"WROTE {OUT_DIR / 'debug_tensor_tangent_dense_overlay.png'}")


if __name__ == "__main__":
    main()
