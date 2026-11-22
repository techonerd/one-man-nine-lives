#!/usr/bin/env python3
"""Generate the Thumbs & Paws icons (One Man Nine Lives suite).

Every icon is drawn here from simple shapes, so the whole set stays consistent and is 100 % original.
Every colour is imported from Tabby & Tweed; no hex literals are defined here.
Run:  python3 -I tools/generate.py
SPDX-License-Identifier: GPL-3.0-or-later
"""
import argparse
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEME_TOOLS = ROOT.parent.parent / "color-scheme" / "tabby-and-tweed" / "tools"
sys.path.insert(0, str(SCHEME_TOOLS))
from generate import LIGHT, DARK, contrast, luminance

# Tabby & Tweed Named Palette Tokens
# Amber folder tones
AMBER = DARK["accent"]                 # warm tabby amber
AMBER_BACK = LIGHT["accent"]           # shaded amber for back flap & accents
AMBER_HIGHLIGHT = LIGHT["button_alt"]  # amber highlight / rim
AMBER_WARM = DARK["neutral"]           # bright warm amber / sun

# Inks and text
INK = LIGHT["text"]                    # dark brown text / emblem
INK_DARK = DARK["selection_text"]      # deepest ink

# Creams and whites
CREAM = DARK["text"]                   # warm cream
CREAM_PAPER = LIGHT["view"]            # paper view cream
WHITE = LIGHT["selection_text"]        # crisp white highlight

# Rose / ear & toe bean accents
ROSE = DARK["negative"]                # warm rose
ROSE_DARK = LIGHT["negative"]          # deep rose

# Link / eye accents (replaces un-paletted teal)
LINK_ACCENT = DARK["link"]             # bright link teal for eyes / highlights
LINK_DEEP = LIGHT["link"]              # deep link teal

# Positive / green for LEDs
POSITIVE = DARK["positive"]            # LED indicator green

# Slate / Tweed elements & rims
# Slate elements need >= 3:1 contrast on both light (#eff0f1) and dark (#202326)
SLATE_BODY = LIGHT["inactive"]         # slate body (contrast on light: 5.30 >= 3.0)
SLATE_RIM = DARK["inactive"]           # lighter slate rim (contrast on dark: 5.68 >= 3.0)
SLATE_DARK = DARK["button"]            # dark slate interior / shadow

# Breeze reference backgrounds for contrast verification
BREEZE_LIGHT = "#eff0f1"
BREEZE_DARK = "#202326"


def check_contrast() -> bool:
    """Verify that slate elements and key tokens meet >= 3:1 contrast requirements."""
    bgs = [(BREEZE_LIGHT, "Light Panel"), (BREEZE_DARK, "Dark Panel")]
    print("=== Thumbs & Paws Contrast Verification ===")
    
    # Check slate body on light and slate rim on dark
    c_slate_light = contrast(SLATE_BODY, BREEZE_LIGHT)
    c_slate_dark = contrast(SLATE_RIM, BREEZE_DARK)
    c_amber_light = contrast(AMBER_BACK, BREEZE_LIGHT)
    c_amber_dark = contrast(AMBER, BREEZE_DARK)
    
    print(f"  Slate body ({SLATE_BODY}) on Light ({BREEZE_LIGHT}): {c_slate_light:.2f}:1 (needs >= 3.0)")
    print(f"  Slate rim  ({SLATE_RIM})  on Dark  ({BREEZE_DARK}): {c_slate_dark:.2f}:1 (needs >= 3.0)")
    print(f"  Amber back ({AMBER_BACK}) on Light ({BREEZE_LIGHT}): {c_amber_light:.2f}:1 (needs >= 3.0)")
    print(f"  Amber front({AMBER})      on Dark  ({BREEZE_DARK}): {c_amber_dark:.2f}:1 (needs >= 3.0)")

    passed = (c_slate_light >= 3.0 and c_slate_dark >= 3.0 and 
              c_amber_light >= 3.0 and c_amber_dark >= 3.0)
    print("  Result: " + ("PASS (all contrast thresholds met)" if passed else "FAIL"))
    return passed


def svg(body: str, size: int = 64) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
            f'viewBox="0 0 {size} {size}">\n{body}\n</svg>\n')


def symbolic_svg(path_d: str) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">\n'
            f'  <defs>\n'
            f'    <style type="text/css" id="current-color-scheme">\n'
            f'      .ColorScheme-Text {{ color: {INK}; }}\n'
            f'    </style>\n'
            f'  </defs>\n'
            f'  <path class="ColorScheme-Text" style="fill:currentColor" d="{path_d}"/>\n'
            f'</svg>\n')


# =============================================================================
# REUSABLE CAT PARTS LIBRARY
# =============================================================================

def part_paw_64(cx: float, cy: float, angle: float = 0, scale: float = 1.0, 
                color: str = CREAM, bean_color: str = ROSE) -> str:
    """Reusable cat paw: palm pad + 4 radial toe beans."""
    trans = f'transform="translate({cx},{cy}) rotate({angle}) scale({scale})"'
    pad = f'<path d="M-4 2 C-4 -2 -1 -3 0 -3 C1 -3 4 -2 4 2 C3 5 -3 5 -4 2 Z" fill="{color}"/>'
    inner_pad = f'<ellipse cx="0" cy="1.5" rx="2.4" ry="1.7" fill="{bean_color}"/>'
    beans = (
        f'<ellipse cx="-4.5" cy="-2.5" rx="1.2" ry="1.6" transform="rotate(-30 -4.5 -2.5)" fill="{bean_color}"/>'
        f'<ellipse cx="-1.8" cy="-5" rx="1.2" ry="1.6" transform="rotate(-10 -1.8 -5)" fill="{bean_color}"/>'
        f'<ellipse cx="1.8" cy="-5" rx="1.2" ry="1.6" transform="rotate(10 1.8 -5)" fill="{bean_color}"/>'
        f'<ellipse cx="4.5" cy="-2.5" rx="1.2" ry="1.6" transform="rotate(30 4.5 -2.5)" fill="{bean_color}"/>'
    )
    return f'<g {trans}>{pad}{inner_pad}{beans}</g>'


def part_print_mark(cx: float, cy: float, scale: float = 1.0, color: str = INK) -> str:
    """The suite mark: one central bean pad + 4 radial toe dots."""
    trans = f'transform="translate({cx},{cy}) scale({scale})"'
    pad = f'<ellipse cx="0" cy="2" rx="4" ry="3.2" fill="{color}"/>'
    beans = (
        f'<circle cx="-4.5" cy="-2.5" r="1.6" fill="{color}"/>'
        f'<circle cx="-1.7" cy="-5" r="1.6" fill="{color}"/>'
        f'<circle cx="1.7" cy="-5" r="1.6" fill="{color}"/>'
        f'<circle cx="4.5" cy="-2.5" r="1.6" fill="{color}"/>'
    )
    return f'<g {trans}>{pad}{beans}</g>'


