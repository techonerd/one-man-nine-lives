#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Composite Name Tag QML offscreen renders into a comprehensive preview.

Combines:
  - Panel horizontal active (dark & light)
  - Panel horizontal empty/desktop (dark & light)
  - Panel vertical (dark & light)
  - Settings dialog (dark & light)
Into widgets/name-tag/preview/preview.png
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
PREVIEW_DIR = ROOT / "widgets" / "name-tag" / "preview"


def main():
    panel_dark = Image.open(PREVIEW_DIR / "panel_dark.png").convert("RGBA")
    panel_light = Image.open(PREVIEW_DIR / "panel_light.png").convert("RGBA")
    panel_empty_dark = Image.open(PREVIEW_DIR / "panel_empty_dark.png").convert("RGBA")
    panel_empty_light = Image.open(PREVIEW_DIR / "panel_empty_light.png").convert("RGBA")
    panel_vert_dark = Image.open(PREVIEW_DIR / "panel_vertical_dark.png").convert("RGBA")
    panel_vert_light = Image.open(PREVIEW_DIR / "panel_vertical_light.png").convert("RGBA")
    config_dark = Image.open(PREVIEW_DIR / "config_dark.png").convert("RGBA")
    config_light = Image.open(PREVIEW_DIR / "config_light.png").convert("RGBA")

    # Canvas 2560 x 1440
    w, h = 2560, 1440
    canvas = Image.new("RGBA", (w, h), (18, 18, 18, 255))
    draw = ImageDraw.Draw(canvas)

    # Top title
    draw.text((60, 40), "Name Tag — Window Title & Collar Badge Widget (One Man Nine Lives)", fill=(245, 245, 245, 255))
    draw.text((60, 75), "A collar tag for your windows. Public org.kde.taskmanager APIs only, Plasma 6 native.", fill=(160, 160, 160, 255))

    # Section 1: Horizontal Panels (Top Left)
    draw.text((60, 130), "Panel States (Horizontal Form Factor)", fill=(232, 162, 86, 255))

    # Active Dark
    canvas.paste(panel_dark, (60, 170))
    draw.rectangle([59, 169, 60 + 560, 170 + 48], outline=(60, 60, 60, 255), width=1)
    draw.text((60, 225), "Active Window (Dark Mode: main.qml — Kate)", fill=(180, 180, 180, 255))

    # Active Light
    canvas.paste(panel_light, (660, 170))
    draw.rectangle([659, 169, 660 + 560, 170 + 48], outline=(180, 180, 180, 255), width=1)
    draw.text((660, 225), "Active Window (Light Mode: one-man-nine-lives — Dolphin)", fill=(180, 180, 180, 255))

    # Empty Dark
    canvas.paste(panel_empty_dark, (60, 265))
    draw.rectangle([59, 264, 60 + 560, 265 + 48], outline=(60, 60, 60, 255), width=1)
    draw.text((60, 320), "Empty / Desktop State (Dark Mode: Activity / Desktop)", fill=(180, 180, 180, 255))

    # Empty Light
    canvas.paste(panel_empty_light, (660, 265))
    draw.rectangle([659, 264, 660 + 560, 265 + 48], outline=(180, 180, 180, 255), width=1)
    draw.text((660, 320), "Empty / Desktop State (Light Mode: Activity / Desktop)", fill=(180, 180, 180, 255))

    # Section 2: Vertical Panels
    draw.text((1280, 130), "Vertical Panel Orientation", fill=(232, 162, 86, 255))

    canvas.paste(panel_vert_dark, (1280, 170))
    draw.rectangle([1279, 169, 1280 + 56, 170 + 320], outline=(60, 60, 60, 255), width=1)
    draw.text((1280, 500), "Vertical (Dark)", fill=(180, 180, 180, 255))

    canvas.paste(panel_vert_light, (1380, 170))
    draw.rectangle([1379, 169, 1380 + 56, 170 + 320], outline=(180, 180, 180, 255), width=1)
    draw.text((1380, 500), "Vertical (Light)", fill=(180, 180, 180, 255))

    # Section 3: Configuration Settings (Middle / Bottom)
    draw.text((60, 540), "Plasma 6 Configuration Interface (SimpleKCM & Kirigami.FormLayout)", fill=(232, 162, 86, 255))

    canvas.paste(config_dark, (60, 575))
    draw.rectangle([59, 574, 60 + 620, 575 + 480], outline=(60, 60, 60, 255), width=1)
    draw.text((60, 1065), "General Settings (Dark Theme)", fill=(180, 180, 180, 255))

    canvas.paste(config_light, (720, 575))
    draw.rectangle([719, 574, 720 + 620, 575 + 480], outline=(180, 180, 180, 255), width=1)
    draw.text((720, 1065), "General Settings (Light Theme)", fill=(180, 180, 180, 255))

    # Section 4: Architecture & Design Highlights (Right Side Box)
    draw.rectangle([1520, 170, 2500, 1100], fill=(26, 26, 26, 255), outline=(50, 50, 50, 255), width=1)
    draw.text((1550, 200), "Architecture & Design Highlights:", fill=(232, 162, 86, 255))

    notes = [
        "• Public Plasma 6 APIs Only: Exclusively utilizes org.kde.taskmanager (TasksModel,",
        "  ActivityInfo, VirtualDesktopInfo). Completely avoids deprecated org.kde.plasma.private.*.",
        "",
        "• Active Task Tracking: Reactive Qt.DisplayRole and Qt.DecorationRole bindings dynamically",
        "  track window focus, desktop switching, and title/icon updates without polling.",
        "",
        "• Flexible Empty State: When no window is active, seamlessly displays:",
        "  - Current Activity Name (default with fallback to 'Desktop')",
        "  - Fixed 'Desktop' label",
        "  - Custom user-defined label",
        "  - Blank (hidden)",
        "",
        "• Adaptive Orientation: Seamlessly adjusts layout between Horizontal and Vertical panels,",
        "  properly centering and eliding text to fit panel bounds.",
        "",
        "• Strict System Theme Compliance: Uses Kirigami.Theme colors exclusively.",
        "  No hardcoded colors in UI components.",
        "",
        "• Authentic Tabby & Tweed Palette: Original collar tag badge icon in both full-color",
        "  (warm amber #E8A256 with slate ring) and monochrome symbolic (.ColorScheme-Text).",
        "",
        "• Full KCFG Schema Synchronization: Every entry in main.xml declares matching cfg_<key>",
        "  and cfg_<key>Default properties in configGeneral.qml with identical default values.",
        "",
        "• Quality Assurance: Validated by qmllint with 0 errors, offline rendering harness,",
        "  and comprehensive logic test suite."
    ]

    for i, line in enumerate(notes):
        draw.text((1550, 250 + (i * 28)), line, fill=(210, 210, 210, 255))

    # Bottom footer
    draw.rectangle([60, 1150, 2500, 1380], fill=(22, 22, 22, 255), outline=(45, 45, 45, 255), width=1)
    draw.text((90, 1175), "Component Metadata & Compliance Summary:", fill=(232, 162, 86, 255))
    summary_lines = [
        "Package ID: com.github.techonerd.nametag   |   Type: Plasma/Applet   |   API: Plasma 6.0+   |   License: GPL-3.0-or-later",
        "Author: techonerd <22074809+techonerd@users.noreply.github.com>   |   Suite: One Man Nine Lives (Techonerd & Casper)",
        "Files: contents/ui/main.qml, contents/ui/configGeneral.qml, contents/config/main.xml, contents/icons/name-tag*.svg",
        "Safe Verification: Rendered offscreen with universal Qt6/Kirigami harness without system modifications."
    ]
    for i, line in enumerate(summary_lines):
        draw.text((90, 1220 + (i * 35)), line, fill=(170, 170, 170, 255))

    out_file = PREVIEW_DIR / "preview.png"
    canvas.save(out_file, format="PNG", optimize=True)
    print(f"Generated Name Tag composite preview: {out_file} ({w}x{h})")


if __name__ == "__main__":
    main()
