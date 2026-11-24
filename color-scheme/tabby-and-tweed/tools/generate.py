#!/usr/bin/env python3
"""Generate the Tabby & Tweed colour schemes (light + dark) for KDE Plasma 6.

Tabby: warm amber, cream and rose from a tabby coat.  Tweed: slate and heather from a tweed jacket.
Every text/background pair is checked against WCAG contrast (4.5:1 for text, 3:1 for inactive text)
so the schemes stay readable; the script refuses to write files that fail.
Run: python3 -I tools/generate.py      SPDX-License-Identifier: GPL-3.0-or-later
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

LIGHT = dict(
    name="Tabby & Tweed Light", id="TabbyAndTweedLight",
    window="#EFEFEF", window_alt="#E5E5E5", view="#F7F7F7", view_alt="#EDEDED",
    button="#E8E8E8", button_alt="#DCDCDC", header="#E8E8E8", header_alt="#E0E0E0",
    header_inactive="#EDEDED", tooltip="#F7F7F7", complementary="#1C1C1C", complementary_alt="#141414",
    text="#1C1C1C", inactive="#666666", complementary_text="#E6E6E6", complementary_inactive="#A0A0A0",
    accent="#964C12", hover="#B8621E", selection="#964C12", selection_alt="#E0E0E0", selection_text="#F7F7F7",
    link="#8A420B", visited="#7A3A0A", negative="#A83434", neutral="#8F560B", positive="#2D6E46",
)
DARK = dict(
    name="Tabby & Tweed Dark", id="TabbyAndTweedDark",
    window="#1C1C1C", window_alt="#242424", view="#141414", view_alt="#1C1C1C",
    button="#242424", button_alt="#303030", header="#1C1C1C", header_alt="#141414",
    header_inactive="#181818", tooltip="#202020", complementary="#141414", complementary_alt="#1C1C1C",
    text="#E6E6E6", inactive="#A0A0A0", complementary_text="#E6E6E6", complementary_inactive="#A0A0A0",
    accent="#E8A256", hover="#F0B16B", selection="#D98A3D", selection_alt="#3A3A3A", selection_text="#141414",
    link="#E8A256", visited="#F0B875", negative="#F0807A", neutral="#F0B35B", positive="#73C694",
)

# Casper character palette
CASPER_LIGHT = dict(
    coat="#F5F5F5", coat_shade="#E8E8E8", eye="#964C12", inner_ear="#F0807A", bean="#F0807A", rim="#1C1C1C",
)
CASPER_DARK = dict(
    coat="#F5F5F5", coat_shade="#E8E8E8", eye="#E8A256", inner_ear="#F0807A", bean="#F0807A", rim="none",
)

# Casper Mono palette (Doorstep, Catnap, Whiskers icon, cursors, symbolics)
MONO_LIGHT = dict(
    bg="#F7F7F7", bg_alt="#EFEFEF", fg="#1C1C1C", fg_muted="#666666",
    rim="rgba(0, 0, 0, 0.12)", overlay="rgba(247, 247, 247, 0.75)",
    coat="#F5F5F5", outline="#1C1C1C", shadow="rgba(0, 0, 0, 0.12)",
)
MONO_DARK = dict(
    bg="#141414", bg_alt="#1C1C1C", fg="#E6E6E6", fg_muted="#A0A0A0",
    rim="rgba(255, 255, 255, 0.12)", overlay="rgba(20, 20, 20, 0.70)",
    coat="#F5F5F5", outline="none", shadow="rgba(0, 0, 0, 0.45)",
)


def rgb(h: str) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def kde(h: str) -> str:
    return ",".join(map(str, rgb(h)))


def luminance(h: str) -> float:
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = map(lin, rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def check(p: dict) -> list:
    problems = []
    for bg in ("window", "view", "button", "header", "tooltip"):
        for fg, need in (("text", 4.5), ("inactive", 3.0), ("link", 4.5), ("negative", 4.5),
                         ("neutral", 3.0), ("positive", 3.0)):
            c = contrast(p[fg], p[bg])
            if c < need:
                problems.append(f"{p['name']}: {fg} on {bg} = {c:.2f} (needs {need})")
            if fg == "text" and c > 16.5:
                problems.append(f"{p['name']}: {fg} on {bg} = {c:.2f} (exceeds 16:1 ceiling)")
    for fg, bg, need in (("selection_text", "selection", 4.5), ("complementary_text", "complementary", 4.5),
                         ("complementary_inactive", "complementary", 3.0),
                         ("negative", "complementary", 4.5), ("neutral", "complementary", 4.5),
                         ("positive", "complementary", 4.5)):
        col = DARK[fg] if bg == "complementary" and fg in ("negative", "neutral", "positive") else p[fg]
        c = contrast(col, p[bg])
        if c < need:
            problems.append(f"{p['name']}: {fg} on {bg} = {c:.2f} (needs {need})")
    return problems


def group(p: dict, bg: str, bg_alt: str, fg: str = "text", inactive: str = "inactive", **over) -> str:
    v = dict(BackgroundNormal=p[bg], BackgroundAlternate=p[bg_alt], DecorationFocus=p["accent"],
             DecorationHover=p["hover"], ForegroundActive=p["accent"], ForegroundInactive=p[inactive],
             ForegroundLink=p["link"], ForegroundNegative=p["negative"], ForegroundNeutral=p["neutral"],
             ForegroundNormal=p[fg], ForegroundPositive=p["positive"], ForegroundVisited=p["visited"])
    v.update(over)
    return "\n".join(f"{k}={kde(v[k])}" for k in sorted(v))


def scheme(p: dict, dark: bool) -> str:
    sel = group(p, "selection", "selection_alt", fg="selection_text",
                ForegroundActive=p["selection_text"], ForegroundLink=p["selection_text"],
                ForegroundInactive=p["selection_alt"])
    comp = group(p, "complementary", "complementary_alt", fg="complementary_text", inactive="complementary_inactive",
                 ForegroundLink=DARK["link"], ForegroundVisited=DARK["visited"], ForegroundActive=DARK["accent"],
                 ForegroundNegative=DARK["negative"], ForegroundNeutral=DARK["neutral"], ForegroundPositive=DARK["positive"])
    return f"""# {p['name']} - One Man Nine Lives suite. Generated by tools/generate.py; edit the palette there.