def part_loaf_silhouette(cx: float, cy: float, scale: float = 1.0, 
                         color: str = SLATE_BODY, rim: str = SLATE_RIM) -> str:
    """Reusable sleeping cat loaf silhouette."""
    trans = f'transform="translate({cx},{cy}) scale({scale})"'
    body = (
        f'<path d="M-10 4 C-10 -4 4 -6 10 -2 C12 0 13 4 10 6 C6 8 -6 8 -10 4 Z" '
        f'fill="{color}" stroke="{rim}" stroke-width="1.2"/>'
        f'<path d="M7 -2 L6 -6 L9 -3 Z M11 -1 L11 -5 L13 -2 Z" fill="{ROSE}"/>'
    )
    return f'<g {trans}>{body}</g>'


# =============================================================================
# SCALABLE (64px) ICONS
# =============================================================================

def folder_base_64(emblem: str = "", extra_quirk: str = "") -> str:
    """Base tabbed folder at 64px with family signature ear-notched tab."""
    # Back panel with ear-notched tab
    back = (
        f'<path d="M6 14 Q6 10 10 10 L13 10 L16 5 L19 10 L22 10 L25 5 L28 10 L30 10 '
        f'Q33 10 35 13 L37 15 L54 15 Q58 15 58 19 L58 48 L6 48 Z" fill="{AMBER_BACK}"/>'
    )
    inner_ears = (
        f'<path d="M14.2 9.4 L16 6.6 L17.8 9.4 Z M23.2 9.4 L25 6.6 L26.8 9.4 Z" '
        f'fill="{ROSE}" opacity="0.85"/>'
    )
    # Front pocket panel
    front = (
        f'<rect x="4" y="20" width="56" height="36" rx="5" fill="{AMBER}"/>'
        f'<rect x="4" y="20" width="56" height="3" rx="1.5" fill="{AMBER_HIGHLIGHT}" opacity="0.9"/>'
    )
    return back + inner_ears + extra_quirk + front + (f'<g>{emblem}</g>' if emblem else "")


def icon_folder_64() -> str:
    """Standard folder: cat loaf lying across the folder top, paws draped over front."""
    # Loaf peeking over the top edge on the right side
    loaf = (
        # Cat body resting behind front flap
        f'<path d="M36 20 C36 12 44 11 48 13 C52 15 54 18 54 20 Z" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        # Head and ears
        f'<circle cx="43" cy="15" r="4.5" fill="{CREAM}"/>'
        f'<path d="M39.5 13 L40.5 9 L42.5 12 Z M43.5 12 L45.5 9 L46.5 13 Z" fill="{ROSE}"/>'
        # Sleeping eye arcs
        f'<path d="M41 15.5 Q42 16.5 43 15.5 M43.5 15.5 Q44.5 16.5 45.5 15.5" stroke="{INK}" stroke-width="0.8" fill="none"/>'
        # Front paws draped over the front flap lip
        f'<rect x="40" y="19" width="3.2" height="4.5" rx="1.6" fill="{CREAM}"/>'
        f'<circle cx="41.6" cy="22" r="0.8" fill="{ROSE}"/>'
        f'<rect x="45" y="19" width="3.2" height="4.5" rx="1.6" fill="{CREAM}"/>'
        f'<circle cx="46.6" cy="22" r="0.8" fill="{ROSE}"/>'
    )
    return svg(folder_base_64("", extra_quirk=loaf), 64)


def icon_folder_home_64() -> str:
    """Home folder: cat face in the house window."""
    emblem = (
        # House body
        f'<path d="M32 26 L43 35 L40 35 V47 H36 V41 H28 V47 H24 V35 L21 35 Z" fill="{INK}"/>'
        # Window cutout
        f'<rect x="29.5" y="31.5" width="5" height="5" rx="1" fill="{CREAM_PAPER}"/>'
        # Cat face inside window: ears + curious eyes
        f'<path d="M30 33.5 L30.8 32 L31.5 33.5 Z M32.5 33.5 L33.2 32 L34 33.5 Z" fill="{ROSE}"/>'
        f'<circle cx="31" cy="34" r="0.6" fill="{LINK_ACCENT}"/>'
        f'<circle cx="33" cy="34" r="0.6" fill="{LINK_ACCENT}"/>'
    )
    return svg(folder_base_64(emblem), 64)


def icon_folder_documents_64() -> str:
    """Documents folder: cat asleep on the page, tail over text lines."""
    emblem = (
        # Document sheet with folded corner
        f'<path d="M23 26 H36 L42 32 V48 H23 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="1.5" stroke-linejoin="round"/>'
        f'<path d="M36 26 V32 H42 Z" fill="{CREAM}" stroke="{INK}" stroke-width="1.2" stroke-linejoin="round"/>'
        # Text lines
        f'<path d="M26 34 H34 M26 38 H38 M26 42 H31" stroke="{INK}" stroke-width="1.8" stroke-linecap="round"/>'
        # Cat curled on bottom right of page
        f'<ellipse cx="36" cy="43.5" rx="3.5" ry="2.5" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<path d="M33 42.5 L33.5 41 L34.5 42 Z M35 42 L36 41 L36.5 42.5 Z" fill="{ROSE}"/>'
        # Tail curving over the bottom line
        f'<path d="M39 44 Q41 41 37 40" stroke="{SLATE_BODY}" stroke-width="1.2" stroke-linecap="round" fill="none"/>'
    )
    return svg(folder_base_64(emblem), 64)


def icon_folder_downloads_64() -> str:
    """Downloads folder: strictly vertical arrow, paw touches side mid-swat."""
    arrow = (
        # Downward vertical arrow
        f'<path d="M29 27 H35 V37 H40 L32 45 L24 37 H29 Z" fill="{INK}"/>'
        # Bottom tray
        f'<rect x="22" y="46" width="20" height="3" rx="1.5" fill="{INK}"/>'
    )
    # Paw touching arrow side from right
    paw = part_paw_64(39.5, 34, angle=-75, scale=0.85, color=CREAM, bean_color=ROSE)
    return svg(folder_base_64(arrow + paw), 64)


def icon_folder_pictures_64() -> str:
    """Pictures folder: paw print sits cleanly BESIDE the landscape, not over it."""
    landscape = (
        # Framed photo on left
        f'<rect x="19" y="27" width="16" height="19" rx="2" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="1.2"/>'
        # Sun
        f'<circle cx="23.5" cy="32" r="2.2" fill="{AMBER_WARM}"/>'
        # Mountains
        f'<path d="M20 44 L24.5 36 L28 41 L30.5 38 L34 44 Z" fill="{LINK_DEEP}"/>'
    )
    # Paw print stamped neatly beside the landscape on the right
    paw_print = part_print_mark(41.5, 36.5, scale=0.85, color=INK)
    return svg(folder_base_64(landscape + paw_print), 64)


