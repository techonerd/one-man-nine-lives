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
    eye_light = Image.open(PREVIEW_DIR / "eye_strip_light.png").convert("RGBA")
    stretch_dark = Image.open(PREVIEW_DIR / "stretch_overlay_dark.png").convert("RGBA")
    stretch_light = Image.open(PREVIEW_DIR / "stretch_overlay_light.png").convert("RGBA")

    popup_large_path = PREVIEW_DIR / "popup_large_font.png"
    popup_large = Image.open(popup_large_path).convert("RGBA") if popup_large_path.exists() else None

    # Canvas 2560 x 1440
    w, h = 2560, 1440
    canvas = Image.new("RGBA", (w, h), (20, 20, 20, 255))
    draw = ImageDraw.Draw(canvas)

    # Top banner / title
    draw.text((40, 30), "Lap Time — Break Reminder with Casper Overlay (One Man Nine Lives)", fill=(230, 230, 230, 255))

    # Top Row: Panels (Dark & Light) and Popups (Dark & Light & 1.5x font)
    # 1. Panel Dark & Light
    canvas.paste(panel_dark, (40, 80))
    draw.text((40, 145), "Compact Panel (Dark Mode)", fill=(160, 160, 160, 255))

    canvas.paste(panel_light, (440, 80))
    draw.text((440, 145), "Compact Panel (Light Mode)", fill=(160, 160, 160, 255))

    # 2. Popups (Dark & Light)
    canvas.paste(popup_dark, (40, 180))
    draw.text((40, 690), "Popup Dialog (Dark)", fill=(160, 160, 160, 255))

    canvas.paste(popup_light, (490, 180))
    draw.text((490, 690), "Popup Dialog (Light, contrast-verified text)", fill=(160, 160, 160, 255))

    # 3. Eye Break Card (Smaller card without dimming backdrop)
    sw, sh = 740, 416
    eye_dark_scaled = eye_dark.resize((sw, sh), Image.Resampling.LANCZOS)
    eye_light_scaled = eye_light.resize((sw, sh), Image.Resampling.LANCZOS)

    canvas.paste(eye_dark_scaled, (960, 80))
    draw.rectangle([959, 79, 960 + sw, 80 + sh], outline=(60, 60, 60, 255), width=1)
    draw.text((960, 505), "Eye Break: Compact Card (Dark Mode: Non-dimming over desktop)", fill=(200, 200, 200, 255))

    canvas.paste(eye_light_scaled, (1740, 80))
    draw.rectangle([1739, 79, 1740 + sw, 80 + sh], outline=(180, 180, 180, 255), width=1)
    draw.text((1740, 505), "Eye Break: Compact Card (Light Mode: Non-dimming over desktop)", fill=(200, 200, 200, 255))

    # 4. Stretch Break Overlay (Scaled representations: Dark on left-middle, Light on right-middle)
    stretch_dark_scaled = stretch_dark.resize((sw, sh), Image.Resampling.LANCZOS)
    stretch_light_scaled = stretch_light.resize((sw, sh), Image.Resampling.LANCZOS)

    canvas.paste(stretch_dark_scaled, (960, 535))
    draw.rectangle([959, 534, 960 + sw, 535 + sh], outline=(70, 70, 70, 255), width=1)
    draw.text((960, 960), "Fullscreen Stretch Break (Dark Mode: Covers all screens, Snooze count, Return/Esc)", fill=(200, 200, 200, 255))

    canvas.paste(stretch_light_scaled, (1740, 535))
    draw.rectangle([1739, 534, 1740 + sw, 535 + sh], outline=(180, 180, 180, 255), width=1)
    draw.text((1740, 960), "Fullscreen Stretch Break (Light Mode: Covers all screens, high-contrast text)", fill=(200, 200, 200, 255))

    # Bottom summary panel
    draw.rectangle([40, 990, 2500, 1400], fill=(28, 28, 28, 255), outline=(50, 50, 50, 255), width=1)
    draw.text((70, 1010), "Ergonomics & Design Highlights (UI Polish Completed):", fill=(232, 162, 86, 255))
    notes = [
        "• L1 (Readability): Countdowns, Taken & Skipped counts render in Kirigami.Theme.textColor (>10:1 contrast on Breeze Light). Accent kept for progress ring & bars.",
        "• L2 (Font Scaling): All fixed font pointSizes replaced with Heading levels and Kirigami.Theme.smallFont. Card heights are implicit to prevent clipping.",
        "• L3 (Idle Detection): Short 'Tracking' badge; Kirigami.InlineMessage warning if laptime-idle daemon is missing, linking to fix documentation.",
        "• L4 (Keyboard & Screens): Return completes break ('I'm on it' has initial focus); Esc skips. Stretch breaks cover all screens; Snooze displays count left.",
        "• L5 & L6 (HIG Polish): Removed redundant theme overrides. Standardized button title casing ('Take Now', 'Pause for 1 Hour') and i18nc unit translations.",
        "• Decisions 1 & 2: Stretch breaks cover every screen with full-screen glass; eye breaks display a compact non-dimming card on active screen only."
    ]
    for i, note in enumerate(notes):
        draw.text((70, 1055 + (i * 45)), note, fill=(230, 230, 230, 255))

    out_file = PREVIEW_DIR / "preview.png"
    canvas.save(out_file, format="PNG", optimize=True)
    print(f"Generated Lap Time composite preview: {out_file} ({w}x{h})")


if __name__ == "__main__":
    main()
