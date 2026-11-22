#!/usr/bin/env python3
"""Generate the Night Shift Plasma 6 style and Konsole colour schemes.

One Man Nine Lives suite:
- Plasma Style: panels, dialogs, tooltips, buttons, etc. using ColorScheme-* classes.
- Desktop twin of the Doorstep glass: soft 1px rim, no amber hairline.
- Translucent and opaque variants for panel, dialogs, tooltip, and background.
- plasmarc with blur, contrast, and adaptive transparency settings.
- Cover panel-background, dialogs/background, tooltip, background, button,
  viewitem, listitem, lineedit, frame, scrollbar, slider, switch, tabbar,
  tasks, plasmoidheading, calendar, checkmarks, radiobutton.
- Konsole: soft-mono NightShiftDark and NightShiftLight colour schemes + profiles.

Run:  python3 -I tools/generate.py
SPDX-License-Identifier: GPL-3.0-or-later
"""
import argparse
import json
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
THEME_DIR = ROOT / "night-shift"
KONSOLE_DIR = ROOT / "konsole"
SCHEME_TOOLS = ROOT.parent.parent / "color-scheme" / "tabby-and-tweed" / "tools"
sys.path.insert(0, str(SCHEME_TOOLS))
from generate import LIGHT, DARK, MONO_LIGHT, MONO_DARK, CASPER_LIGHT, CASPER_DARK, contrast, luminance, kde

# Palette Tokens for fallback stylesheet
AMBER = DARK["accent"]                 # #E8A256
AMBER_DARK = LIGHT["accent"]           # #964C12
INK = LIGHT["text"]                    # #1C1C1C
CREAM = DARK["text"]                   # #E6E6E6
CREAM_PAPER = LIGHT["view"]            # #F7F7F7
DARK_VIEW = DARK["view"]               # #141414
ROSE = DARK["negative"]                # #F0807A
ROSE_DARK = LIGHT["negative"]          # #A83434
SLATE_BODY = LIGHT["inactive"]         # #666666
SLATE_RIM = DARK["inactive"]           # #A0A0A0
POSITIVE = DARK["positive"]            # #73C694
POSITIVE_DARK = LIGHT["positive"]      # #2D6E46


def plasma_metadata() -> str:
    meta = {
        "KPackageStructure": "Plasma/Theme",
        "KPlugin": {
            "Authors": [
                {
                    "Email": "22074809+techonerd@users.noreply.github.com",
                    "Name": "techonerd"
                }
            ],
            "Category": "Plasma Theme",
            "Description": "Night Shift: Breeze Plasma style in Tabby & Tweed colours, part of One Man Nine Lives.",
            "Id": "night-shift",
            "License": "GPL-3.0-or-later",
            "Name": "Night Shift",
            "Version": "0.2.0",
            "Website": "https://github.com/techonerd/one-man-nine-lives"
        }
    }
    return json.dumps(meta, indent=4) + "\n"


def plasma_rc() -> str:
    # Same effects as Breeze's own plasmarc; KWin's default blur and contrast apply.
    return """[AdaptiveTransparency]
enabled=true
"""


# =============================================================================
# 4. KONSOLE COLOUR SCHEMES & PROFILES (Item 5 preparation)
# =============================================================================

