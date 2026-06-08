#!/usr/bin/env python3
"""Convert the demo fingerprint PNG set into 256x256 grayscale ROM files."""

from pathlib import Path

from PIL import Image, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
INPUT_DIR = ROOT / "fingers_pics"
IMAGE_DIR = ROOT / "fingerprint_direction_fpga" / "fingerprint_direction_fpga.srcs" / "sources_1" / "new" / "image"
PREVIEW_DIR = ROOT / "fingerprint_direction_fpga" / "previews"

IMAGE_W = 256
IMAGE_H = 256

INPUTS = [
    ("finger_1.png", "fingerprint_0_256"),
    ("finger_2.png", "fingerprint_1_256"),
    ("finger_3_reality.png", "fingerprint_2_256"),
]


def prepare_image(path):
    gray = Image.open(path).convert("L")
    gray = ImageOps.autocontrast(gray)
    gray.thumbnail((IMAGE_W, IMAGE_H), Image.Resampling.LANCZOS)

    canvas = Image.new("L", (IMAGE_W, IMAGE_H), 255)
    canvas.paste(gray, ((IMAGE_W - gray.width) // 2, (IMAGE_H - gray.height) // 2))

    # A light blur keeps camera/noise artifacts from dominating the static demo.
    return canvas.filter(ImageFilter.GaussianBlur(radius=0.35))


def write_mem(img, path):
    values = img.tobytes()
    path.write_text("".join(f"{value:02x}\n" for value in values), encoding="ascii")


def main():
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)

    for input_name, output_stem in INPUTS:
        source = INPUT_DIR / input_name
        if not source.exists():
            raise FileNotFoundError(source)

        img = prepare_image(source)
        mem_path = IMAGE_DIR / f"{output_stem}.mem"
        png_path = PREVIEW_DIR / f"{output_stem}.png"
        write_mem(img, mem_path)
        img.save(png_path)
        print(f"WROTE {mem_path}")
        print(f"WROTE {png_path}")

    print(f"FINGERPRINT_SET_PREP_PASS images={len(INPUTS)}")


if __name__ == "__main__":
    main()
