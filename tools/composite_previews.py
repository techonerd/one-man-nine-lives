#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Composite real QML offscreen renders into theme preview images.

Creates:
  - sddm/doorstep/preview/preview.png (and doorstep/preview.png)
From the real 2560x1600 offscreen renders of:
  - dark
  - light
  - error (wrong password)
  - capslock
"""

import shutil
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]


def make_preview_composite(dark_path: Path, light_path: Path, error_path: Path, capslock_path: Path, out_path: Path, title: str):
    # Load 2560x1600 renders
    dark_img = Image.open(dark_path).convert("RGBA")
    light_img = Image.open(light_path).convert("RGBA")
    error_img = Image.open(error_path).convert("RGBA")
    capslock_img = Image.open(capslock_path).convert("RGBA")

    # Target composite canvas: 3000 x 1200
    w, h = 3000, 1200
    canvas = Image.new("RGBA", (w, h), (20, 20, 20, 255))

    # Left: Dark Mode (scaled to 1480 x 925)
    # Right: Light Mode (scaled to 1480 x 925)
    pw, ph = 1480, 925
    dark_scaled = dark_img.resize((pw, ph), Image.Resampling.LANCZOS)
    light_scaled = light_img.resize((pw, ph), Image.Resampling.LANCZOS)

    canvas.paste(dark_scaled, (15, 20))
    canvas.paste(light_scaled, (1505, 20))

    # Draw separator line between dark and light
    draw = ImageDraw.Draw(canvas)
    draw.line([(1500, 20), (1500, 20 + ph)], fill=(50, 50, 50, 255), width=2)

    # Inset cards at bottom: Error state and Caps Lock state (centered crops of the card)
    # Card is located around center (x: 1000..1560, y: 550..1150 on 2560x1600)
    crop_box = (920, 560, 1640, 1140)  # 720 x 580
    cw, ch = 380, 210

    err_crop = error_img.crop(crop_box).resize((cw, ch), Image.Resampling.LANCZOS)
    caps_crop = capslock_img.crop(crop_box).resize((cw, ch), Image.Resampling.LANCZOS)

    # Paste insets on bottom row
    # Inset 1: Wrong Password State
    canvas.paste(err_crop, (400, 960))
    draw.rectangle([399, 959, 400 + cw, 960 + ch], outline=(240, 128, 122, 200), width=1)

    # Inset 2: Caps Lock Active State
    canvas.paste(caps_crop, (1900, 960))
    draw.rectangle([1899, 959, 1900 + cw, 960 + ch], outline=(240, 179, 91, 200), width=1)

    # Labels for insets
    draw.text((400, 940), "Wrong Password State (Semantic Error)", fill=(240, 128, 122, 255))
    draw.text((1900, 940), "Caps Lock Active State (Semantic Warning)", fill=(240, 179, 91, 255))
    draw.text((25, 960), f"{title} — Dark Mode (Off-white Casper)", fill=(230, 230, 230, 255))
    draw.text((1515, 960), f"{title} — Light Mode (Off-white Casper + Outline)", fill=(230, 230, 230, 255))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, format="PNG", optimize=True)
    print(f"Generated composite preview: {out_path} ({w}x{h})")


def main():
    sddm_prev_dir = ROOT / "sddm" / "doorstep" / "preview"

    # Doorstep
    doorstep_out = sddm_prev_dir / "preview.png"
    make_preview_composite(
        sddm_prev_dir / "doorstep_dark.png",
        sddm_prev_dir / "doorstep_light.png",
        sddm_prev_dir / "doorstep_error.png",
        sddm_prev_dir / "doorstep_capslock.png",
        doorstep_out,
        "Doorstep SDDM Login Theme"
    )
    # Also sync metadata preview for SDDM
    shutil.copyfile(doorstep_out, ROOT / "sddm" / "doorstep" / "doorstep" / "preview.png")


if __name__ == "__main__":
    main()