def icon_folder_music_64() -> str:
    """Music folder: cat ear sticking up between two notes."""
    emblem = (
        # Beamed notes
        f'<ellipse cx="27" cy="43" rx="3.5" ry="2.5" transform="rotate(-20 27 43)" fill="{INK}"/>'
        f'<ellipse cx="38" cy="40" rx="3.5" ry="2.5" transform="rotate(-20 38 40)" fill="{INK}"/>'
        f'<path d="M29.5 42 V28 M40.5 39 V25" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>'
        f'<path d="M29.5 28 L40.5 25 V28 L29.5 31 Z" fill="{INK}"/>'
        # Cat ears peeking up between the two vertical stems
        f'<path d="M33 26.5 L34.5 22.5 L36 26 Z M36.5 26 L38 22 L39.5 25.5 Z" fill="{SLATE_BODY}"/>'
        f'<path d="M33.8 25.5 L34.5 23.5 L35.2 25.5 Z M37.2 25 L38 23.2 L38.7 25 Z" fill="{ROSE}"/>'
    )
    return svg(folder_base_64(emblem), 64)


def icon_folder_videos_64() -> str:
    """Videos folder: cat silhouette sitting in front of the play screen."""
    emblem = (
        # Video screen
        f'<rect x="20" y="27" width="24" height="17" rx="3" fill="{INK}"/>'
        # Play triangle
        f'<path d="M29 31.5 L37 35.5 L29 39.5 Z" fill="{AMBER}"/>'
        # Cat silhouette seated in bottom right corner
        f'<path d="M38 44 Q38 40.5 39.5 39.5 L39.5 37.5 L41 39 L42.5 37.5 L42.5 39.5 Q44 40.5 44 44 Z" '
        f'fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
    )
    return svg(folder_base_64(emblem), 64)


def icon_folder_desktop_64() -> str:
    """Desktop folder: cat loaf on top of monitor, tail hanging over screen."""
    emblem = (
        # Monitor display
        f'<rect x="21" y="28" width="22" height="14" rx="2" fill="{INK}"/>'
        f'<rect x="23" y="30" width="18" height="10" rx="1" fill="{CREAM_PAPER}"/>'
        f'<rect x="30" y="42" width="4" height="3" fill="{INK}"/>'
        f'<rect x="25" y="45" width="14" height="2" rx="1" fill="{INK}"/>'
        # Cat loaf on top bezel
        f'<ellipse cx="32" cy="27" rx="5" ry="2" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.6"/>'
        f'<path d="M28.5 26.5 L29.5 24 L30.5 26.5 Z M33.5 26.5 L34.5 24 L35.5 26.5 Z" fill="{ROSE}"/>'
        # Tail hanging down in front of screen
        f'<path d="M37 27 Q39 30 38 34" stroke="{SLATE_BODY}" stroke-width="1.4" stroke-linecap="round" fill="none"/>'
    )
    return svg(folder_base_64(emblem), 64)


def icon_folder_favorites_64() -> str:
    """Favorites folder: paw print (the suite mark)."""
    mark = (
        f'<ellipse cx="32" cy="41" rx="6.5" ry="5.5" fill="{ROSE}" stroke="{INK}" stroke-width="1.2"/>'
        f'<circle cx="24.5" cy="33.5" r="2.8" fill="{ROSE}" stroke="{INK}" stroke-width="1.2"/>'
        f'<circle cx="29.5" cy="29.5" r="2.8" fill="{ROSE}" stroke="{INK}" stroke-width="1.2"/>'
        f'<circle cx="34.5" cy="29.5" r="2.8" fill="{ROSE}" stroke="{INK}" stroke-width="1.2"/>'
        f'<circle cx="39.5" cy="33.5" r="2.8" fill="{ROSE}" stroke="{INK}" stroke-width="1.2"/>'
    )
    return svg(folder_base_64(mark), 64)


def icon_folder_git_64() -> str:
    """Git folder: paw tangled in branch lines."""
    tree = (
        # Branch tracks
        f'<path d="M28 44 V30 M28 40 C28 35 38 37 38 33 V28" stroke="{INK}" stroke-width="2.2" stroke-linecap="round" fill="none"/>'
        # Commit nodes
        f'<circle cx="28" cy="44" r="2.8" fill="{LINK_DEEP}"/>'
        f'<circle cx="28" cy="30" r="2.8" fill="{LINK_DEEP}"/>'
        f'<circle cx="38" cy="28" r="2.8" fill="{LINK_DEEP}"/>'
    )
    # Paw tangled in branch
    paw = part_paw_64(34, 37, angle=45, scale=0.75, color=CREAM, bean_color=ROSE)
    return svg(folder_base_64(tree + paw), 64)


def icon_folder_development_64() -> str:
    """Development folder: paw resting on code brackets."""
    brackets = (
        # < / > glyphs
        f'<path d="M26 31 L21 36 L26 41" stroke="{INK}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
        f'<path d="M30 43 L34 29" stroke="{LINK_DEEP}" stroke-width="2.4" stroke-linecap="round" fill="none"/>'
        f'<path d="M38 31 L43 36 L38 41" stroke="{INK}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
    )
    # Paw resting on the > bracket
    paw = part_paw_64(41.5, 30, angle=-30, scale=0.75, color=CREAM, bean_color=ROSE)
    return svg(folder_base_64(brackets + paw), 64)


def icon_quiet_folder_64(emblem: str) -> str:
    """Quiet folder variant: ears on tab, clean unhindered emblem."""
    return svg(folder_base_64(f'<g fill="{INK}">{emblem}</g>'), 64)


QUIET_EMBLEMS_64 = {
    # Network nodes
    "folder-network": (
        f'<path d="M32 30 L25 42 M32 30 L39 42 M25 42 H39" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
        f'<circle cx="32" cy="29" r="3" fill="{LINK_DEEP}"/>'
        f'<circle cx="24" cy="43" r="3" fill="{LINK_DEEP}"/>'
        f'<circle cx="40" cy="43" r="3" fill="{LINK_DEEP}"/>'
    ),
    # Cloud silhouette
    "folder-cloud": (
        f'<path d="M24 43 H39 A5 5 0 0 0 39 34 A7 7 0 0 0 26 34 A5 5 0 0 0 24 43 Z" '
        f'fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>'
    ),
    # Templates drafting ruler & sheet
    "folder-templates": (
        f'<path d="M23 27 H37 L41 31 V47 H23 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="1.5"/>'
        f'<path d="M27 34 L37 44 M27 38 L33 44 M27 42 L29 44" stroke="{INK}" stroke-width="1.5"/>'
    ),
    # Shared / public
    "folder-public": (
        f'<circle cx="32" cy="33" r="4" fill="{INK}"/>'
        f'<path d="M23 46 C23 40 27 39 32 39 C37 39 41 40 41 46 Z" fill="{INK}"/>'
        f'<path d="M20 37 Q22 35 24 37 M44 37 Q42 35 40 37" stroke="{LINK_DEEP}" stroke-width="1.8" stroke-linecap="round" fill="none"/>'
    ),
    # Padlock
    "folder-locked": (
        f'<rect x="25" y="34" width="14" height="12" rx="2" fill="{INK}"/>'
        f'<path d="M28 34 V29 A4 4 0 0 1 36 29 V34" stroke="{INK}" stroke-width="2.5" fill="none"/>'
        f'<circle cx="32" cy="39" r="1.5" fill="{AMBER}"/>'
    ),
    # Hourglass / temp
    "folder-temp": (
        f'<path d="M25 28 H39 M25 46 H39 M27 28 L32 37 L37 28 M27 46 L32 37 L37 46" '
        f'stroke="{INK}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
        f'<polygon points="30,43 34,43 32,39" fill="{AMBER}"/>'
    ),
}


