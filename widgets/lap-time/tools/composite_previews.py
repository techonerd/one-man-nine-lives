#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Composite Lap Time QML offscreen renders into a comprehensive preview.

Combines:
  - Panel (dark & light)
  - Popup dialog (dark & light)
  - Eye break strip (dark & light)
  - Stretch break overlay (dark & light)
Into widgets/lap-time/preview/preview.png
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
PREVIEW_DIR = ROOT / "widgets" / "lap-time" / "preview"


def main():
    panel_dark = Image.open(PREVIEW_DIR / "panel_dark.png").convert("RGBA")
    panel_light = Image.open(PREVIEW_DIR / "panel_light.png").convert("RGBA")
    popup_dark = Image.open(PREVIEW_DIR / "popup_dark.png").convert("RGBA")
    popup_light = Image.open(PREVIEW_DIR / "popup_light.png").convert("RGBA")
    eye_dark = Image.open(PREVIEW_DIR / "eye_strip_dark.png").convert("RGBA")
    stretch_dark = Image.open(PREVIEW_DIR / "stretch_overlay_dark.png").convert("RGBA")
    stretch_light = Image.open(PREVIEW_DIR / "stretch_overlay_light.png").convert("RGBA")

    # Canvas 2560 x 1440
    w, h = 2560, 1440
    canvas = Image.new("RGBA", (w, h), (20, 20, 20, 255))
    draw = ImageDraw.Draw(canvas)

    # Top banner / title
    draw.text((40, 30), "Lap Time — Break Reminder with Casper Overlay (One Man Nine Lives)", fill=(230, 230, 230, 255))

    # Top Row: Panels (Dark & Light) and Popups (Dark & Light)
    # 1. Panel Dark & Light
    canvas.paste(panel_dark, (40, 80))
    draw.text((40, 145), "Compact Panel (Dark Mode)", fill=(160, 160, 160, 255))

    canvas.paste(panel_light, (440, 80))
    draw.text((440, 145), "Compact Panel (Light Mode)", fill=(160, 160, 160, 255))

    # 2. Popups (Dark & Light)
    canvas.paste(popup_dark, (40, 180))
    canvas.paste(popup_light, (490, 180))

    # 3. Eye Break Strip (Bottom strip crop, placed on the right side)
    # Eye strip is at y: 990..1080 of eye_dark (1920x1080)
    eye_crop_dark = eye_dark.crop((0, 990, 1920, 1080)).resize((1500, 75), Image.Resampling.LANCZOS)
    canvas.paste(eye_crop_dark, (960, 80))
    draw.rectangle([959, 79, 960 + 1500, 80 + 75], outline=(60, 60, 60, 255), width=1)
    draw.text((960, 165), "Eye Break: 20-20-20 Rule Frameless Click-Through Strip (Casper Walking)", fill=(200, 200, 200, 255))

    # 4. Stretch Break Overlay (Scaled representations: Dark on left-middle, Light on right-middle)
    sw, sh = 740, 416
    stretch_dark_scaled = stretch_dark.resize((sw, sh), Image.Resampling.LANCZOS)
    stretch_light_scaled = stretch_light.resize((sw, sh), Image.Resampling.LANCZOS)

    canvas.paste(stretch_dark_scaled, (960, 210))
    draw.rectangle([959, 209, 960 + sw, 210 + sh], outline=(70, 70, 70, 255), width=1)
    draw.text((960, 635), "Fullscreen Stretch Break (Dark Mode: Casper napping, timer, Snooze/Skip/I'm on it)", fill=(200, 200, 200, 255))

    canvas.paste(stretch_light_scaled, (1740, 210))
    draw.rectangle([1739, 209, 1740 + sw, 210 + sh], outline=(180, 180, 180, 255), width=1)
    draw.text((1740, 635), "Fullscreen Stretch Break (Light Mode: Off-white Casper + Outline, tips & timer)", fill=(200, 200, 200, 255))

    # Inset for Eye Break Light mode
    eye_light = Image.open(PREVIEW_DIR / "eye_strip_light.png").convert("RGBA")
    eye_crop_light = eye_light.crop((0, 990, 1920, 1080)).resize((1500, 75), Image.Resampling.LANCZOS)
    canvas.paste(eye_crop_light, (960, 675))
    draw.rectangle([959, 674, 960 + 1500, 675 + 75], outline=(180, 180, 180, 255), width=1)
    draw.text((960, 760), "Eye Break Strip (Light Mode: High contrast text & Casper outline)", fill=(200, 200, 200, 255))

    # Bottom summary panel
    draw.rectangle([40, 800, 2500, 1400], fill=(28, 28, 28, 255), outline=(50, 50, 50, 255), width=1)
    draw.text((70, 830), "Ergonomics & Design Highlights:", fill=(232, 162, 86, 255))
    notes = [
        "• Respects Work Time Only: Pauses automatically when user is idle > 1 min or screen is locked (checked via powermanagement UserActivity & ScreenSaver GetActive).",
        "• Auto Break Detection: If idle for longer than the break duration (e.g. 5 min away from desk), automatically counts the break as taken.",
        "• Do Not Disturb Integration: Respects Plasma Do Not Disturb mode (Inhibited property), silencing fullscreen overlays during presentations or calls.",
        "• Non-Forced Ergonomics: Always offers Snooze (up to max configured), Skip, or instant Escape key bypass.",
        "• Public Plasma 6 APIs Only: Clean architecture with PlasmaComponents3, Kirigami, Plasma5Support data engines. Zero private modules.",
        "• Authentic Casper Mono Palette: Off-white coat (#F5F5F5) in both modes; outline (#1C1C1C) on light backgrounds; frosted glass MultiEffect blur."
    ]
    for i, note in enumerate(notes):
        draw.text((70, 880 + (i * 45)), note, fill=(230, 230, 230, 255))

    out_file = PREVIEW_DIR / "preview.png"
    canvas.save(out_file, format="PNG", optimize=True)
    print(f"Generated Lap Time composite preview: {out_file} ({w}x{h})")


if __name__ == "__main__":
    main()