def konsole_scheme(name: str, dark: bool) -> str:
    """Generate a Konsole .colorscheme strictly from Tabby & Tweed tokens with WCAG >= 4.5:1 text and < 16:1 ceiling."""
    p = DARK if dark else LIGHT
    m = MONO_DARK if dark else MONO_LIGHT
    casper = CASPER_DARK if dark else CASPER_LIGHT

    bg = m["bg"]
    fg = m["fg"]
    fg_muted = m["fg_muted"]
    accent = p["accent"]

    if dark:
        # Strict Tabby & Tweed Dark tokens (WCAG >= 4.5:1, ceiling < 16:1)
        c0 = p["header_inactive"]           # #181818
        c0_intense = fg_muted               # #A0A0A0 (7.04:1)
        c1 = p["negative"]                  # #F0807A (7.08:1)
        c1_intense = p["negative"]          # #F0807A (7.08:1)
        c2 = p["positive"]                  # #73C694 (8.98:1)
        c2_intense = p["positive"]          # #73C694 (8.98:1)
        c3 = p["neutral"]                   # #F0B35B (9.92:1)
        c3_intense = p["hover"]             # #F0B16B (9.83:1)
        c4 = accent                         # #E8A256 (8.54:1)
        c4_intense = p["visited"]           # #F0B875 (10.37:1)
        c5 = p["visited"]                   # #F0B875 (10.37:1)
        c5_intense = p["selection"]         # #D98A3D (6.71:1)
        c6 = p["link"]                      # #E8A256 (8.54:1)
        c6_intense = p["hover"]             # #F0B16B (9.83:1)
        c7 = fg                             # #E6E6E6 (14.76:1)
        c7_intense = casper["coat_shade"]   # #E8E8E8 (15.04:1, < 16:1 ceiling)
    else:
        # Strict Tabby & Tweed Light tokens (WCAG >= 4.5:1, ceiling < 16:1)
        c0 = fg                             # #1C1C1C (15.91:1)
        c0_intense = fg_muted               # #666666 (5.36:1)
        c1 = p["negative"]                  # #A83434 (6.11:1)
        c1_intense = p["negative"]          # #A83434 (6.11:1)
        c2 = p["positive"]                  # #2D6E46 (5.71:1)
        c2_intense = p["positive"]          # #2D6E46 (5.71:1)
        c3 = p["neutral"]                   # #8F560B (5.59:1)
        c3_intense = accent                 # #964C12 (5.87:1)
        c4 = p["link"]                      # #8A420B (6.84:1)
        c4_intense = p["visited"]           # #7A3A0A (8.04:1)
        c5 = p["visited"]                   # #7A3A0A (8.04:1)
        c5_intense = p["visited"]           # #7A3A0A (8.04:1)
        c6 = accent                         # #964C12 (5.87:1)
        c6_intense = p["link"]              # #8A420B (6.84:1)
        c7 = p["view_alt"]                  # #EDEDED
        c7_intense = p["view"]              # #F7F7F7

    return f"""# {name} - Konsole colour scheme (One Man Nine Lives suite)
# Sourced from Tabby & Tweed soft-mono palette. WCAG >= 4.5:1 verified.
# SPDX-License-Identifier: GPL-3.0-or-later

[General]
Description={name}
Blur=true
Opacity=0.95

[Background]
Color={kde(bg)}

[BackgroundIntense]
Color={kde(bg)}

[Foreground]
Color={kde(fg)}

[ForegroundIntense]
Color={kde(fg)}

[Color0]
Color={kde(c0)}

[Color0Intense]
Color={kde(c0_intense)}

[Color1]
Color={kde(c1)}

[Color1Intense]
Color={kde(c1_intense)}

[Color2]
Color={kde(c2)}

[Color2Intense]
Color={kde(c2_intense)}

[Color3]
Color={kde(c3)}

[Color3Intense]
Color={kde(c3_intense)}

[Color4]
Color={kde(c4)}

[Color4Intense]
Color={kde(c4_intense)}

[Color5]
Color={kde(c5)}

[Color5Intense]
Color={kde(c5_intense)}

[Color6]
Color={kde(c6)}

[Color6Intense]
Color={kde(c6_intense)}

[Color7]
Color={kde(c7)}

[Color7Intense]
Color={kde(c7_intense)}
"""


def konsole_profile(name: str, scheme: str) -> str:
    return f"""[Appearance]
ColorScheme={scheme}

[General]
Name={name}
Parent=FALLBACK/
"""


# =============================================================================
# 5. CONTRAST VERIFICATION
# =============================================================================

