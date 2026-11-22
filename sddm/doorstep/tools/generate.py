#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Generate assets and theme files for Doorstep SDDM login theme.

Strictly follows Casper Mono palette from color-scheme/tabby-and-tweed/tools/generate.py.
Casper Mono rules (tasks/media.md section 1 & user review):
  - Casper is ALWAYS white (MONO coat, slightly off-white #F5F5F5, never #FFFFFF).
  - Light mode: keep background as MONO_LIGHT (#FFFFFF), Casper has near-black outline
    (#121212, >= 3:1 against background, ~1.5-2 units at 64), soft shadow, placed on a mid-tone
    area in scenes (#D8D8D8 floor, #E2E2E2 pad).
  - Dark mode: off-white coat (#F5F5F5), no outline, faint shadow, dark background (#0E0E0E).
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "color-scheme" / "tabby-and-tweed" / "tools"))
from generate import MONO_DARK, MONO_LIGHT  # noqa: E402

DOORSTEP_DIR = ROOT / "sddm" / "doorstep" / "doorstep"
DOORSTEP_DIR.mkdir(parents=True, exist_ok=True)

# 1. metadata.desktop
METADATA_DESKTOP = """[SddmGreeterTheme]
Name=Doorstep
Description=The cat waiting at the door when you come home. Casper Mono theme for SDDM.
Author=techonerd
Copyright=(c) 2026 techonerd
License=GPL-3.0-or-later
Type=sddm-theme
Version=0.1.0
Website=https://github.com/techonerd/one-man-nine-lives
Screenshot=preview.png
MainScript=Main.qml
ConfigFile=theme.conf
Theme-Id=doorstep
Theme-API=2.0
QtVersion=6
"""

(DOORSTEP_DIR / "metadata.desktop").write_text(METADATA_DESKTOP, encoding="utf-8")

# 2. theme.conf
THEME_CONF = """[General]
background=background.svg
avatar=avatar-default.svg
logo=doorstep-cat.svg
color=#0E0E0E
font=Sans
fontSize=11
clockFormat=hh:mm
dateFormat=dddd, MMMM d
showClock=true
variant=dark
"""

(DOORSTEP_DIR / "theme.conf").write_text(THEME_CONF, encoding="utf-8")


def make_mono_background(is_dark: bool) -> str:
    m = MONO_DARK if is_dark else MONO_LIGHT
    bg_wall = m["bg"]  # #0E0E0E in dark, #FFFFFF in light
    coat = "#F5F5F5"
    outline = "none" if is_dark else "#121212"
    stroke_w = "0" if is_dark else "2.5"
    cat_shadow = "rgba(0, 0, 0, 0.45)" if is_dark else "rgba(0, 0, 0, 0.15)"
    detail_color = "#222222" if is_dark else "#121212"
    ear_shade = "rgba(0, 0, 0, 0.08)" if is_dark else "rgba(0, 0, 0, 0.10)"

    floor_color = "#161616" if is_dark else "#D8D8D8"
    floor_dark = "#111111" if is_dark else "#CECECE"
    line_color = "rgba(255, 255, 255, 0.08)" if is_dark else "rgba(0, 0, 0, 0.12)"

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1600" viewBox="0 0 2560 1600">
  <defs>
    <linearGradient id="floorGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{floor_color}"/>
      <stop offset="100%" stop-color="{floor_dark}"/>
    </linearGradient>
  </defs>

  <!-- Wall -->
  <rect width="2560" height="1160" fill="{bg_wall}"/>

  <!-- Architectural Doorway (Mono lines) -->
  <rect x="1760" y="120" width="600" height="1040" rx="16" fill="none" stroke="{line_color}" stroke-width="4"/>
  <rect x="1790" y="150" width="540" height="1010" rx="12" fill="none" stroke="{line_color}" stroke-width="1.5"/>
  <line x1="1790" y1="680" x2="2330" y2="680" stroke="{line_color}" stroke-width="1.5"/>

  <!-- Mid-tone Floor -->
  <rect y="1160" width="2560" height="440" fill="url(#floorGrad)"/>
  <line x1="0" y1="1160" x2="2560" y2="1160" stroke="{line_color}" stroke-width="2"/>

  <!-- Floor Planks -->
  <g stroke="{line_color}" stroke-width="1">
    <line x1="0" y1="1250" x2="2560" y2="1250"/>
    <line x1="0" y1="1360" x2="2560" y2="1360"/>
    <line x1="0" y1="1480" x2="2560" y2="1480"/>
    <line x1="400" y1="1160" x2="260" y2="1600"/>
    <line x1="1000" y1="1160" x2="860" y2="1600"/>
    <line x1="1600" y1="1160" x2="1460" y2="1600"/>
    <line x1="2200" y1="1160" x2="2060" y2="1600"/>
  </g>

  <!-- Friendly Casper Sitting by the Doorway -->
  <g transform="translate(1960, 1030) scale(1.35)">
    <!-- Floor Shadow -->
    <ellipse cx="50" cy="184" rx="65" ry="16" fill="{cat_shadow}"/>

    <!-- Curled Friendly Tail -->
    <path d="M88 172 C135 184 140 156 126 142 C118 134 110 140 114 150 C118 162 108 170 82 165 Z"
          fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}" stroke-linejoin="round"/>

    <!-- Rounded Pear-shaped Body -->
    <path d="M22 176 C12 135 28 92 48 68 C58 56 74 56 84 68 C104 92 120 135 110 176 C102 188 30 188 22 176 Z"
          fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}" stroke-linejoin="round"/>

    <!-- Soft Front Paws -->
    <ellipse cx="48" cy="180" rx="10" ry="7" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <ellipse cx="70" cy="180" rx="10" ry="7" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>

    <!-- Friendly Rounded Head -->
    <circle cx="58" cy="50" r="26" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>

    <!-- Left Ear with signature notch -->
    <path d="M38 38 L42 14 C44 12 46 12 47 14 L56 28 Z" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <path d="M41 34 L44 18 L51 28 Z" fill="{ear_shade}"/>

    <!-- Right Ear with signature notch -->
    <path d="M60 28 L69 12 C71 11 73 12 74 14 L78 38 Z" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <path d="M63 28 L70 17 L74 34 Z" fill="{ear_shade}"/>

    <!-- Eyes and sweet expression -->
    <ellipse cx="50" cy="46" rx="2.5" ry="3.5" fill="{detail_color}"/>
    <ellipse cx="66" cy="46" rx="2.5" ry="3.5" fill="{detail_color}"/>
    <polygon points="57,53 59,53 58,54.5" fill="{detail_color}"/>
    <path d="M55 56 Q58 58 61 56" fill="none" stroke="{detail_color}" stroke-width="1" stroke-linecap="round"/>
  </g>
</svg>
"""


def make_mono_emblem(is_dark: bool) -> str:
    coat = "#F5F5F5"
    outline = "none" if is_dark else "#121212"
    stroke_w = "0" if is_dark else "3.2"  # ~1.6 units at 64
    shadow = "rgba(0, 0, 0, 0.45)" if is_dark else "rgba(0, 0, 0, 0.15)"
    detail_color = "#222222" if is_dark else "#121212"
    ear_shade = "rgba(0, 0, 0, 0.08)" if is_dark else "rgba(0, 0, 0, 0.10)"
    mid_tone_pad = "" if is_dark else """<ellipse cx="50" cy="68" rx="46" ry="34" fill="#E2E2E2" opacity="0.75"/>"""

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <g transform="translate(14, 10)">
    <!-- Mid-tone background pad (light mode) -->
    {mid_tone_pad}

    <!-- Shadow -->
    <ellipse cx="50" cy="106" rx="44" ry="10" fill="{shadow}"/>

    <!-- Curled Tail -->
    <path d="M72 100 C98 108 102 90 92 80 C86 74 80 78 83 85 C86 93 78 98 62 95 Z"
          fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}" stroke-linejoin="round"/>

    <!-- Rounded Body -->
    <path d="M22 100 C14 74 24 48 38 34 C46 26 58 26 66 34 C80 48 90 74 82 100 C74 108 30 108 22 100 Z"
          fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}" stroke-linejoin="round"/>

    <!-- Front Paws -->
    <ellipse cx="42" cy="102" rx="7.5" ry="5.5" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <ellipse cx="58" cy="102" rx="7.5" ry="5.5" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>

    <!-- Rounded Head -->
    <circle cx="50" cy="30" r="19" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>

    <!-- Left Ear with signature notch -->
    <path d="M36 22 L39 4 C40 2 42 2 43 4 L50 14 Z" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <path d="M38 18 L40 7 L46 15 Z" fill="{ear_shade}"/>

    <!-- Right Ear with signature notch -->
    <path d="M52 14 L59 2 C61 1 62 2 63 4 L66 22 Z" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <path d="M54 14 L60 6 L63 19 Z" fill="{ear_shade}"/>

    <!-- Friendly Eyes -->
    <ellipse cx="44" cy="28" rx="2.5" ry="3.5" fill="{detail_color}"/>
    <ellipse cx="56" cy="28" rx="2.5" ry="3.5" fill="{detail_color}"/>

    <!-- Nose & Smile -->
    <polygon points="49,34 51,34 50,35.5" fill="{detail_color}"/>
    <path d="M47 37 Q50 39 53 37" fill="none" stroke="{detail_color}" stroke-width="1" stroke-linecap="round"/>
  </g>
</svg>
"""


def make_mono_avatar(is_dark: bool) -> str:
    m = MONO_DARK if is_dark else MONO_LIGHT
    bg_circle = "rgba(255, 255, 255, 0.08)" if is_dark else "#E2E2E2"
    rim_color = m["rim"]
    emblem = make_mono_emblem(is_dark)
    inner_g = emblem[emblem.find("<g"):emblem.rfind("</svg>")]

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <circle cx="64" cy="64" r="62" fill="{bg_circle}" stroke="{rim_color}" stroke-width="1.5"/>
  <g transform="translate(0, 2)">
    {inner_g}
  </g>
</svg>
"""


# Write Mono SVGs
(DOORSTEP_DIR / "background-dark.svg").write_text(make_mono_background(True), encoding="utf-8")
(DOORSTEP_DIR / "background-light.svg").write_text(make_mono_background(False), encoding="utf-8")
(DOORSTEP_DIR / "background.svg").write_text(make_mono_background(True), encoding="utf-8")

(DOORSTEP_DIR / "doorstep-cat-dark.svg").write_text(make_mono_emblem(True), encoding="utf-8")
(DOORSTEP_DIR / "doorstep-cat-light.svg").write_text(make_mono_emblem(False), encoding="utf-8")
(DOORSTEP_DIR / "doorstep-cat.svg").write_text(make_mono_emblem(True), encoding="utf-8")

(DOORSTEP_DIR / "avatar-dark.svg").write_text(make_mono_avatar(True), encoding="utf-8")
(DOORSTEP_DIR / "avatar-light.svg").write_text(make_mono_avatar(False), encoding="utf-8")
(DOORSTEP_DIR / "avatar-default.svg").write_text(make_mono_avatar(True), encoding="utf-8")

print("Generated friendly Casper Mono Doorstep SVG assets successfully.")
