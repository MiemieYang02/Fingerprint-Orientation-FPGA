import argparse
import math
import os
import struct
import zlib


def png_chunk(chunk_type, data):
    return (
        struct.pack(">I", len(data))
        + chunk_type
        + data
        + struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF)
    )


def write_png(gray, width, height, path):
    raw_rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            v = gray[y * width + x]
            row.extend([v, v, v])
        raw_rows.append(bytes(row))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = zlib.compress(b"".join(raw_rows), level=9)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(png_chunk(b"IHDR", ihdr))
        f.write(png_chunk(b"IDAT", data))
        f.write(png_chunk(b"IEND", b""))


def synth_fingerprint(width, height):
    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0
    values = []

    for y in range(height):
        for x in range(width):
            dx = x - cx
            dy = y - cy
            rx = dx / (width * 0.43)
            ry = dy / (height * 0.47)
            mask = rx * rx + ry * ry

            if mask > 1.0:
                values.append(232)
                continue

            radius = math.sqrt(dx * dx + dy * dy)
            angle = math.atan2(dy, dx)
            swirl = 0.27 * radius + 3.6 * angle + 0.018 * dx - 0.012 * dy
            ridge = 0.5 + 0.5 * math.sin(swirl)
            fine = 0.5 + 0.5 * math.sin(0.11 * x + 0.07 * y)
            edge_fade = min(1.0, max(0.0, (1.0 - mask) * 3.0))

            ink = (ridge ** 1.9) * 112.0 + fine * 11.0
            value = int(216 - ink * edge_fade)
            value = max(36, min(238, value))
            values.append(value)

    return values


def main():
    parser = argparse.ArgumentParser(description="Generate a static 256x256 fingerprint-like MEM image and PNG preview.")
    parser.add_argument("--width", type=int, default=256)
    parser.add_argument("--height", type=int, default=256)
    parser.add_argument("--mem", default="fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/fingerprint_static_256.mem")
    parser.add_argument("--png", default="fingerprint_direction_fpga/previews/fingerprint_static_256.png")
    args = parser.parse_args()

    values = synth_fingerprint(args.width, args.height)

    os.makedirs(os.path.dirname(args.mem), exist_ok=True)
    with open(args.mem, "w", encoding="ascii", newline="\n") as f:
        for v in values:
            f.write(f"{v:02x}\n")

    os.makedirs(os.path.dirname(args.png), exist_ok=True)
    write_png(values, args.width, args.height, args.png)


if __name__ == "__main__":
    main()
