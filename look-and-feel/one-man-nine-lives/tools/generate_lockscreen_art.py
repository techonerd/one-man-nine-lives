#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Generate Casper Mono SVGs for Catnap lockscreen (One Man Nine Lives).

Casper Mono rules (tasks/media.md section 1):
  - Casper is ALWAYS white (off-white coat #F5F5F5, never #FFFFFF).
  - Dark mode: off-white coat (#F5F5F5), no outline, faint shadow, dark background (#0E0E0E).
  - Light mode: off-white coat (#F5F5F5), near-black outline (#121212, >= 3:1 contrast),
    soft shadow, placed on a mid-tone area (#E2E2E2), light background (#FFFFFF).
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "color-scheme" / "tabby-and-tweed" / "tools"))
from generate import MONO_DARK, MONO_LIGHT  # noqa: E402


def make_mono_sleeping_cat(is_dark: bool) -> str:
    coat = "#F5F5F5"
    outline = "none" if is_dark else "#121212"
    stroke_w = "0" if is_dark else "3.2"
    shadow = "rgba(0, 0, 0, 0.45)" if is_dark else "rgba(0, 0, 0, 0.15)"
    detail_color = "#222222" if is_dark else "#121212"
    inner_ear = "rgba(0, 0, 0, 0.08)" if is_dark else "rgba(0, 0, 0, 0.12)"
    zzz_color = "#FFFFFF" if is_dark else "#121212"
    mid_tone_pad = "" if is_dark else """<ellipse cx="110" cy="72" rx="105" ry="48" fill="#E2E2E2" opacity="0.65"/>"""

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="256" height="140" viewBox="0 0 256 140">
  <g transform="translate(18, 14)">
    <!-- Mid-tone background pad (light mode) -->
    {mid_tone_pad}

    <!-- Shadow -->
    <ellipse cx="110" cy="98" rx="80" ry="14" fill="{shadow}"/>

    <!-- Curled Sleeping Tail -->
    <path d="M168 76 C202 76 210 48 192 34 C180 24 168 32 173 43 C176 52 168 64 144 68 Z"
          fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}" stroke-linejoin="round"/>

    <!-- Rounded Bean Body Arch -->
    <path d="M48 78 C28 50 50 16 102 16 C158 16 186 46 176 78 C166 100 128 104 88 100 C64 98 52 88 48 78 Z"
          fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}" stroke-linejoin="round"/>

    <!-- Soft Rounded Head -->
    <circle cx="62" cy="62" r="27" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>

    <!-- Left Rounded Ear with signature notch -->
    <path d="M42 46 L45 20 C46 18 48 18 49 20 L58 36 Z" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <path d="M45 42 L47 24 L54 36 Z" fill="{inner_ear}"/>

    <!-- Right Rounded Ear with signature notch -->
    <path d="M64 34 L75 16 C77 15 79 16 80 18 L83 42 Z" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <path d="M68 34 L76 21 L80 38 Z" fill="{inner_ear}"/>

    <!-- Tucked Front Paws -->
    <ellipse cx="88" cy="80" rx="11" ry="8" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>
    <ellipse cx="104" cy="80" rx="10" ry="7.5" fill="{coat}" stroke="{outline}" stroke-width="{stroke_w}"/>

    <!-- Smiling Closed Sleeping Eyes -->
    <path d="M46 64 Q52 70 58 64" fill="none" stroke="{detail_color}" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M62 64 Q68 70 74 64" fill="none" stroke="{detail_color}" stroke-width="2.5" stroke-linecap="round"/>

    <!-- Sweet Tiny Nose -->
    <polygon points="59,71 63,71 61,74" fill="{detail_color}" opacity="0.8"/>

    <!-- Whisker Glints -->
    <g stroke="{detail_color}" stroke-width="0.9" stroke-linecap="round" opacity="0.35">
      <line x1="42" y1="68" x2="28" y2="66"/>
      <line x1="42" y1="71" x2="29" y2="73"/>
      <line x1="76" y1="68" x2="90" y2="66"/>
      <line x1="76" y1="71" x2="89" y2="73"/>
    </g>

    <!-- Friendly Zzz -->
    <g fill="{zzz_color}" font-family="sans-serif" font-weight="bold">
      <text x="145" y="26" font-size="14" opacity="0.5">z</text>
      <text x="158" y="16" font-size="18" opacity="0.7">z</text>
      <text x="174" y="6" font-size="22" opacity="0.9">Z</text>
    </g>
  </g>