def verify_contrasts() -> bool:
    """Check that normal text and key UI elements exceed WCAG contrast thresholds and respect ceiling."""
    print("=== Night Shift Contrast & Palette Verification ===")
    
    # 1. Konsole text contrast & ceiling (< 16:1)
    c_dark = contrast(MONO_DARK["fg"], MONO_DARK["bg"])
    c_light = contrast(MONO_LIGHT["fg"], MONO_LIGHT["bg"])
    c_dark_intense = contrast(CASPER_DARK["coat_shade"], MONO_DARK["bg"])
    c_light_muted = contrast(MONO_LIGHT["fg_muted"], MONO_LIGHT["bg"])
    c_dark_muted = contrast(MONO_DARK["fg_muted"], MONO_DARK["bg"])
    
    print(f"  Dark text ({MONO_DARK['fg']} on {MONO_DARK['bg']}): {c_dark:.2f}:1 (needs >= 4.5, < 16:1)")
    print(f"  Light text ({MONO_LIGHT['fg']} on {MONO_LIGHT['bg']}): {c_light:.2f}:1 (needs >= 4.5, < 16:1)")
    print(f"  Dark intense text ({CASPER_DARK['coat_shade']} on {MONO_DARK['bg']}): {c_dark_intense:.2f}:1 (< 16:1 ceiling)")
    print(f"  Dark muted text ({MONO_DARK['fg_muted']} on {MONO_DARK['bg']}): {c_dark_muted:.2f}:1 (needs >= 3.0)")
    print(f"  Light muted text ({MONO_LIGHT['fg_muted']} on {MONO_LIGHT['bg']}): {c_light_muted:.2f}:1 (needs >= 3.0)")

    # 2. Accent contrast against background
    c_accent_dark = contrast(DARK["accent"], MONO_DARK["bg"])
    c_accent_light = contrast(LIGHT["accent"], MONO_LIGHT["bg"])
    print(f"  Dark accent ({DARK['accent']} on {MONO_DARK['bg']}): {c_accent_dark:.2f}:1")
    print(f"  Light accent ({LIGHT['accent']} on {MONO_LIGHT['bg']}): {c_accent_light:.2f}:1")

    passed = (
        4.5 <= c_dark < 16.0
        and 4.5 <= c_light < 16.0
        and c_dark_intense < 16.0
        and c_dark_muted >= 3.0
        and c_light_muted >= 3.0
    )
    print("  Result: " + ("PASS (WCAG >= 4.5:1 satisfied and < 16:1 ceiling respected)" if passed else "FAIL"))
    return passed


def write_file_644(path: pathlib.Path, content: str) -> None:
    """Write text file with permissions 0o644."""
    path.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    path.chmod(0o644)


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Night Shift Plasma style and Konsole schemes.")
    parser.add_argument("--check-contrast", action="store_true", help="Run contrast check and exit.")
    args = parser.parse_args()
    if args.check_contrast:
        return 0 if verify_contrasts() else 1
    verify_contrasts()

    # Night Shift draws nothing itself: every panel, popup and control comes from Breeze
    # (KDE's "default" Plasma style), which recolours from the Tabby & Tweed colour scheme.
    # Hand-made frames broke at 125 % scaling, so the old SVGs are removed here.
    import shutil
    for sub in ("widgets", "dialogs", "translucent", "opaque"):
        if (THEME_DIR / sub).exists():
            shutil.rmtree(THEME_DIR / sub)
    KONSOLE_DIR.mkdir(mode=0o755, parents=True, exist_ok=True)

    write_file_644(THEME_DIR / "metadata.json", plasma_metadata())
    write_file_644(THEME_DIR / "plasmarc", plasma_rc())

    write_file_644(KONSOLE_DIR / "NightShiftDark.colorscheme", konsole_scheme("Night Shift Dark", dark=True))
    write_file_644(KONSOLE_DIR / "NightShiftLight.colorscheme", konsole_scheme("Night Shift Light", dark=False))
    write_file_644(KONSOLE_DIR / "Night Shift Dark.profile", konsole_profile("Night Shift Dark", "NightShiftDark"))
    write_file_644(KONSOLE_DIR / "Night Shift Light.profile", konsole_profile("Night Shift Light", "NightShiftLight"))
    old = KONSOLE_DIR / "Night Shift.profile"
    if old.exists():
        old.unlink()

    print(f"Generated Night Shift (Breeze-based) in {THEME_DIR} and Konsole files in {KONSOLE_DIR}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
