#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Generate Catnap: the lock-screen wallpaper of One Man Nine Lives.

Plasma 6 always uses the Breeze lock screen of the desktop shell, so Catnap is
a wallpaper package for it (com.github.techonerd.catnap), not a QML lock
screen. The Breeze lock screen draws its clock and password field in the
Complementary (dark) colour set in both Light and Dark, so Catnap is one dark
image: the dark Casper Mono background with Casper asleep in the corner.

Casper Mono rules (tasks/media.md section 1):
  - Casper is ALWAYS white (off-white coat #F5F5F5, never #FFFFFF).
  - Dark mode: off-white coat (#F5F5F5), no outline, faint shadow, dark background (#0E0E0E).
"""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "color-scheme" / "tabby-and-tweed" / "tools"))
from generate import MONO_DARK  # noqa: E402

W, H = 2560, 1600
CAT_SCALE = 2.4                       # 256x140 artwork -> about 614x336 px
CAT_X, CAT_Y = 1800, 1150             # lower right, clear of clock, field and buttons
PKG = ROOT / "look-and-feel" / "one-man-nine-lives" / "catnap"

METADATA = {
    "KPackageStructure": "Plasma/Wallpaper",
    "KPlugin": {
        "Authors": [{"Name": "techonerd"}],
        "Description": "Casper asleep in the corner; lock-screen wallpaper of One Man Nine Lives",
        "Id": "com.github.techonerd.catnap",
        "License": "GPL-3.0-or-later",
        "Name": "Catnap",
        "Version": "0.1.0",
        "Website": "https://github.com/techonerd/one-man-nine-lives",
    },
    "X-Plasma-API-Minimum-Version": "6.0",
}


def make_mono_bg() -> str:
    bg_color = MONO_DARK["bg"]
    fade_color = "#161616"
    beam_color = MONO_DARK["fg"]

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{bg_color}"/>
      <stop offset="100%" stop-color="{fade_color}"/>
    </linearGradient>
    <linearGradient id="beamGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{beam_color}" stop-opacity="0.04"/>
      <stop offset="60%" stop-color="{beam_color}" stop-opacity="0.015"/>
      <stop offset="100%" stop-color="{beam_color}" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <rect width="{W}" height="{H}" fill="url(#bgGrad)"/>
  <path d="M1600 0 L2200 0 L1200 1600 L460 1600 Z" fill="url(#beamGrad)"/>
</svg>
"""


def make_body_svg() -> str:
    return """<svg xmlns="http://www.w3.org/2000/svg" width="164" height="96" viewBox="0 0 164 96">
  <g transform="translate(-46, -30)">
    <!-- Floor Shadow -->
    <ellipse cx="128" cy="112" rx="80" ry="14" fill="rgba(0, 0, 0, 0.45)"/>

    <!-- Rounded Bean Body Arch -->
    <path d="M66 92 C46 64 68 30 120 30 C176 30 204 60 194 92 C184 114 146 118 106 114 C82 112 70 102 66 92 Z"
          fill="#F5F5F5" stroke="none" stroke-width="0" stroke-linejoin="round"/>

    <!-- Tucked Front Paws -->
    <ellipse cx="106" cy="94" rx="11" ry="8" fill="#F5F5F5" stroke="none" stroke-width="0"/>
    <ellipse cx="122" cy="94" rx="10" ry="7.5" fill="#F5F5F5" stroke="none" stroke-width="0"/>
  </g>
</svg>
"""


def make_head_svg() -> str:
    return """<svg xmlns="http://www.w3.org/2000/svg" width="66" height="76" viewBox="0 0 66 76">
  <g transform="translate(-44, -28)">
    <!-- Soft Rounded Head -->
    <circle cx="80" cy="76" r="27" fill="#F5F5F5" stroke="none" stroke-width="0"/>

    <!-- Left Rounded Ear with signature notch -->
    <path d="M60 60 L63 34 C64 32 66 32 67 34 L76 50 Z" fill="#F5F5F5" stroke="none" stroke-width="0"/>
    <path d="M63 56 L65 38 L72 50 Z" fill="rgba(0, 0, 0, 0.08)"/>

    <!-- Right Rounded Ear with signature notch -->
    <path d="M82 48 L93 30 C95 29 97 30 98 32 L101 56 Z" fill="#F5F5F5" stroke="none" stroke-width="0"/>
    <path d="M86 48 L94 35 L98 52 Z" fill="rgba(0, 0, 0, 0.08)"/>

    <!-- Smiling Closed Sleeping Eyes -->
    <path d="M64 78 Q70 84 76 78" fill="none" stroke="#222222" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M80 78 Q86 84 92 78" fill="none" stroke="#222222" stroke-width="2.5" stroke-linecap="round"/>

    <!-- Sweet Tiny Nose -->
    <polygon points="77,85 81,85 79,88" fill="#222222" opacity="0.8"/>

    <!-- Whisker Glints -->
    <g stroke="#222222" stroke-width="0.9" stroke-linecap="round" opacity="0.35">
      <line x1="60" y1="82" x2="46" y2="80"/>
      <line x1="60" y1="85" x2="47" y2="87"/>
      <line x1="94" y1="82" x2="108" y2="80"/>
      <line x1="94" y1="85" x2="107" y2="87"/>
    </g>
  </g>
</svg>
"""


def make_tail_base_svg() -> str:
    # Overlaps ~2 art units past Joint 1 with circular arc centered at pivot (197.4, 78.1)
    return """<svg xmlns="http://www.w3.org/2000/svg" width="56" height="22" viewBox="0 0 56 22">
  <g transform="translate(-160, -71)">
    <path d="M186 90 C199.26 90.00 208.57 85.74 213.92 79.71
             A 15.5 15.5 0 0 1 184.14 73.54
             C179.34 77.23 172.08 80.32 162.00 82.00 Z"
          fill="#F5F5F5" stroke="none" stroke-width="0" stroke-linejoin="round"/>
  </g>
</svg>
"""


def make_tail_mid_svg() -> str:
    # Overlaps ~2 art units before Joint 1 and ~2 art units past Joint 2 with circular arcs
    return """<svg xmlns="http://www.w3.org/2000/svg" width="44" height="30" viewBox="0 0 44 30">
  <g transform="translate(-179, -55)">
    <path d="M181.13 75.58 A 15.5 15.5 0 0 0 210.12 83.18
             C218.71 76.78 221.30 66.94 217.90 58.28
             A 13.5 13.5 0 0 1 191.54 59.49
             C192.10 64.88 188.94 70.92 181.13 75.58 Z"
          fill="#F5F5F5" stroke="none" stroke-width="0" stroke-linejoin="round"/>
  </g>
</svg>
"""


def make_tail_tip_svg() -> str:
    # Overlaps ~2 art units before Joint 2 with circular arc centered at pivot (205.1, 60.5)
    return """<svg xmlns="http://www.w3.org/2000/svg" width="42" height="33" viewBox="0 0 42 33">
  <g transform="translate(-181, -33)">
    <path d="M191.55 61.80 A 13.8 13.8 0 0 0 219.10 62.69
             C218.25 57.30 215.22 52.06 210.00 48.00
             C198 38 186 46 191 57
             C191.51 58.53 191.70 60.15 191.55 61.80 Z"
          fill="#F5F5F5" stroke="none" stroke-width="0" stroke-linejoin="round"/>
  </g>
</svg>
"""


def make_parts_js() -> str:
    return """// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
.pragma library

var sceneW = 2560;
var sceneH = 1600;

var body = {
    x: 1910.4,
    y: 1222.0,
    w: 393.6,
    h: 230.4,
    pivotX: 2107.2,
    pivotY: 1433.2
};

var head = {
    x: 1905.6,
    y: 1217.2,
    w: 158.4,
    h: 182.4,
    pivotX: 2028.0,
    pivotY: 1380.4
};

var tailBase = {
    x: 2184.0,
    y: 1320.4,
    w: 134.4,
    h: 52.8,
    pivotX: 2217.6,
    pivotY: 1356.4
};

var tailMid = {
    x: 2229.6,
    y: 1282.0,
    w: 105.6,
    h: 72.0,
    pivotX: 2273.76,
    pivotY: 1337.44
};

var tailTip = {
    x: 2234.4,
    y: 1229.2,
    w: 100.8,
    h: 79.2,
    pivotX: 2292.24,
    pivotY: 1295.2
};
"""


def scene() -> str:
    bg = make_mono_bg()
    body = make_body_svg()
    head = make_head_svg()
    tb = make_tail_base_svg()
    tm = make_tail_mid_svg()
    tt = make_tail_tip_svg()

    def inner(svg: str) -> str:
        return svg[svg.index(">", svg.index("<svg")) + 1: svg.rindex("</svg>")].strip()

    elements = [
        f'  <g transform="translate(2184.0, 1320.4) scale({CAT_SCALE})">{inner(tb)}</g>',
        f'  <g transform="translate(2229.6, 1282.0) scale({CAT_SCALE})">{inner(tm)}</g>',
        f'  <g transform="translate(2234.4, 1229.2) scale({CAT_SCALE})">{inner(tt)}</g>',
        f'  <g transform="translate(1910.4, 1222.0) scale({CAT_SCALE})">{inner(body)}</g>',
        f'  <g transform="translate(1905.6, 1217.2) scale({CAT_SCALE})">{inner(head)}</g>',
    ]
    return bg.replace("</svg>", "\n" + "\n".join(elements) + "\n</svg>")


HARNESS = Path("/tmp/wk/bin/render_harness")


def qt_render(svg: Path, out: Path) -> None:
    """Render with Qt's SVG engine (the one Plasma uses), via tools/render_harness."""
    src = ROOT / "tools" / "render_harness.cpp"
    if not HARNESS.exists() or src.stat().st_mtime > HARNESS.stat().st_mtime:
        HARNESS.parent.mkdir(parents=True, exist_ok=True)
        flags = subprocess.run(["pkg-config", "--cflags", "--libs", "Qt6Quick", "Qt6Qml"],
                               check=True, capture_output=True, text=True).stdout.split()
        subprocess.run(["g++", "-O2", str(src), *flags, "-o", str(HARNESS)], check=True)
    qml = svg.with_suffix(".qml")
    qml.write_text(f'''import QtQuick
Image {{ width: {W}; height: {H}; source: "{svg.name}"; sourceSize: Qt.size({W}, {H}); smooth: true }}
''', encoding="utf-8")
    env = dict(__import__("os").environ, QT_QPA_PLATFORM="offscreen", QML_DISABLE_DISK_CACHE="1")
    subprocess.run([str(HARNESS), str(qml), str(out)], check=True, env=env)


def main() -> None:
    images = PKG / "contents" / "images"
    ui = PKG / "contents" / "ui"
    images.mkdir(parents=True, exist_ok=True)
    ui.mkdir(parents=True, exist_ok=True)

    # Clean up legacy raster files in images/ if any
    for old_file in images.glob("*.png"):
        old_file.unlink()

    # Write metadata.json
    (PKG / "metadata.json").write_text(json.dumps(METADATA, indent=4) + "\n", encoding="utf-8")

    # Write parts.js
    (ui / "parts.js").write_text(make_parts_js(), encoding="utf-8")

    # Write vector SVGs
    (images / "background.svg").write_text(make_mono_bg(), encoding="utf-8")
    (images / "body.svg").write_text(make_body_svg(), encoding="utf-8")
    (images / "head.svg").write_text(make_head_svg(), encoding="utf-8")
    (images / "tail-base.svg").write_text(make_tail_base_svg(), encoding="utf-8")
    (images / "tail-mid.svg").write_text(make_tail_mid_svg(), encoding="utf-8")
    (images / "tail-tip.svg").write_text(make_tail_tip_svg(), encoding="utf-8")

    # Generate screenshot.png (400x250) deterministically
    with tempfile.TemporaryDirectory() as tmp:
        svg_file = Path(tmp) / "catnap_scene.svg"
        svg_file.write_text(scene(), encoding="utf-8")
        full_png = Path(tmp) / "full.png"
        qt_render(svg_file, full_png)
        screenshot = PKG / "contents" / "screenshot.png"
        cmd = ["magick", str(full_png), "-filter", "Lanczos", "-resize", "400x250!", "-strip", str(screenshot)]
        subprocess.run(cmd, check=True)

    print(f"wrote {PKG.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
