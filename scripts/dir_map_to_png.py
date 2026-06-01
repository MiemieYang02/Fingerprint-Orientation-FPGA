#!/usr/bin/env python3
"""Convert a 16x16 direction map text file into a simple PPM preview.

The script name keeps the project terminology from the design spec. It writes a
PPM image by default so it has no third-party dependency.
"""

import argparse
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


def main():
    parser = argparse.ArgumentParser(description="Convert dir_map.txt to a color PPM preview.")
    parser.add_argument("input", nargs="?", default="dir_map.txt", help="input direction map text file")
    parser.add_argument("output", nargs="?", default="dir_map.ppm", help="output PPM preview path")
    parser.add_argument("--scale", type=int, default=20, help="pixels per direction block")
    args = parser.parse_args()

    if args.scale < 4:
        raise SystemExit("--scale must be at least 4")

    values = read_map(Path(args.input))
    write_ppm(values, Path(args.output), args.scale)
    print(f"WROTE {args.output}")


if __name__ == "__main__":
    main()
