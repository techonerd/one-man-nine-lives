#!/usr/bin/env python3
"""Render preview.png: a mock window in Tabby & Tweed Light and Dark. Needs ImageMagick (magick).
SPDX-License-Identifier: GPL-3.0-or-later"""
import html, pathlib, subprocess, sys, tempfile
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from generate import LIGHT, DARK  # noqa: E402

def mock(p, x):
    f = 'font-family="sans-serif"'
    return f'''<g transform="translate({x},20)">
  <rect width="420" height="300" rx="10" fill="{p['window']}" stroke="{p['window_alt']}"/>
  <path d="M0 10 Q0 0 10 0 H410 Q420 0 420 10 V38 H0 Z" fill="{p['header']}"/>
  <text x="16" y="25" {f} font-size="14" font-weight="600" fill="{p['text']}">{html.escape(p['name'])}</text>
  <circle cx="400" cy="19" r="7" fill="{p['negative']}"/><circle cx="378" cy="19" r="7" fill="{p['inactive']}"/>
  <rect x="16" y="54" width="388" height="150" rx="6" fill="{p['view']}" stroke="{p['window_alt']}"/>
  <rect x="17" y="64" width="386" height="28" fill="{p['selection']}"/>
  <text x="30" y="83" {f} font-size="13" fill="{p['selection_text']}">Selected item</text>
  <text x="30" y="113" {f} font-size="13" fill="{p['text']}">Normal text</text>
  <text x="30" y="139" {f} font-size="13" fill="{p['inactive']}">Inactive text</text>
  <text x="30" y="165" {f} font-size="13" fill="{p['link']}" text-decoration="underline">A link</text>
  <text x="130" y="165" {f} font-size="13" fill="{p['positive']}">Positive</text>
  <text x="210" y="165" {f} font-size="13" fill="{p['neutral']}">Neutral</text>
  <text x="290" y="165" {f} font-size="13" fill="{p['negative']}">Negative</text>
  <rect x="16" y="222" width="120" height="34" rx="6" fill="{p['button']}" stroke="{p['window_alt']}"/>
  <text x="76" y="244" {f} font-size="13" text-anchor="middle" fill="{p['text']}">Button</text>
  <rect x="148" y="222" width="120" height="34" rx="6" fill="{p['button']}" stroke="{p['accent']}" stroke-width="2"/>
  <text x="208" y="244" {f} font-size="13" text-anchor="middle" fill="{p['text']}">Focused</text>
  <rect x="280" y="222" width="124" height="34" rx="6" fill="{p['complementary']}"/>
  <text x="342" y="244" {f} font-size="13" text-anchor="middle" fill="{p['complementary_text']}">Panel</text>
</g>'''

svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="900" height="340"><rect width="900" height="340" fill="#808080"/>{mock(LIGHT, 20)}{mock(DARK, 460)}</svg>'
out = pathlib.Path(__file__).resolve().parent.parent / "preview.png"
with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as t:
    t.write(svg)
subprocess.run(["magick", "-density", "96", t.name, str(out)], check=True)
pathlib.Path(t.name).unlink()
print(f"wrote {out}")