# =============================================================================
# TRASH SYSTEM
# =============================================================================

def icon_trash_64(full: bool) -> str:
    """Trash can with family signature ear-notched lid and >= 3:1 slate contrast."""
    can_body = (
        # Can body: SLATE_BODY with SLATE_RIM outline for >= 3:1 contrast on both light and dark
        f'<path d="M17 23 H47 L44 55 Q43.6 58 40.6 58 H23.4 Q20.4 58 20 55 Z" '
        f'fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        # Fluted rib lines
        f'<path d="M26 28 L27 52 M32 28 V52 M38 28 L37 52" '
        f'stroke="{SLATE_RIM}" stroke-width="1.5" stroke-linecap="round" opacity="0.65"/>'
    )
    # Ear-notched lid
    lid = (
        f'<path d="M14 18 L17 12 L20 16 L44 16 L47 12 L50 18 Q51 21 48 21 L16 21 Q13 21 14 18 Z" '
        f'fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        f'<path d="M16.4 16.6 L17.2 14.2 L18.6 16.2 Z M45.4 16.2 L46.8 14.2 L47.6 16.6 Z" fill="{ROSE}"/>'
    )
    if not full:
        # Quirk: cat inside empty bin looking out
        cat_in_bin = (
            # Face peeking above rim
            f'<circle cx="32" cy="18" r="4.5" fill="{CREAM}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
            f'<path d="M28.5 16 L29.5 12 L31.5 15 Z M32.5 15 L34.5 12 L35.5 16 Z" fill="{ROSE}"/>'
            # Eyes
            f'<circle cx="30.5" cy="18" r="0.9" fill="{LINK_ACCENT}"/>'
            f'<circle cx="33.5" cy="18" r="0.9" fill="{LINK_ACCENT}"/>'
            f'<circle cx="30.5" cy="18" r="0.4" fill="{INK}"/>'
            f'<circle cx="33.5" cy="18" r="0.4" fill="{INK}"/>'
            # Paws on the front rim
            f'<rect x="29" y="21.5" width="2.8" height="3.5" rx="1.4" fill="{CREAM}"/>'
            f'<rect x="33" y="21.5" width="2.8" height="3.5" rx="1.4" fill="{CREAM}"/>'
        )
        return svg(can_body + cat_in_bin + lid, 64)
    else:
        # Full trash: crumpled paper mound overflowing
        paper = (
            f'<path d="M20 23 Q24 13 29 17 Q32 11 36 15 Q40 10 44 23 Z" '
            f'fill="{CREAM}" stroke="{SLATE_RIM}" stroke-width="1.2"/>'
        )
        # Quirk: knocked paper ball on floor + swishing tail behind corner
        floor_ball = (
            f'<circle cx="51" cy="54" r="3.5" fill="{CREAM}" stroke="{SLATE_RIM}" stroke-width="1"/>'
            f'<path d="M18 48 Q10 44 12 37" stroke="{SLATE_BODY}" stroke-width="2.5" stroke-linecap="round" fill="none"/>'
            f'<circle cx="12" cy="37" r="1.5" fill="{CREAM}"/>'
        )
        # Propped lid behind paper
        tilted_lid = f'<g transform="rotate(-12 16 18)">{lid}</g>'
        return svg(floor_ball + can_body + paper + tilted_lid, 64)


# =============================================================================
# APPLICATIONS, SYSTEM & ACTIONS
# =============================================================================

def icon_terminal_64() -> str:
    """Terminal: prompt shows fffffff with paw on keyboard."""
    window = (
        # Outer terminal window with lighter rim
        f'<rect x="6" y="10" width="52" height="44" rx="4" fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        # Titlebar
        f'<rect x="6" y="10" width="52" height="8" rx="4" fill="{SLATE_BODY}"/>'
        f'<circle cx="11" cy="14" r="1.5" fill="{ROSE}"/>'
        f'<circle cx="16" cy="14" r="1.5" fill="{AMBER_WARM}"/>'
        f'<circle cx="21" cy="14" r="1.5" fill="{POSITIVE}"/>'
        # Terminal prompt text: > fffffff
        f'<text x="11" y="28" font-family="monospace" font-size="9" font-weight="bold" fill="{LINK_ACCENT}">&gt;</text>'
        f'<text x="19" y="28" font-family="monospace" font-size="8" font-weight="bold" fill="{AMBER}">fffffff</text>'
        f'<rect x="52" y="21" width="3" height="8" fill="{AMBER}" opacity="0.85"/>'
    )
    # Paw on keyboard / bottom bezel
    paw = part_paw_64(34, 52, angle=0, scale=0.85, color=CREAM, bean_color=ROSE)
    return svg(window + paw, 64)


def icon_file_manager_64() -> str:
    """File manager: cat curled in open top drawer."""
    cabinet = (
        # Cabinet outer casing
        f'<rect x="12" y="11" width="40" height="44" rx="3" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        # Bottom drawer (closed)
        f'<rect x="14" y="34" width="36" height="18" rx="2" fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        f'<rect x="28" y="42" width="8" height="2.5" rx="1" fill="{CREAM}"/>'
        # Top drawer pulled open
        f'<rect x="10" y="16" width="44" height="15" rx="2" fill="{AMBER_BACK}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        f'<rect x="27" y="22" width="10" height="3" rx="1" fill="{CREAM}"/>'
        # Cat sleeping in the top opening
        f'<ellipse cx="32" cy="15" rx="7" ry="3" fill="{CREAM}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<path d="M28 14 L29 11 L30.5 13.5 Z M33.5 13.5 L35 11 L36 14 Z" fill="{ROSE}"/>'
        # Tail curving down over the drawer
        f'<path d="M38 18 Q43 23 39 27" stroke="{SLATE_BODY}" stroke-width="2" stroke-linecap="round" fill="none"/>'
        f'<circle cx="39" cy="27" r="1.2" fill="{CREAM}"/>'
    )
    return svg(cabinet, 64)


def icon_preferences_64() -> str:
    """System settings: gear with paw batting a tooth."""
    gear = (
        # 8-tooth gear
        f'<path d="M28 8 H36 L37 13 L42 15 L46 12 L52 18 L49 22 L51 27 L56 28 V36 L51 37 L49 42 L52 46 '
        f'L46 52 L42 49 L37 51 L36 56 H28 L27 51 L22 49 L18 52 L12 46 L15 42 L13 37 L8 36 V28 L13 27 '
        f'L15 22 L12 18 L18 12 L22 15 L27 13 Z" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1.5" stroke-linejoin="round"/>'
        f'<circle cx="32" cy="32" r="9" fill="{AMBER}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        f'<circle cx="32" cy="32" r="4.5" fill="{SLATE_DARK}"/>'
    )
    # Paw batting upper left tooth
    paw = part_paw_64(18, 16, angle=135, scale=0.9, color=CREAM, bean_color=ROSE)
    return svg(gear + paw, 64)


