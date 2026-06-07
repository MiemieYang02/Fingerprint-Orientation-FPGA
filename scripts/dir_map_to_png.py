#!/usr/bin/env python3
"""Convert a 16x16 direction map text file into a PNG or PPM preview.

The PNG writer uses only the Python standard library, so no Pillow dependency is
required.
"""

import argparse
import binascii
import struct
import zlib
from pathlib import Path


COLORS = {
    0: (230, 35, 35),
    1: (235, 130, 35),
    2: (230, 210, 35),
    3: (80, 190, 70),
    4: (35, 170, 210),
    5: (45, 95, 220),
    6: (145, 70, 210),
    7: (215, 70, 170),
}


def read_map(path):
    values = [[0 for _ in range(16)] for _ in range(16)]
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            parts = line.strip().split()
            if not parts:
                continue
            if len(parts) != 3:
                raise ValueError(f"Bad line in {path}: {line.rstrip()}")
            x, y, direction = (int(p) for p in parts)
            if not (0 <= x < 16 and 0 <= y < 16 and 0 <= direction < 8):
                raise ValueError(f"Out-of-range direction entry: {line.rstrip()}")
            values[y][x] = direction
    return values


def write_ppm(values, path, scale):
    width = 16 * scale
    height = 16 * scale
    with path.open("wb") as f:
        f.write(f"P6\n{width} {height}\n255\n".encode("ascii"))
        for by in range(16):
            for sy in range(scale):
                row = bytearray()
                for bx in range(16):
                    r, g, b = COLORS[values[by][bx]]
                    if sy == scale // 2:
                        r, g, b = 255, 255, 255
                    for sx in range(scale):
                        pixel = (255, 255, 255) if sx == scale // 2 else (r, g, b)
                        row.extend(pixel)
                f.write(row)


def render_rgb(values, scale):
    rows = []
    for by in range(16):
        for sy in range(scale):
            row = bytearray()
            for bx in range(16):
                r, g, b = COLORS[values[by][bx]]
                if sy == scale // 2:
                    r, g, b = 255, 255, 255
                for sx in range(scale):
                    pixel = (255, 255, 255) if sx == scale // 2 else (r, g, b)
                    row.extend(pixel)
            rows.append(bytes(row))
    return rows


def png_chunk(chunk_type, data):
    body = chunk_type + data
    crc = binascii.crc32(body) & 0xffffffff
    return struct.pack(">I", len(data)) + body + struct.pack(">I", crc)


def write_png(values, path, scale):
    width = 16 * scale
    height = 16 * scale
    raw = bytearray()
    for row in render_rgb(values, scale):
        raw.append(0)  # PNG filter type 0.
        raw.extend(row)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    compressed = zlib.compress(bytes(raw), level=9)
    with path.open("wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(png_chunk(b"IHDR", ihdr))
        f.write(png_chunk(b"IDAT", compressed))
        f.write(png_chunk(b"IEND", b""))


def main():
    parser = argparse.ArgumentParser(description="Convert dir_map.txt to a color PNG or PPM preview.")
    parser.add_argument("input", nargs="?", default="dir_map.txt", help="input direction map text file")
    parser.add_argument("output", nargs="?", default="dir_map.png", help="output preview path (.png or .ppm)")
    parser.add_argument("--scale", type=int, default=20, help="pixels per direction block")
    args = parser.parse_args()

    if args.scale < 4:
        raise SystemExit("--scale must be at least 4")

    values = read_map(Path(args.input))
    output = Path(args.output)
    if output.suffix.lower() == ".ppm":
        write_ppm(values, output, args.scale)
    else:
        write_png(values, output, args.scale)
    print(f"WROTE {args.output}")


if __name__ == "__main__":
    main()
