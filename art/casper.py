#!/usr/bin/env python3
"""Casper shared parts library – the cat drawn one way everywhere.

Every component's tools/generate.py imports this module so Casper is consistent
across the entire One Man Nine Lives suite.

Poses: loaf, stretch, curl, sit, peek, paw, tail, paw_print.
Each pose function: pose(x, y, size, palette) -> SVG string.

The palette dict must have at minimum: coat, coat_shade (or coat-shade),
outline, shadow, eye, inner_ear (or inner-ear), bean.
For MONO contexts pass a dict with coat/outline/shadow only (eye etc. unused).

SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: techonerd
"""
from __future__ import annotations

import math
import pathlib
import sys

# ---------------------------------------------------------------------------
# Palette access
# ---------------------------------------------------------------------------
_REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_REPO / "color-scheme" / "tabby-and-tweed" / "tools"))
from generate import (  # noqa: E402
    CASPER_LIGHT, CASPER_DARK, MONO_LIGHT, MONO_DARK, LIGHT, DARK,
)


def _g(pal: dict, key: str, fallback: str = "none") -> str:
    """Get a palette value by underscore or hyphen key."""
    return pal.get(key, pal.get(key.replace("_", "-"), fallback))


# ---------------------------------------------------------------------------
# Low-level SVG helpers
# ---------------------------------------------------------------------------

def _scale(pts: list[tuple[float, float]], s: float, ox: float, oy: float):
    """Scale and translate a list of (x,y) points.  Canvas is 64-unit."""
    return [(ox + p[0] * s / 64, oy + p[1] * s / 64) for p in pts]


def _ellipse(cx, cy, rx, ry, fill, **kw) -> str:
    extra = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in kw.items())
    return f'<ellipse cx="{cx:.2f}" cy="{cy:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="{fill}" {extra}/>'


def _circle(cx, cy, r, fill, **kw) -> str:
    extra = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in kw.items())
    return f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r:.2f}" fill="{fill}" {extra}/>'


def _path(d: str, fill: str = "none", stroke: str = "none",
          stroke_width: float = 0, **kw) -> str:
    extra = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in kw.items())
    sw = f' stroke-width="{stroke_width:.2f}"' if stroke_width else ""
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}"{sw} {extra}/>'


def _fmt(v: float) -> str:
    """Format a float for SVG path data: trim trailing zeros."""
    return f"{v:.2f}".rstrip("0").rstrip(".")


def _f(v: float) -> str:
    return _fmt(v)


# ---------------------------------------------------------------------------
# Shared body parts (all on a 64-unit canvas)
# ---------------------------------------------------------------------------

def _ear_paths(lx, ly, rx, ry, ear_h=10, ear_w=6):
    """Return (left_ear_d, right_ear_d) path data for two triangular ears."""
    # Left ear: triangle pointing up-left
    ld = (f"M{_f(lx - ear_w)} {_f(ly)} "
          f"Q{_f(lx - ear_w * 0.3)} {_f(ly - ear_h)} {_f(lx + ear_w * 0.4)} {_f(ly)} Z")
    # Right ear: mirror
    rd = (f"M{_f(rx - ear_w * 0.4)} {_f(ry)} "
          f"Q{_f(rx + ear_w * 0.3)} {_f(ry - ear_h)} {_f(rx + ear_w)} {_f(ry)} Z")
    return ld, rd


def _inner_ear_paths(lx, ly, rx, ry, ear_h=10, ear_w=6):
    """Smaller inner ear triangles for the rose/inner-ear colour."""
    s = 0.55  # inner ear scale
    oh = ear_h * 0.15  # offset down
    ld = (f"M{_f(lx - ear_w * s)} {_f(ly + oh)} "
          f"Q{_f(lx - ear_w * 0.3 * s)} {_f(ly - ear_h * s + oh)} "
          f"{_f(lx + ear_w * 0.4 * s)} {_f(ly + oh)} Z")
    rd = (f"M{_f(rx - ear_w * 0.4 * s)} {_f(ry + oh)} "
          f"Q{_f(rx + ear_w * 0.3 * s)} {_f(ry - ear_h * s + oh)} "
          f"{_f(rx + ear_w * s)} {_f(ry + oh)} Z")
    return ld, rd