def icon_search_64() -> str:
    """Search: magnifying glass with cat eye looking through."""
    glass = (
        # Handle at 45 degrees
        f'<rect x="38" y="38" width="7" height="19" rx="3.5" transform="rotate(-45 38 38)" '
        f'fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        # Lens rim
        f'<circle cx="27" cy="27" r="16" fill="{CREAM_PAPER}" stroke="{SLATE_BODY}" stroke-width="3"/>'
        f'<circle cx="27" cy="27" r="17.5" fill="none" stroke="{SLATE_RIM}" stroke-width="1"/>'
        # Big cat eye looking through lens
        f'<path d="M18 27 Q27 18 36 27 Q27 36 18 27 Z" fill="{AMBER}" stroke="{INK}" stroke-width="1.2"/>'
        f'<ellipse cx="27" cy="27" rx="1.8" ry="6" fill="{INK}"/>'
        f'<circle cx="25.5" cy="24.5" r="1.3" fill="{WHITE}"/>'
    )
    return svg(glass, 64)


def icon_drive_64(removable: bool = False) -> str:
    """Drive: external enclosure with cat asleep on the warm spot."""
    casing = (
        # Drive enclosure
        f'<rect x="10" y="24" width="44" height="26" rx="4" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1.5"/>'
        f'<rect x="14" y="32" width="26" height="3" rx="1" fill="{SLATE_DARK}"/>'
        # Activity LED
        f'<circle cx="46" cy="33.5" r="2" fill="{POSITIVE}"/>'
    )
    if removable:
        # USB / media icon on front
        casing += (
            f'<path d="M20 42 H34 M27 38 V45" stroke="{SLATE_RIM}" stroke-width="1.5" stroke-linecap="round"/>'
            f'<circle cx="27" cy="38" r="1.2" fill="{SLATE_RIM}"/>'
        )
    # Cat asleep on top
    cat_on_top = (
        f'<path d="M16 24 C16 16 26 14 34 16 C39 17 44 19 44 24 Z" fill="{AMBER}" stroke="{AMBER_BACK}" stroke-width="1"/>'
        f'<path d="M35 15 L36.5 12 L38 14.5 Z M39 15 L40.5 12.5 L42 15 Z" fill="{ROSE}"/>'
        f'<path d="M44 24 Q48 26 47 30" stroke="{AMBER_BACK}" stroke-width="2" stroke-linecap="round" fill="none"/>'
    )
    return svg(casing + cat_on_top, 64)


# =============================================================================
# 22px ICONS (Panel Size: Ear-notched tab preserved, reduced quirks)
# =============================================================================

def folder_base_22(emblem: str = "") -> str:
    """Folder at 22px with ear-notched tab preserved."""
    back = (
        f'<path d="M2 5.5 Q2 4 3.5 4 L4.5 4 L5.5 2 L6.5 4 L7.5 4 L8.5 2 L9.5 4 L10 4 '
        f'Q11 4 11.5 5 L12 5.5 L18.5 5.5 Q20 5.5 20 7 L20 17 L2 17 Z" fill="{AMBER_BACK}"/>'
        f'<path d="M5 3.8 L5.5 2.8 L6 3.8 Z M8 3.8 L8.5 2.8 L9 3.8 Z" fill="{ROSE}"/>'
    )
    front = (
        f'<rect x="1.5" y="7" width="19" height="12.5" rx="2" fill="{AMBER}"/>'
        f'<rect x="1.5" y="7" width="19" height="1.2" rx="0.6" fill="{AMBER_HIGHLIGHT}" opacity="0.9"/>'
    )
    return back + front + (f'<g fill="{INK}">{emblem}</g>' if emblem else "")


def icon_trash_22(full: bool) -> str:
    """Trash at 22px with ear-notched lid."""
    lid = (
        f'<path d="M4.5 6.5 L6 4 L7.5 5.5 L14.5 5.5 L16 4 L17.5 6.5 Q18 7.5 17 7.5 L5 7.5 Q4 7.5 4.5 6.5 Z" '
        f'fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<path d="M5.8 5.8 L6 5 L6.2 5.8 Z M15.8 5.8 L16 5 L16.2 5.8 Z" fill="{ROSE}"/>'
    )
    can = (
        f'<path d="M5.5 8 H16.5 L15.5 19 Q15.3 20 14 20 H8 Q6.7 20 6.5 19 Z" '
        f'fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<path d="M11 9 V18" stroke="{SLATE_RIM}" stroke-width="0.8" opacity="0.6"/>'
    )
    if not full:
        return svg(can + lid, 22)
    else:
        paper = f'<path d="M6.5 8 Q9 5 11 6 Q13 4 15.5 8 Z" fill="{CREAM}" stroke="{SLATE_RIM}" stroke-width="0.6"/>'
        return svg(can + paper + lid, 22)


