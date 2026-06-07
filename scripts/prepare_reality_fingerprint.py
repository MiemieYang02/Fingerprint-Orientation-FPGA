#!/usr/bin/env python3
"""Prepare a real fingerprint photo for the FPGA static-image pipeline.

The hardware still receives a simple 256x256 grayscale stream. This script does
the PC-side work that a future camera/DDR ingress stage will eventually replace:
center crop, grayscale conversion, illumination flattening, light smoothing, and
software direction-field preview generation.
"""

import argparse
import math
import struct
import zlib
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = Path(r"C:\Users\miemie02\Desktop\指纹3reality.png")
OUT_DIR = ROOT / "fingerprint_direction_fpga" / "previews"
MEM_PATH = ROOT / "fingerprint_direction_fpga" / "fingerprint_direction_fpga.srcs" / "sources_1" / "new" / "image" / "fingerprint_reality_256.mem"
PNG_PATH = OUT_DIR / "fingerprint_reality_256.png"
OVERLAY_PATH = OUT_DIR / "fingerprint_reality_orientation_overlay.png"

IMAGE_W = 256
IMAGE_H = 256
BLOCK = 8
SCALE = 2
GRADIENT_THRESHOLD = 10
MIN_BLOCK_VOTES = 8


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


def center_crop_square(img):
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def preprocess_image(path):
    img = Image.open(path).convert("RGB")
    gray = ImageOps.grayscale(center_crop_square(img))
    gray = gray.resize((IMAGE_W, IMAGE_H), Image.Resampling.BILINEAR)

    # Real finger photos have slow illumination changes across the skin. Remove
    # that low-frequency background first, then gently smooth high-frequency
    # sensor noise before Sobel.
    background = gray.filter(ImageFilter.GaussianBlur(radius=18))
    flattened = ImageChops.add(ImageChops.subtract(gray, background), Image.new("L", gray.size, 128))
    enhanced = ImageOps.autocontrast(flattened, cutoff=1)
    smoothed = enhanced.filter(ImageFilter.GaussianBlur(radius=0.7))
    return list(smoothed.getdata())


def write_mem(gray, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(f"{value:02x}\n" for value in gray), encoding="ascii")


def gray_to_rgb(gray):
    rgb = bytearray(IMAGE_W * IMAGE_H * 3)
    for y in range(IMAGE_H):
        for x in range(IMAGE_W):
            value = gray[y * IMAGE_W + x]
            idx = (y * IMAGE_W + x) * 3
            rgb[idx:idx + 3] = bytes((value, value, value))
    return rgb


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


def build_tensor_field(gray):
    blocks_x = IMAGE_W // BLOCK
    blocks_y = IMAGE_H // BLOCK
    tensor_x = [[0 for _ in range(blocks_x)] for _ in range(blocks_y)]
    tensor_y = [[0 for _ in range(blocks_x)] for _ in range(blocks_y)]
    active = [[False for _ in range(blocks_x)] for _ in range(blocks_y)]

    for by in range(blocks_y):
        for bx in range(blocks_x):
            votes = 0
            sx = 0
            sy = 0
            for y in range(max(1, by * BLOCK), min(IMAGE_H - 1, (by + 1) * BLOCK)):
                for x in range(max(1, bx * BLOCK), min(IMAGE_W - 1, (bx + 1) * BLOCK)):
                    gx, gy = sobel(gray, x, y)
                    if abs(gx) + abs(gy) < GRADIENT_THRESHOLD:
                        continue
                    # Match the RTL: rotate Sobel normal (Gx, Gy) to ridge
                    # tangent (-Gy, Gx) before tensor accumulation.
                    sx += gy * gy - gx * gx
                    sy -= 2 * gx * gy
                    votes += 1
            tensor_x[by][bx] = sx
            tensor_y[by][bx] = sy
            active[by][bx] = votes >= MIN_BLOCK_VOTES
    return tensor_x, tensor_y, active


def smooth_tensor_field(tensor_x, tensor_y, active):
    blocks_y = len(tensor_x)
    blocks_x = len(tensor_x[0])
    smooth_x = [[0 for _ in range(blocks_x)] for _ in range(blocks_y)]
    smooth_y = [[0 for _ in range(blocks_x)] for _ in range(blocks_y)]
    smooth_active = [[False for _ in range(blocks_x)] for _ in range(blocks_y)]

    for by in range(blocks_y):
        for bx in range(blocks_x):
            sx = 0
            sy = 0
            votes = 0
            for oy in (-1, 0, 1):
                for ox in (-1, 0, 1):
                    yy = by + oy
                    xx = bx + ox
                    if 0 <= yy < blocks_y and 0 <= xx < blocks_x and active[yy][xx]:
                        sx += tensor_x[yy][xx]
                        sy += tensor_y[yy][xx]
                        votes += 1
            smooth_x[by][bx] = sx
            smooth_y[by][bx] = sy
            smooth_active[by][bx] = active[by][bx] and votes >= 3
    return smooth_x, smooth_y, smooth_active


def angle_to_bin(theta_deg):
    theta_deg %= 180.0
    return int(math.floor((theta_deg + 11.25) / 22.5)) & 7


def bin_to_angle(direction):
    return direction * 22.5


def tensor_to_angle(tx, ty):
    ridge = 0.5 * math.degrees(math.atan2(ty, tx))
    return bin_to_angle(angle_to_bin(ridge))


def draw_line(rgb, width, height, cx, cy, angle_deg, length=12, color=(255, 255, 255)):
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


def render_overlay(gray, tensor_x, tensor_y, active, path):
    width = IMAGE_W * SCALE
    height = IMAGE_H * SCALE
    rgb = bytearray(width * height * 3)
    for y in range(height):
        for x in range(width):
            value = gray[(y // SCALE) * IMAGE_W + (x // SCALE)]
            idx = (y * width + x) * 3
            rgb[idx:idx + 3] = bytes((value, value, value))

    for by in range(IMAGE_H // BLOCK):
        for bx in range(IMAGE_W // BLOCK):
            if not active[by][bx]:
                continue
            cx = int((bx * BLOCK + BLOCK / 2) * SCALE)
            cy = int((by * BLOCK + BLOCK / 2) * SCALE)
            draw_line(rgb, width, height, cx, cy, tensor_to_angle(tensor_x[by][bx], tensor_y[by][bx]))
    write_png(rgb, width, height, path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    gray = preprocess_image(args.input)
    write_mem(gray, MEM_PATH)
    write_png(gray_to_rgb(gray), IMAGE_W, IMAGE_H, PNG_PATH)

    tensor_x, tensor_y, active = build_tensor_field(gray)
    tensor_x, tensor_y, active = smooth_tensor_field(tensor_x, tensor_y, active)
    render_overlay(gray, tensor_x, tensor_y, active, OVERLAY_PATH)

    active_count = sum(1 for row in active for value in row if value)
    print(f"WROTE {MEM_PATH}")
    print(f"WROTE {PNG_PATH}")
    print(f"WROTE {OVERLAY_PATH}")
    print(f"REALITY_FINGERPRINT_PREP_PASS active_blocks={active_count}")


if __name__ == "__main__":
    main()