def _eye(cx, cy, r, pal):
    """A simple cat eye: coloured circle with a vertical slit pupil."""
    eye_col = _g(pal, "eye", "#E8A256")
    parts = [_circle(cx, cy, r, eye_col)]
    # Slit pupil
    pr = r * 0.3
    parts.append(_ellipse(cx, cy, pr, r * 0.8, "#0E0E0E"))
    return "\n".join(parts)


def _nose(cx, cy, s, pal):
    """Small triangle nose."""
    ns = s * 0.04
    d = (f"M{_f(cx)} {_f(cy)} "
         f"L{_f(cx - ns)} {_f(cy + ns * 1.2)} "
         f"L{_f(cx + ns)} {_f(cy + ns * 1.2)} Z")
    return _path(d, fill=_g(pal, "bean", _g(pal, "inner_ear", "#F0807A")))


def _whiskers(cx, cy, s, pal):
    """Three whiskers each side."""
    col = _g(pal, "outline", _g(pal, "fg", "#0E0E0E"))
    if col == "none":
        col = _g(pal, "coat_shade", "#E8E8E8")
    sw = max(s * 0.015, 0.5)
    lines = []
    for side in (-1, 1):
        for angle_deg in (-12, 0, 12):
            angle = math.radians(angle_deg)
            wl = s * 0.18
            x1 = cx + side * s * 0.06
            y1 = cy + s * 0.01
            x2 = x1 + side * wl * math.cos(angle)
            y2 = y1 + wl * math.sin(angle)
            lines.append(f'<line x1="{_f(x1)}" y1="{_f(y1)}" x2="{_f(x2)}" y2="{_f(y2)}" '
                         f'stroke="{col}" stroke-width="{_f(sw)}" stroke-linecap="round"/>')
    return "\n".join(lines)


def _shadow_filter(fid: str, pal: dict) -> str:
    """A subtle drop-shadow SVG filter."""
    shadow = _g(pal, "shadow", "rgba(0,0,0,0.15)")
    return (f'<filter id="{fid}" x="-20%" y="-20%" width="140%" height="140%">'
            f'<feDropShadow dx="0" dy="1" stdDeviation="2" flood-color="{shadow}" flood-opacity="0.4"/>'
            f'</filter>')


def _outline_style(pal: dict, sw: float) -> str:
    """Return stroke attributes for the Casper outline, or empty string."""
    outline = _g(pal, "outline", "none")
    if outline == "none" or not outline:
        return ""
    return f'stroke="{outline}" stroke-width="{_f(sw)}" stroke-linejoin="round"'


# ---------------------------------------------------------------------------
# Poses – each returns an SVG group string
# All are drawn on a 64×64 canvas and then scaled/translated to (x, y, size).
# ---------------------------------------------------------------------------