EMBLEMS_22 = {
    "folder": "",
    "folder-home": '<path d="M11 9 L15 12.5 H14 V17 H12.5 V14.5 H9.5 V17 H8 V12.5 H7 Z"/>',
    "folder-documents": f'<path d="M8 9 H13 L15 11 V17 H8 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.8"/><path d="M10 12 H13 M10 14 H13" stroke="{INK}" stroke-width="0.8"/>',
    "folder-downloads": '<path d="M10 9 H12 V13 H14 L11 16 L8 13 H10 Z"/><rect x="7.5" y="17" width="7" height="1.2" rx="0.6"/>',
    "folder-pictures": f'<rect x="6.5" y="9.5" width="9" height="7" rx="1" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.6"/><circle cx="8.5" cy="11.5" r="1" fill="{AMBER_WARM}"/><path d="M7 16 L9.5 13 L11.5 15 L12.5 14 L15 16 Z" fill="{LINK_DEEP}"/>',
    "folder-music": f'<ellipse cx="9" cy="15" rx="1.5" ry="1.2" transform="rotate(-20 9 15)"/><ellipse cx="14" cy="14" rx="1.5" ry="1.2" transform="rotate(-20 14 14)"/><path d="M10.2 14.5 V10 L15.2 9 V13.5" stroke="{INK}" stroke-width="1.2"/>',
    "folder-videos": f'<rect x="7" y="10" width="8" height="6" rx="1"/><polygon points="10,11.5 13,13 10,14.5" fill="{AMBER}"/>',
    "folder-desktop": f'<rect x="7" y="10" width="8" height="5.5" rx="1"/><rect x="8" y="11" width="6" height="3.5" fill="{CREAM_PAPER}"/><rect x="10" y="15.5" width="2" height="1"/><rect x="8.5" y="16.5" width="5" height="0.8" rx="0.4"/>',
    "folder-favorites": f'<ellipse cx="11" cy="14.5" rx="2.5" ry="2" fill="{ROSE}" stroke="{INK}" stroke-width="0.6"/><circle cx="8" cy="11.5" r="1.1" fill="{ROSE}"/><circle cx="10" cy="10" r="1.1" fill="{ROSE}"/><circle cx="12" cy="10" r="1.1" fill="{ROSE}"/><circle cx="14" cy="11.5" r="1.1" fill="{ROSE}"/>',
    "folder-git": f'<path d="M9.5 16 V11 M9.5 14 C9.5 12 13 13 13 11" stroke="{INK}" stroke-width="1.2" fill="none"/><circle cx="9.5" cy="16" r="1.2" fill="{LINK_DEEP}"/><circle cx="9.5" cy="11" r="1.2" fill="{LINK_DEEP}"/><circle cx="13" cy="11" r="1.2" fill="{LINK_DEEP}"/>',
    "folder-development": f'<path d="M9 11 L7 13 L9 15 M11 16 L12 10 M13 11 L15 13 L13 15" stroke="{INK}" stroke-width="1.2" stroke-linecap="round" fill="none"/>',
    "folder-network": f'<circle cx="11" cy="10.5" r="1.3" fill="{LINK_DEEP}"/><circle cx="8" cy="15.5" r="1.3" fill="{LINK_DEEP}"/><circle cx="14" cy="15.5" r="1.3" fill="{LINK_DEEP}"/><path d="M11 11.5 L8.5 14.5 M11 11.5 L13.5 14.5" stroke="{INK}" stroke-width="1"/>',
    "folder-cloud": f'<path d="M8 15 H14 A2 2 0 0 0 14 12 A3 3 0 0 0 9 12 A2 2 0 0 0 8 15 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="1"/>',
    "folder-templates": f'<path d="M8 10 H13 L15 12 V17 H8 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.8"/><path d="M10 13 L13 16" stroke="{INK}" stroke-width="0.8"/>',
    "folder-public": '<circle cx="11" cy="11.5" r="1.5"/><path d="M8 16 C8 14 9.5 13.5 11 13.5 C12.5 13.5 14 14 14 16 Z"/>',
    "folder-locked": f'<rect x="8.5" y="12" width="5" height="4.5" rx="1"/><path d="M9.5 12 V10.5 A1.5 1.5 0 0 1 12.5 10.5 V12" stroke="{INK}" stroke-width="1" fill="none"/>',
    "folder-temp": f'<path d="M8.5 10 H13.5 M8.5 16 H13.5 M9 10 L11 13 L13 10 M9 16 L11 13 L13 16" stroke="{INK}" stroke-width="1" fill="none"/>',
}


def icon_terminal_22() -> str:
    return svg(
        f'<rect x="2" y="3" width="18" height="16" rx="2" fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        f'<rect x="2" y="3" width="18" height="3" rx="1" fill="{SLATE_BODY}"/>'
        f'<text x="4" y="11" font-family="monospace" font-size="5" font-weight="bold" fill="{LINK_ACCENT}">&gt;</text>'
        f'<text x="8" y="11" font-family="monospace" font-size="5" fill="{AMBER}">fff</text>', 22
    )


def icon_file_manager_22() -> str:
    return svg(
        f'<rect x="4" y="3" width="14" height="16" rx="1.5" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        f'<rect x="4" y="4" width="14" height="6.5" rx="1" fill="{AMBER_BACK}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<rect x="9.5" y="6.5" width="3" height="1" rx="0.5" fill="{CREAM}"/>'
        f'<rect x="5" y="11.5" width="12" height="6.5" rx="1" fill="{SLATE_DARK}"/>'
        f'<rect x="9.5" y="14" width="3" height="1" rx="0.5" fill="{CREAM}"/>', 22
    )


def icon_preferences_22() -> str:
    return svg(
        f'<circle cx="11" cy="11" r="7.5" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        f'<circle cx="11" cy="11" r="3.5" fill="{AMBER}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<circle cx="11" cy="11" r="1.5" fill="{SLATE_DARK}"/>', 22
    )


def icon_search_22() -> str:
    return svg(
        f'<circle cx="10" cy="10" r="5.5" fill="{CREAM_PAPER}" stroke="{SLATE_BODY}" stroke-width="1.8"/>'
        f'<circle cx="10" cy="10" r="6.2" fill="none" stroke="{SLATE_RIM}" stroke-width="0.6"/>'
        f'<path d="M14 14 L18.5 18.5" stroke="{SLATE_BODY}" stroke-width="2" stroke-linecap="round"/>', 22
    )


def icon_drive_22(removable: bool = False) -> str:
    return svg(
        f'<rect x="3" y="7" width="16" height="9" rx="1.5" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="1"/>'
        f'<rect x="5" y="10" width="9" height="1.5" rx="0.5" fill="{SLATE_DARK}"/>'
        f'<circle cx="16" cy="10.5" r="1" fill="{POSITIVE}"/>', 22
    )


# =============================================================================
# 16px ICONS (Small Panel Size: Ear-notched tab preserved, clean pixel grid)
# =============================================================================

def folder_base_16(emblem: str = "") -> str:
    """Folder at 16px: ear-notched tab strictly preserved on pixel grid."""
    back = (
        f'<path d="M1 4 Q1 3 2.5 3 L3 3 L4 1.5 L5 3 L6 3 L7 1.5 L8 3 L8.5 3 '
        f'Q9.5 3 10 3.8 L10.5 4 L13.5 4 Q14.5 4 14.5 5 L14.5 13 L1 13 Z" fill="{AMBER_BACK}"/>'
        f'<path d="M3.7 2.8 L4 2.2 L4.3 2.8 Z M6.7 2.8 L7 2.2 L7.3 2.8 Z" fill="{ROSE}"/>'
    )
    front = (
        f'<rect x="1" y="5" width="14" height="9" rx="1.5" fill="{AMBER}"/>'
        f'<rect x="1" y="5" width="14" height="1" rx="0.5" fill="{AMBER_HIGHLIGHT}" opacity="0.9"/>'
    )
    return back + front + (f'<g fill="{INK}">{emblem}</g>' if emblem else "")


def icon_trash_16(full: bool) -> str:
    """Trash at 16px with ear-notched lid."""
    lid = (
        f'<path d="M3 5 L4.5 2.8 L6 4.2 L10 4.2 L11.5 2.8 L13 5 Q13.5 6 12.5 6 L3.5 6 Q2.5 6 3 5 Z" '
        f'fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
    )
    can = (
        f'<path d="M3.5 6.5 H12.5 L11.5 14.5 Q11.3 15 10.5 15 H5.5 Q4.7 15 4.5 14.5 Z" '
        f'fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
    )
    if not full:
        return svg(can + lid, 16)
    else:
        paper = f'<path d="M4.5 6.5 Q8 3.5 11.5 6.5 Z" fill="{CREAM}"/>'
        return svg(can + paper + lid, 16)