</svg>
"""


def make_mono_bg(is_dark: bool) -> str:
    m = MONO_DARK if is_dark else MONO_LIGHT
    bg_color = m["bg"]
    fade_color = "#161616" if is_dark else "#F5F5F5"
    beam_color = m["fg"]

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="2560" height="1600" viewBox="0 0 2560 1600">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{bg_color}"/>
      <stop offset="100%" stop-color="{fade_color}"/>
    </linearGradient>
    <linearGradient id="beamGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{beam_color}" stop-opacity="{'0.04' if is_dark else '0.03'}"/>
      <stop offset="60%" stop-color="{beam_color}" stop-opacity="{'0.015' if is_dark else '0.01'}"/>
      <stop offset="100%" stop-color="{beam_color}" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <rect width="2560" height="1600" fill="url(#bgGrad)"/>
  <path d="M1600 0 L2200 0 L1200 1600 L460 1600 Z" fill="url(#beamGrad)"/>
</svg>
"""


template_file = ROOT / "look-and-feel" / "one-man-nine-lives" / "tools" / "LockScreenUi.qml.in"
template_content = template_file.read_text(encoding="utf-8")

for v, is_dark in [("dark", True), ("light", False)]:
    m = MONO_DARK if is_dark else MONO_LIGHT

    # Generate LockScreenUi.qml from the single template
    qml_content = template_content
    qml_content = qml_content.replace("@IS_DARK@", "true" if is_dark else "false")
    qml_content = qml_content.replace("@MONO_BG@", m["bg"])
    qml_content = qml_content.replace("@MONO_FG@", m["fg"])
    qml_content = qml_content.replace("@MONO_FG_MUTED@", m["fg_muted"])
    rim_val = "Qt.rgba(1, 1, 1, 0.12)" if is_dark else "Qt.rgba(0, 0, 0, 0.12)"
    overlay_val = "Qt.rgba(0.08, 0.08, 0.08, 0.70)" if is_dark else "Qt.rgba(0.97, 0.97, 0.97, 0.75)"
    qml_content = qml_content.replace("@MONO_RIM@", rim_val)
    qml_content = qml_content.replace("@MONO_OVERLAY@", overlay_val)

    ls_dir = ROOT / "look-and-feel" / "one-man-nine-lives" / v / "contents" / "lockscreen"
    ls_dir.mkdir(parents=True, exist_ok=True)
    (ls_dir / "sleeping-cat.svg").write_text(make_mono_sleeping_cat(is_dark), encoding="utf-8")
    (ls_dir / "lockscreen-bg.svg").write_text(make_mono_bg(is_dark), encoding="utf-8")
    (ls_dir / "LockScreenUi.qml").write_text(qml_content, encoding="utf-8")

    # Also update shell packages
    shell_dir = ROOT / "look-and-feel" / "one-man-nine-lives" / "shells" / f"com.github.techonerd.catnap.{v}" / "contents" / "lockscreen"
    shell_dir.mkdir(parents=True, exist_ok=True)
    (shell_dir / "sleeping-cat.svg").write_text(make_mono_sleeping_cat(is_dark), encoding="utf-8")
    (shell_dir / "lockscreen-bg.svg").write_text(make_mono_bg(is_dark), encoding="utf-8")
    (shell_dir / "LockScreenUi.qml").write_text(qml_content, encoding="utf-8")

print("Generated Casper Mono SVGs and LockScreenUi.qml from template for Catnap (light + dark).")
