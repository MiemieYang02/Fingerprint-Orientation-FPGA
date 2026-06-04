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
BLOCK = 4
SCALE = 2
DIR_BINS = 16
DIR_STEP_DEG = 180.0 / DIR_BINS
GRID_W = IMAGE_W // BLOCK
GRID_H = IMAGE_H // BLOCK
GRADIENT_THRESHOLD = 10
MIN_SMOOTH_NEIGHBORS = 4
MIN_SMOOTH_STRENGTH = 512


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
    return int(math.floor((theta_deg + DIR_STEP_DEG / 2.0) / DIR_STEP_DEG)) & (DIR_BINS - 1)


def bin_to_angle(direction):
    return direction * DIR_STEP_DEG


def current_pixel_mode_map(gray, rotate_to_tangent):
    bins = [[None for _ in range(GRID_W)] for _ in range(GRID_H)]
    for by in range(GRID_H):
        for bx in range(GRID_W):
            counts = [0] * DIR_BINS
            for y in range(max(1, by * BLOCK), min(IMAGE_H - 1, (by + 1) * BLOCK)):
                for x in range(max(1, bx * BLOCK), min(IMAGE_W - 1, (bx + 1) * BLOCK)):
                    gx, gy = sobel(gray, x, y)
                    if gx == 0 and gy == 0:
                        continue
                    theta = math.degrees(math.atan2(gy, gx))
                    if rotate_to_tangent:
                        theta += 90.0
                    counts[angle_to_bin(theta)] += 1
            bins[by][bx] = max(range(DIR_BINS), key=lambda i: counts[i])
    return bins


def structure_tensor_map(gray):
    tensor_x = [[0 for _ in range(GRID_W)] for _ in range(GRID_H)]
    tensor_y = [[0 for _ in range(GRID_W)] for _ in range(GRID_H)]
    active = [[False for _ in range(GRID_W)] for _ in range(GRID_H)]
    bins = [[0 for _ in range(GRID_W)] for _ in range(GRID_H)]
    for by in range(GRID_H):
        for bx in range(GRID_W):
            v_x = 0
            v_y = 0
            votes = 0
            for y in range(max(1, by * BLOCK), min(IMAGE_H - 1, (by + 1) * BLOCK)):
                for x in range(max(1, bx * BLOCK), min(IMAGE_W - 1, (bx + 1) * BLOCK)):
                    gx, gy = sobel(gray, x, y)
                    if abs(gx) + abs(gy) < GRADIENT_THRESHOLD:
                        continue
                    v_x += gx * gx - gy * gy
                    v_y += 2 * gx * gy
                    votes += 1
            tensor_x[by][bx] = v_x
            tensor_y[by][bx] = v_y
            active[by][bx] = votes >= 3

    for by in range(1, GRID_H - 1):
        for bx in range(1, GRID_W - 1):
            sx = 0
            sy = 0
            votes = 0
            for oy in (-1, 0, 1):
                for ox in (-1, 0, 1):
                    yy = by + oy
                    xx = bx + ox
                    if active[yy][xx]:
                        sx += tensor_x[yy][xx]
                        sy += tensor_y[yy][xx]
                        votes += 1
            if votes >= MIN_SMOOTH_NEIGHBORS and abs(sx) + abs(sy) >= MIN_SMOOTH_STRENGTH:
                normal_theta = 0.5 * math.degrees(math.atan2(sy, sx))
                bins[by][bx] = angle_to_bin(normal_theta + 90.0)
            else:
                bins[by][bx] = None
    return bins


def synthetic_phase_tangent_map():
    bins = [[0 for _ in range(GRID_W)] for _ in range(GRID_H)]
    cx = (IMAGE_W - 1) / 2.0
    cy = (IMAGE_H - 1) / 2.0
    for by in range(GRID_H):
        for bx in range(GRID_W):
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


def draw_line(rgb, width, height, cx, cy, angle_deg, length=7, color=(255, 255, 255)):
    rad = math.radians(angle_deg)
    dx = math.cos(rad)
    dy = math.sin(rad)
    for step in range(-length // 2, length // 2 + 1):
        x = int(round(cx + dx * step))
        y = int(round(cy + dy * step))
        if 0 <= x < width and 0 <= y < height:
            idx = (y * width + x) * 3
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

    offsets = [(0, 0)] if repeat == 1 else [(-1, -1), (1, -1), (-1, 1), (1, 1)]
    for by in range(GRID_H):
        for bx in range(GRID_W):
            base_x = (bx * BLOCK + BLOCK / 2) * SCALE
            base_y = (by * BLOCK + BLOCK / 2) * SCALE
            if bins[by][bx] is None:
                continue
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