def loaf(x: float, y: float, size: float, pal: dict) -> str:
    """Cat loaf – compact rounded body, tucked paws, alert ears."""
    s = size
    # Build at canvas then wrap in a transform
    parts = []
    fid = f"shadow-loaf-{id(pal)}"
    parts.append(_shadow_filter(fid, pal))

    coat = _g(pal, "coat", "#F5F5F5")
    shade = _g(pal, "coat_shade", "#E8E8E8")
    osty = _outline_style(pal, s * 0.03)

    # Body: a wide, squat ellipse
    bx, by = 32, 40
    brx, bry = 20, 12
    parts.append(f'<ellipse cx="{_f(bx)}" cy="{_f(by)}" rx="{_f(brx)}" ry="{_f(bry)}" '
                 f'fill="{coat}" {osty} filter="url(#{fid})"/>')
    # Shade on bottom
    parts.append(f'<ellipse cx="{_f(bx)}" cy="{_f(by + 3)}" rx="{_f(brx - 2)}" ry="{_f(bry * 0.5)}" '
                 f'fill="{shade}" opacity="0.5"/>')
    # Head
    hx, hy = 32, 26
    hr = 10
    parts.append(f'<circle cx="{_f(hx)}" cy="{_f(hy)}" r="{_f(hr)}" fill="{coat}" {osty}/>')
    # Ears
    le, re = _ear_paths(hx - 6, hy - 7, hx + 6, hy - 7, ear_h=8, ear_w=5)
    parts.append(_path(le, fill=coat, **({} if not osty else {"stroke": _g(pal, "outline"), "stroke_width": s * 0.03})))
    parts.append(_path(re, fill=coat, **({} if not osty else {"stroke": _g(pal, "outline"), "stroke_width": s * 0.03})))
    # Inner ears
    lie, rie = _inner_ear_paths(hx - 6, hy - 7, hx + 6, hy - 7, ear_h=8, ear_w=5)
    ie_col = _g(pal, "inner_ear", "#F0807A")
    parts.append(_path(lie, fill=ie_col))
    parts.append(_path(rie, fill=ie_col))
    # Eyes
    parts.append(_eye(hx - 3.5, hy - 1, 1.8, pal))
    parts.append(_eye(hx + 3.5, hy - 1, 1.8, pal))
    # Nose
    parts.append(_nose(hx, hy + 2.5, 64, pal))
    # Whiskers
    parts.append(_whiskers(hx, hy + 3.5, 64, pal))
    # Tail curling out right
    tail_d = f"M{_f(52)} {_f(40)} Q{_f(58)} {_f(36)} {_f(56)} {_f(30)} Q{_f(54)} {_f(26)} {_f(56)} {_f(24)}"
    parts.append(_path(tail_d, stroke=coat, stroke_width=3,
                       **({} if not osty else {"fill": "none"})))
    if osty:
        parts.append(_path(tail_d, stroke=_g(pal, "outline"), stroke_width=3 + s * 0.03 * 2, fill="none", opacity="0.3"))

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def stretch(x: float, y: float, size: float, pal: dict) -> str:
    """Cat stretching – long body, front paws extended, back arched."""
    s = size
    parts = []
    fid = f"shadow-stretch-{id(pal)}"
    parts.append(_shadow_filter(fid, pal))

    coat = _g(pal, "coat", "#F5F5F5")
    shade = _g(pal, "coat_shade", "#E8E8E8")
    osty = _outline_style(pal, s * 0.03)

    # Back arch
    body_d = (f"M{_f(10)} {_f(48)} Q{_f(14)} {_f(28)} {_f(28)} {_f(26)} "
              f"Q{_f(38)} {_f(24)} {_f(46)} {_f(32)} Q{_f(52)} {_f(36)} {_f(54)} {_f(44)}")
    parts.append(_path(body_d, stroke=coat, stroke_width=14, fill="none",
                       stroke_linecap="round", filter=f"url(#{fid})"))
    if osty:
        parts.append(_path(body_d, stroke=_g(pal, "outline"), stroke_width=14 + 2, fill="none",
                           stroke_linecap="round", opacity="0.15"))
    # Front paws extended
    parts.append(f'<line x1="{_f(10)}" y1="{_f(48)}" x2="{_f(4)}" y2="{_f(56)}" '
                 f'stroke="{coat}" stroke-width="4" stroke-linecap="round"/>')
    parts.append(f'<line x1="{_f(14)}" y1="{_f(48)}" x2="{_f(8)}" y2="{_f(56)}" '
                 f'stroke="{coat}" stroke-width="4" stroke-linecap="round"/>')
    # Paw beans at tips
    bean = _g(pal, "bean", "#F0807A")
    parts.append(_circle(4, 56, 1.5, bean))
    parts.append(_circle(8, 56, 1.5, bean))
    # Hind legs
    parts.append(f'<line x1="{_f(50)}" y1="{_f(42)}" x2="{_f(50)}" y2="{_f(56)}" '
                 f'stroke="{coat}" stroke-width="5" stroke-linecap="round"/>')
    parts.append(f'<line x1="{_f(56)}" y1="{_f(44)}" x2="{_f(56)}" y2="{_f(56)}" '
                 f'stroke="{coat}" stroke-width="5" stroke-linecap="round"/>')
    # Head (looking down at paws)
    hx, hy = 14, 34
    parts.append(_circle(hx, hy, 8, coat, **({} if not osty else
                 {"stroke": _g(pal, "outline"), "stroke_width": s * 0.03})))
    # Ears
    le, re = _ear_paths(hx - 5, hy - 5.5, hx + 5, hy - 5.5, ear_h=7, ear_w=4)
    parts.append(_path(le, fill=coat))
    parts.append(_path(re, fill=coat))
    lie, rie = _inner_ear_paths(hx - 5, hy - 5.5, hx + 5, hy - 5.5, ear_h=7, ear_w=4)
    parts.append(_path(lie, fill=_g(pal, "inner_ear", "#F0807A")))
    parts.append(_path(rie, fill=_g(pal, "inner_ear", "#F0807A")))
    # Eyes (half-closed, content)
    parts.append(f'<line x1="{_f(hx - 4)}" y1="{_f(hy - 0.5)}" x2="{_f(hx - 1.5)}" y2="{_f(hy - 0.5)}" '
                 f'stroke="{_g(pal, "eye", "#E8A256")}" stroke-width="1.5" stroke-linecap="round"/>')
    parts.append(f'<line x1="{_f(hx + 1.5)}" y1="{_f(hy - 0.5)}" x2="{_f(hx + 4)}" y2="{_f(hy - 0.5)}" '
                 f'stroke="{_g(pal, "eye", "#E8A256")}" stroke-width="1.5" stroke-linecap="round"/>')
    parts.append(_nose(hx, hy + 2, 64, pal))
    # Tail up
    tail_d = f"M{_f(54)} {_f(38)} Q{_f(60)} {_f(28)} {_f(58)} {_f(18)} Q{_f(56)} {_f(14)} {_f(60)} {_f(12)}"
    parts.append(_path(tail_d, stroke=coat, stroke_width=3, fill="none", stroke_linecap="round"))

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def curl(x: float, y: float, size: float, pal: dict) -> str:
    """Cat curled up asleep – circular, tail wrapping around, eyes closed."""
    s = size
    parts = []
    fid = f"shadow-curl-{id(pal)}"
    parts.append(_shadow_filter(fid, pal))

    coat = _g(pal, "coat", "#F5F5F5")
    shade = _g(pal, "coat_shade", "#E8E8E8")
    osty = _outline_style(pal, s * 0.03)

    # Round body
    bx, by = 32, 36
    br = 16
    parts.append(_circle(bx, by, br, coat, filter=f"url(#{fid})",
                         **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    # Shade crescent
    parts.append(f'<path d="M{_f(bx - 14)} {_f(by + 4)} A14 14 0 0 0 {_f(bx + 14)} {_f(by + 4)} '
                 f'A16 10 0 0 1 {_f(bx - 14)} {_f(by + 4)} Z" fill="{shade}" opacity="0.4"/>')
    # Head on the body
    hx, hy = 26, 26
    hr = 8
    parts.append(_circle(hx, hy, hr, coat,
                         **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    # Ears
    le, re = _ear_paths(hx - 4.5, hy - 5, hx + 4.5, hy - 5, ear_h=6, ear_w=4)
    parts.append(_path(le, fill=coat))
    parts.append(_path(re, fill=coat))
    lie, rie = _inner_ear_paths(hx - 4.5, hy - 5, hx + 4.5, hy - 5, ear_h=6, ear_w=4)
    parts.append(_path(lie, fill=_g(pal, "inner_ear", "#F0807A")))
    parts.append(_path(rie, fill=_g(pal, "inner_ear", "#F0807A")))
    # Closed eyes (zzz)
    ecol = _g(pal, "outline", _g(pal, "fg", "#0E0E0E"))
    if ecol == "none":
        ecol = shade
    for ex in (hx - 3, hx + 3):
        parts.append(f'<path d="M{_f(ex - 1.5)} {_f(hy)} Q{_f(ex)} {_f(hy + 1.5)} {_f(ex + 1.5)} {_f(hy)}" '
                     f'fill="none" stroke="{ecol}" stroke-width="1" stroke-linecap="round"/>')
    parts.append(_nose(hx, hy + 2, 64, pal))
    # Tail wrapping around
    tail_d = (f"M{_f(46)} {_f(44)} Q{_f(50)} {_f(50)} {_f(42)} {_f(52)} "
              f"Q{_f(30)} {_f(54)} {_f(20)} {_f(48)} Q{_f(16)} {_f(44)} {_f(18)} {_f(38)}")
    parts.append(_path(tail_d, stroke=coat, stroke_width=3.5, fill="none", stroke_linecap="round"))
    # Front paw peeking
    parts.append(_circle(34, 44, 3, coat))
    bean = _g(pal, "bean", "#F0807A")
    for dx, dy in [(33.2, 43), (34.8, 43), (34, 43.5)]:
        parts.append(_circle(dx, dy, 0.7, bean))

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def sit(x: float, y: float, size: float, pal: dict) -> str:
    """Cat sitting upright – formal pose, tail curled beside."""
    s = size
    parts = []
    fid = f"shadow-sit-{id(pal)}"
    parts.append(_shadow_filter(fid, pal))

    coat = _g(pal, "coat", "#F5F5F5")
    shade = _g(pal, "coat_shade", "#E8E8E8")
    osty = _outline_style(pal, s * 0.03)

    # Body (tapered oval, wider at base)
    body_d = (f"M{_f(32)} {_f(22)} "
              f"Q{_f(18)} {_f(28)} {_f(18)} {_f(42)} "
              f"Q{_f(18)} {_f(56)} {_f(32)} {_f(56)} "
              f"Q{_f(46)} {_f(56)} {_f(46)} {_f(42)} "
              f"Q{_f(46)} {_f(28)} {_f(32)} {_f(22)} Z")
    parts.append(_path(body_d, fill=coat, filter=f"url(#{fid})",
                       **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    # Shade
    parts.append(f'<ellipse cx="32" cy="50" rx="12" ry="5" fill="{shade}" opacity="0.4"/>')
    # Front paws
    for px in (26, 38):
        parts.append(_circle(px, 54, 3.5, coat))
        bean = _g(pal, "bean", "#F0807A")
        for bx, by in [(px - 1, 53.3), (px + 1, 53.3), (px, 54.5)]:
            parts.append(_circle(bx, by, 0.7, bean))
    # Head
    hx, hy = 32, 16
    hr = 9
    parts.append(_circle(hx, hy, hr, coat,
                         **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    # Ears
    le, re = _ear_paths(hx - 5.5, hy - 6, hx + 5.5, hy - 6, ear_h=8, ear_w=4.5)
    parts.append(_path(le, fill=coat))
    parts.append(_path(re, fill=coat))
    lie, rie = _inner_ear_paths(hx - 5.5, hy - 6, hx + 5.5, hy - 6, ear_h=8, ear_w=4.5)
    parts.append(_path(lie, fill=_g(pal, "inner_ear", "#F0807A")))
    parts.append(_path(rie, fill=_g(pal, "inner_ear", "#F0807A")))
    # Eyes
    parts.append(_eye(hx - 3.5, hy - 1, 1.8, pal))
    parts.append(_eye(hx + 3.5, hy - 1, 1.8, pal))
    parts.append(_nose(hx, hy + 2.5, 64, pal))
    parts.append(_whiskers(hx, hy + 3.5, 64, pal))
    # Tail
    tail_d = (f"M{_f(46)} {_f(50)} Q{_f(56)} {_f(52)} {_f(58)} {_f(46)} "
              f"Q{_f(60)} {_f(40)} {_f(54)} {_f(38)}")
    parts.append(_path(tail_d, stroke=coat, stroke_width=3, fill="none", stroke_linecap="round"))

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def peek(x: float, y: float, size: float, pal: dict) -> str:
    """Cat peeking – ears and eyes visible over an edge, rest hidden."""
    s = size
    parts = []
    coat = _g(pal, "coat", "#F5F5F5")
    osty = _outline_style(pal, s * 0.03)

    # The "edge" line at y=40
    edge_y = 40
    # Ears above the edge
    le, re = _ear_paths(26, edge_y - 2, 38, edge_y - 2, ear_h=10, ear_w=5)
    parts.append(_path(le, fill=coat,
                       **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    parts.append(_path(re, fill=coat,
                       **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    lie, rie = _inner_ear_paths(26, edge_y - 2, 38, edge_y - 2, ear_h=10, ear_w=5)
    parts.append(_path(lie, fill=_g(pal, "inner_ear", "#F0807A")))
    parts.append(_path(rie, fill=_g(pal, "inner_ear", "#F0807A")))
    # Top of head (semi-circle above edge)
    head_d = (f"M{_f(18)} {_f(edge_y)} "
              f"A14 14 0 0 1 {_f(46)} {_f(edge_y)} Z")
    parts.append(_path(head_d, fill=coat,
                       **({"stroke": _g(pal, "outline"), "stroke_width": s * 0.03} if osty else {})))
    # Eyes (wide, alert)
    parts.append(_eye(28, edge_y - 3, 2.2, pal))
    parts.append(_eye(36, edge_y - 3, 2.2, pal))
    # Paws on the edge
    for px in (22, 32, 42):
        parts.append(f'<rect x="{_f(px - 2.5)}" y="{_f(edge_y - 1)}" width="5" height="4" rx="2" fill="{coat}" '
                     f'{osty}/>')
    bean = _g(pal, "bean", "#F0807A")
    for px in (22, 42):
        for bx, by in [(px - 1, edge_y + 1), (px + 1, edge_y + 1), (px, edge_y + 2)]:
            parts.append(_circle(bx, by, 0.6, bean))

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def paw(x: float, y: float, size: float, pal: dict) -> str:
    """Single paw pad with toe beans – the suite's signature mark."""
    s = size
    parts = []
    coat = _g(pal, "coat", "#F5F5F5")
    bean = _g(pal, "bean", "#F0807A")
    osty = _outline_style(pal, s * 0.03)

    # Main pad
    parts.append(f'<ellipse cx="32" cy="38" rx="10" ry="12" fill="{coat}" '
                 f'{osty}/>')
    # Central pad (larger bean)
    parts.append(f'<ellipse cx="32" cy="40" rx="7" ry="8" fill="{bean}" opacity="0.85"/>')
    # Toe beans (4 ovals above)
    for tx, ty in [(22, 24), (28, 20), (36, 20), (42, 24)]:
        parts.append(f'<ellipse cx="{tx}" cy="{ty}" rx="4" ry="5" fill="{coat}" {osty}/>')
        parts.append(f'<ellipse cx="{tx}" cy="{ty + 0.5}" rx="2.8" ry="3.5" fill="{bean}" opacity="0.85"/>')

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def tail(x: float, y: float, size: float, pal: dict) -> str:
    """Elegant tail curl – a sweeping S-curve."""
    s = size
    parts = []
    coat = _g(pal, "coat", "#F5F5F5")
    osty = _outline_style(pal, s * 0.03)

    tail_d = (f"M{_f(16)} {_f(56)} "
              f"Q{_f(10)} {_f(40)} {_f(20)} {_f(28)} "
              f"Q{_f(30)} {_f(16)} {_f(40)} {_f(14)} "
              f"Q{_f(50)} {_f(12)} {_f(52)} {_f(20)} "
              f"Q{_f(54)} {_f(28)} {_f(46)} {_f(30)}")
    sw = 4
    if osty:
        # Outline behind
        parts.append(_path(tail_d, stroke=_g(pal, "outline"), stroke_width=sw + 2,
                           fill="none", stroke_linecap="round", opacity="0.3"))
    parts.append(_path(tail_d, stroke=coat, stroke_width=sw,
                       fill="none", stroke_linecap="round"))
    # Tip thickening
    tip_d = f"M{_f(46)} {_f(30)} Q{_f(42)} {_f(32)} {_f(44)} {_f(34)}"
    parts.append(_path(tip_d, stroke=coat, stroke_width=sw + 1,
                       fill="none", stroke_linecap="round"))

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


def paw_print(x: float, y: float, size: float, pal: dict) -> str:
    """Paw print stamp – the suite's logo mark."""
    s = size
    parts = []
    coat = _g(pal, "coat", "#F5F5F5")
    outline = _g(pal, "outline", "none")
    osty = _outline_style(pal, s * 0.03)

    # Main pad (bean shape)
    parts.append(f'<ellipse cx="32" cy="40" rx="9" ry="10" fill="{coat}" {osty}/>')
    # Four toe beans
    for tx, ty in [(22, 24), (28, 19), (36, 19), (42, 24)]:
        parts.append(f'<ellipse cx="{tx}" cy="{ty}" rx="4" ry="5" fill="{coat}" {osty}/>')

    svg = "\n".join(parts)
    return f'<g transform="translate({_f(x)},{_f(y)}) scale({_f(s / 64)})">\n{svg}\n</g>'


# ---------------------------------------------------------------------------
# All poses in order
# ---------------------------------------------------------------------------
ALL_POSES = [
    ("loaf", loaf),
    ("stretch", stretch),
    ("curl", curl),
    ("sit", sit),
    ("peek", peek),
    ("paw", paw),
    ("tail", tail),
    ("paw_print", paw_print),
]


# ---------------------------------------------------------------------------
# Model sheet renderer
# ---------------------------------------------------------------------------

def model_sheet(out_path: str | pathlib.Path | None = None) -> str:
    """Render art/preview.png – every pose at 256px and 64px, on light and dark.

    Returns the SVG source. If out_path is given (or defaults to art/preview.png),
    also renders to PNG via ImageMagick.
    """
    import subprocess
    import tempfile

    if out_path is None:
        out_path = _REPO / "art" / "preview.png"
    out_path = pathlib.Path(out_path)

    n = len(ALL_POSES)
    # Layout: two rows (light bg, dark bg), each row has 256px poses then 64px poses
    big = 256
    small = 64
    pad = 20
    label_h = 24
    row_h = big + small + pad * 3 + label_h * 2
    # Width: n poses * (big + pad) but let's be generous
    col_w = big + pad
    total_w = n * col_w + pad
    total_h = row_h * 2 + pad * 2

    light_bg = LIGHT["window"]  # #F0F0F0
    dark_bg = DARK["view"]      # #0E0E0E

    # Build palettes for rendering
    # Light mode: Casper is off-white with dark outline (≥3:1)
    pal_light = dict(CASPER_LIGHT)
    pal_light.update({"outline": MONO_LIGHT["outline"], "shadow": MONO_LIGHT["shadow"]})

    # Dark mode: Casper is off-white, no outline, faint shadow
    pal_dark = dict(CASPER_DARK)
    pal_dark.update({"outline": "none", "shadow": MONO_DARK["shadow"]})

    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_w}" height="{total_h}">']
    # Font
    f_attr = 'font-family="sans-serif" font-size="14" font-weight="600"'

    for row_i, (bg_col, pal, mode_label) in enumerate([
        (light_bg, pal_light, "Light"),
        (dark_bg, pal_dark, "Dark"),
    ]):
        ry = pad + row_i * (row_h + pad)
        # Background rect
        parts.append(f'<rect x="0" y="{ry}" width="{total_w}" height="{row_h}" fill="{bg_col}"/>')
        # Mode label
        text_col = "#0E0E0E" if row_i == 0 else "#FFFFFF"
        parts.append(f'<text x="{pad}" y="{ry + 18}" {f_attr} fill="{text_col}">{mode_label} mode</text>')

        for col_i, (pose_name, pose_fn) in enumerate(ALL_POSES):
            cx = pad + col_i * col_w
            # Big pose
            by = ry + label_h + pad
            parts.append(pose_fn(cx, by, big, pal))
            # Label under big
            parts.append(f'<text x="{cx + big / 2}" y="{by + big + 16}" {f_attr} '
                         f'text-anchor="middle" fill="{text_col}">{pose_name}</text>')
            # Small pose below label
            sy = by + big + label_h + pad
            parts.append(pose_fn(cx + (big - small) / 2, sy, small, pal))

    parts.append("</svg>")
    svg_src = "\n".join(parts)

    # Write SVG and render to PNG
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as tmp:
        tmp.write(svg_src)
        tmp_path = tmp.name

    subprocess.run(
        ["magick", "-density", "96", tmp_path, str(out_path)],
        check=True,
    )
    pathlib.Path(tmp_path).unlink()
    print(f"wrote {out_path}")
    return svg_src


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    model_sheet()