EMBLEMS_16 = {
    "folder": "",
    "folder-home": '<path d="M8 6.5 L4.5 9.5 H5.5 V13.5 H10.5 V9.5 H11.5 Z"/>',
    "folder-documents": f'<path d="M5.5 6.5 H9.5 L11.5 8.5 V13.5 H5.5 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.6"/>',
    "folder-downloads": '<path d="M7 6.5 H9 V9.5 H10.5 L8 12 L5.5 9.5 H7 Z"/><rect x="5.5" y="12.5" width="5" height="1" rx="0.5"/>',
    "folder-pictures": f'<rect x="4.5" y="7" width="7" height="5.5" rx="0.5" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.5"/><path d="M5 12 L7 9.5 L8.5 11 L9.5 10.5 L11 12 Z" fill="{LINK_DEEP}"/>',
    "folder-music": f'<ellipse cx="6.5" cy="12" rx="1.2" ry="0.9" transform="rotate(-20 6.5 12)"/><ellipse cx="10.5" cy="11.5" rx="1.2" ry="0.9" transform="rotate(-20 10.5 11.5)"/><path d="M7.5 11.5 V8 L11.5 7.5 V11" stroke="{INK}" stroke-width="1"/>',
    "folder-videos": f'<rect x="5" y="7.5" width="6" height="4.5" rx="0.8"/><polygon points="7,8.5 9.5,9.7 7,11" fill="{AMBER}"/>',
    "folder-desktop": f'<rect x="5" y="7.5" width="6" height="4" rx="0.6"/><rect x="5.8" y="8.2" width="4.4" height="2.6" fill="{CREAM_PAPER}"/><rect x="7" y="11.5" width="2" height="1"/>',
    "folder-favorites": f'<ellipse cx="8" cy="11" rx="1.8" ry="1.4" fill="{ROSE}"/><circle cx="6" cy="8.8" r="0.8" fill="{ROSE}"/><circle cx="7.3" cy="7.7" r="0.8" fill="{ROSE}"/><circle cx="8.7" cy="7.7" r="0.8" fill="{ROSE}"/><circle cx="10" cy="8.8" r="0.8" fill="{ROSE}"/>',
    "folder-git": f'<path d="M7 12.5 V8.5 M7 10.5 C7 9.5 9.5 9.5 9.5 8.5" stroke="{INK}" stroke-width="1" fill="none"/><circle cx="7" cy="12.5" r="0.9" fill="{LINK_DEEP}"/><circle cx="7" cy="8.5" r="0.9" fill="{LINK_DEEP}"/><circle cx="9.5" cy="8.5" r="0.9" fill="{LINK_DEEP}"/>',
    "folder-development": f'<path d="M6.5 8.5 L5 10 L6.5 11.5 M8 12 L8.5 8 M10 8.5 L11.5 10 L10 11.5" stroke="{INK}" stroke-width="1" stroke-linecap="round" fill="none"/>',
    "folder-network": f'<circle cx="8" cy="8" r="1" fill="{LINK_DEEP}"/><circle cx="6" cy="12" r="1" fill="{LINK_DEEP}"/><circle cx="10" cy="12" r="1" fill="{LINK_DEEP}"/><path d="M8 8.5 L6 11.5 M8 8.5 L10 11.5" stroke="{INK}" stroke-width="0.8"/>',
    "folder-cloud": f'<path d="M6 12 H10.5 A1.5 1.5 0 0 0 10.5 9.5 A2 2 0 0 0 7 9.5 A1.5 1.5 0 0 0 6 12 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.8"/>',
    "folder-templates": f'<path d="M5.5 7 H9.5 L11.5 9 V13 H5.5 Z" fill="{CREAM_PAPER}" stroke="{INK}" stroke-width="0.6"/>',
    "folder-public": '<circle cx="8" cy="8.5" r="1.2"/><path d="M6 12 C6 10.5 7 10 8 10 C9 10 10 10.5 10 12 Z"/>',
    "folder-locked": f'<rect x="6" y="9.5" width="4" height="3.5" rx="0.5"/><path d="M7 9.5 V8 A1 1 0 0 1 9 8 V9.5" stroke="{INK}" stroke-width="0.8" fill="none"/>',
    "folder-temp": f'<path d="M6 7.5 H10 M6 12.5 H10 M6.5 7.5 L8 10 L9.5 7.5 M6.5 12.5 L8 10 L9.5 12.5" stroke="{INK}" stroke-width="0.8" fill="none"/>',
}


def icon_terminal_16() -> str:
    return svg(
        f'<rect x="1" y="2" width="14" height="12" rx="1.5" fill="{SLATE_DARK}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<rect x="1" y="2" width="14" height="2.5" rx="1" fill="{SLATE_BODY}"/>'
        f'<text x="3" y="8" font-family="monospace" font-size="4" font-weight="bold" fill="{LINK_ACCENT}">&gt;</text>'
        f'<rect x="6" y="6" width="2" height="3" fill="{AMBER}"/>', 16
    )


def icon_file_manager_16() -> str:
    return svg(
        f'<rect x="2.5" y="2" width="11" height="12" rx="1" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<rect x="2.5" y="3" width="11" height="4.5" rx="0.5" fill="{AMBER_BACK}" stroke="{SLATE_RIM}" stroke-width="0.6"/>'
        f'<rect x="3.5" y="8.5" width="9" height="4.5" rx="0.5" fill="{SLATE_DARK}"/>', 16
    )


def icon_preferences_16() -> str:
    return svg(
        f'<circle cx="8" cy="8" r="5.5" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<circle cx="8" cy="8" r="2.5" fill="{AMBER}"/>'
        f'<circle cx="8" cy="8" r="1" fill="{SLATE_DARK}"/>', 16
    )


def icon_search_16() -> str:
    return svg(
        f'<circle cx="7" cy="7" r="4" fill="{CREAM_PAPER}" stroke="{SLATE_BODY}" stroke-width="1.4"/>'
        f'<path d="M10 10 L13.5 13.5" stroke="{SLATE_BODY}" stroke-width="1.8" stroke-linecap="round"/>', 16
    )


def icon_drive_16(removable: bool = False) -> str:
    return svg(
        f'<rect x="2" y="5" width="12" height="7" rx="1" fill="{SLATE_BODY}" stroke="{SLATE_RIM}" stroke-width="0.8"/>'
        f'<rect x="3.5" y="7.5" width="6" height="1" fill="{SLATE_DARK}"/>'
        f'<circle cx="12" cy="8" r="0.8" fill="{POSITIVE}"/>', 16
    )


# =============================================================================
# SYMBOLIC SET (16px, monochrome, ColorScheme-Text class)
# =============================================================================

SYMBOLIC_ICONS = {
    # Ear-notched tab on folder
    "folder-symbolic": (
        "M1 3 L1 4 L1 13 L1 14 L15 14 L15 13 L15 5 L15 4 L9.5 4 L9 2.5 L8 4 L7 2.5 L6 4 L2 4 L1 3 Z "
        "M2 5 L14 5 L14 13 L2 13 Z"
    ),
    # House silhouette (no cat)
    "user-home-symbolic": (
        "M8 2 L1 8 H3 V14 H13 V8 H15 Z M6 9 H10 V14 H6 Z"
    ),
    # Trash bin with ear-notched lid (no cat)
    "user-trash-symbolic": (
        "M2 4 L4 2 L5 3 L11 3 L12 2 L14 4 Z M3 5 L4.5 14 H11.5 L13 5 Z"
    ),
    # Magnifying glass (no cat)
    "system-search-symbolic": (
        "M6.5 2 A4.5 4.5 0 1 0 10.2 9.4 L13.6 12.8 L14.7 11.7 L11.3 8.3 A4.5 4.5 0 0 0 6.5 2 Z "
        "M6.5 3.5 A3 3 0 1 1 3.5 6.5 A3 3 0 0 1 6.5 3.5 Z"
    ),
}