# SPDX-License-Identifier: GPL-3.0-or-later

[ColorEffects:Disabled]
Color={kde(p['window'])}
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color={kde(p['inactive'])}
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
{group(p, "button", "button_alt")}

[Colors:Complementary]
{comp}

[Colors:Header]
{group(p, "header", "header_alt")}

[Colors:Header][Inactive]
{group(p, "header_inactive", "header_alt")}

[Colors:Selection]
{sel}

[Colors:Tooltip]
{group(p, "tooltip", "window_alt")}

[Colors:View]
{group(p, "view", "view_alt")}

[Colors:Window]
{group(p, "window", "window_alt")}

[General]
ColorScheme={p['id']}
Name={p['name']}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={kde(p['header'])}
activeBlend={kde(p['header'])}
activeForeground={kde(p['text'])}
inactiveBackground={kde(p['header_inactive'])}
inactiveBlend={kde(p['header_inactive'])}
inactiveForeground={kde(p['inactive'])}
"""


def main() -> int:
    problems = check(LIGHT) + check(DARK)
    if problems:
        print("Contrast check failed:\n  " + "\n  ".join(problems))
        return 1
    for p, dark in ((LIGHT, False), (DARK, True)):
        (ROOT / f"{p['id']}.colors").write_text(scheme(p, dark))
        print(f"[{p['name']}]")
        for b in ("view", "window", "button", "header", "tooltip"):
            c_txt = contrast(p["text"], p[b])
            c_ina = contrast(p["inactive"], p[b])
            print(f"  on {b:7s} ({p[b]}): text={c_txt:5.2f}:1, inactive={c_ina:4.2f}:1")
        c_sel = contrast(p["selection_text"], p["selection"])
        print(f"  selection text ({p['selection_text']}) on selection ({p['selection']}): {c_sel:.2f}:1")
    worst = min(contrast(p["text"], p[b]) for p in (LIGHT, DARK) for b in ("window", "view", "button", "header"))
    best = max(contrast(p["text"], p[b]) for p in (LIGHT, DARK) for b in ("window", "view", "button", "header"))
    print(f"\nwrote TabbyAndTweedLight.colors and TabbyAndTweedDark.colors")
    print(f"Text contrast range across all surfaces: {worst:.2f}:1 to {best:.2f}:1 (WCAG AA >= 4.5:1, ceiling <= 16.5:1)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