# =============================================================================
# WRITER AND MAIN
# =============================================================================

def write_icon(dest: pathlib.Path, content: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content)


def symlink_icon(dest: pathlib.Path, target_name: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() or dest.is_symlink():
        dest.unlink()
    dest.symlink_to(target_name)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Thumbs & Paws icon theme.")
    parser.add_argument("--check-contrast", action="store_true", help="Print contrast check and exit.")
    args = parser.parse_args()

    if args.check_contrast:
        passed = check_contrast()
        return 0 if passed else 1

    check_contrast()

    # Context directories
    places_64 = ROOT / "places" / "scalable"
    places_22 = ROOT / "places" / "22"
    places_16 = ROOT / "places" / "16"

    apps_64 = ROOT / "apps" / "scalable"
    apps_22 = ROOT / "apps" / "22"
    apps_16 = ROOT / "apps" / "16"

    actions_64 = ROOT / "actions" / "scalable"
    actions_22 = ROOT / "actions" / "22"
    actions_16 = ROOT / "actions" / "16"

    devices_64 = ROOT / "devices" / "scalable"
    devices_22 = ROOT / "devices" / "22"
    devices_16 = ROOT / "devices" / "16"

    # --- 1. PLACES: FOLDERS ---
    scalable_folders = {
        "folder": icon_folder_64(),
        "folder-home": icon_folder_home_64(),
        "folder-documents": icon_folder_documents_64(),
        "folder-downloads": icon_folder_downloads_64(),
        "folder-pictures": icon_folder_pictures_64(),
        "folder-music": icon_folder_music_64(),
        "folder-videos": icon_folder_videos_64(),
        "folder-desktop": icon_folder_desktop_64(),
        "folder-favorites": icon_folder_favorites_64(),
        "folder-git": icon_folder_git_64(),
        "folder-development": icon_folder_development_64(),
    }
    for name, content in scalable_folders.items():
        write_icon(places_64 / f"{name}.svg", content)
        write_icon(places_22 / f"{name}.svg", svg(folder_base_22(EMBLEMS_22[name]), 22))
        write_icon(places_16 / f"{name}.svg", svg(folder_base_16(EMBLEMS_16[name]), 16))

    # Quiet folder variants
    for name, emblem in QUIET_EMBLEMS_64.items():
        write_icon(places_64 / f"{name}.svg", icon_quiet_folder_64(emblem))
        write_icon(places_22 / f"{name}.svg", svg(folder_base_22(EMBLEMS_22[name]), 22))
        write_icon(places_16 / f"{name}.svg", svg(folder_base_16(EMBLEMS_16[name]), 16))

    # --- 2. PLACES: TRASH ---
    write_icon(places_64 / "user-trash.svg", icon_trash_64(full=False))
    write_icon(places_64 / "user-trash-full.svg", icon_trash_64(full=True))
    write_icon(places_22 / "user-trash.svg", icon_trash_22(full=False))
    write_icon(places_22 / "user-trash-full.svg", icon_trash_22(full=True))
    write_icon(places_16 / "user-trash.svg", icon_trash_16(full=False))
    write_icon(places_16 / "user-trash-full.svg", icon_trash_16(full=True))

    # --- 3. PLACES: SYMBOLIC ---
    write_icon(places_16 / "folder-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["folder-symbolic"]))
    write_icon(places_16 / "user-home-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["user-home-symbolic"]))
    write_icon(places_16 / "user-trash-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["user-trash-symbolic"]))
    # Also write to scalable for Plasma SVG resolution
    write_icon(places_64 / "folder-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["folder-symbolic"]))
    write_icon(places_64 / "user-home-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["user-home-symbolic"]))
    write_icon(places_64 / "user-trash-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["user-trash-symbolic"]))

    # --- 4. APPS ---
    # Terminal
    write_icon(apps_64 / "utilities-terminal.svg", icon_terminal_64())
    write_icon(apps_22 / "utilities-terminal.svg", icon_terminal_22())
    write_icon(apps_16 / "utilities-terminal.svg", icon_terminal_16())
    symlink_icon(apps_64 / "org.kde.konsole.svg", "utilities-terminal.svg")
    symlink_icon(apps_22 / "org.kde.konsole.svg", "utilities-terminal.svg")
    symlink_icon(apps_16 / "org.kde.konsole.svg", "utilities-terminal.svg")

    # File manager (Dolphin)
    write_icon(apps_64 / "system-file-manager.svg", icon_file_manager_64())
    write_icon(apps_22 / "system-file-manager.svg", icon_file_manager_22())
    write_icon(apps_16 / "system-file-manager.svg", icon_file_manager_16())
    symlink_icon(apps_64 / "org.kde.dolphin.svg", "system-file-manager.svg")
    symlink_icon(apps_22 / "org.kde.dolphin.svg", "system-file-manager.svg")
    symlink_icon(apps_16 / "org.kde.dolphin.svg", "system-file-manager.svg")

    # Preferences (System Settings)
    write_icon(apps_64 / "preferences-system.svg", icon_preferences_64())
    write_icon(apps_22 / "preferences-system.svg", icon_preferences_22())
    write_icon(apps_16 / "preferences-system.svg", icon_preferences_16())
    symlink_icon(apps_64 / "org.kde.systemsettings.svg", "preferences-system.svg")
    symlink_icon(apps_22 / "org.kde.systemsettings.svg", "preferences-system.svg")
    symlink_icon(apps_16 / "org.kde.systemsettings.svg", "preferences-system.svg")

    # --- 5. ACTIONS: SEARCH ---
    write_icon(actions_64 / "system-search.svg", icon_search_64())
    write_icon(actions_22 / "system-search.svg", icon_search_22())
    write_icon(actions_16 / "system-search.svg", icon_search_16())
    write_icon(actions_16 / "system-search-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["system-search-symbolic"]))
    write_icon(actions_64 / "system-search-symbolic.svg", symbolic_svg(SYMBOLIC_ICONS["system-search-symbolic"]))

    # --- 6. DEVICES: DRIVES ---
    write_icon(devices_64 / "drive-harddisk.svg", icon_drive_64(removable=False))
    write_icon(devices_22 / "drive-harddisk.svg", icon_drive_22(removable=False))
    write_icon(devices_16 / "drive-harddisk.svg", icon_drive_16(removable=False))

    write_icon(devices_64 / "drive-removable-media.svg", icon_drive_64(removable=True))
    write_icon(devices_22 / "drive-removable-media.svg", icon_drive_22(removable=True))
    write_icon(devices_16 / "drive-removable-media.svg", icon_drive_16(removable=True))

    print(f"Generated complete Thumbs & Paws icon set across places, apps, actions, devices.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
