#!/usr/bin/env python3
"""Generate the Thumbs & Paws icons (One Man Nine Lives suite).

Every icon is drawn here from simple shapes, so the whole set stays consistent and is 100 % original.
Run:  python3 -I tools/generate.py      (writes into places/ and apps/ next to this folder)
SPDX-License-Identifier: GPL-3.0-or-later
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Tabby & Tweed palette: mid-tones that read well on both light and dark panels
AMBER, AMBER_DARK, AMBER_LIGHT = "#E8A256", "#C47A33", "#F3C489"
SLATE, SLATE_DARK = "#56657A", "#3E4A5B"
CREAM, INK, TEAL, ROSE = "#F6F0E4", "#7A4218", "#2A9D8F", "#E58B97"


def svg(body: str, size: int = 64) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 64 64">\n'
            f'{body}\n</svg>\n')


def folder(emblem: str = "") -> str:
    # back panel with a tab that has two cat ears
    back = (f'<path d="M6 14 Q6 10 10 10 L13 10 L16 5 L19 10 L22 10 L25 5 L28 10 L30 10 Q33 10 35 13 L37 15 '
            f'L54 15 Q58 15 58 19 L58 48 L6 48 Z" fill="{AMBER_DARK}"/>')
    front = (f'<rect x="4" y="20" width="56" height="36" rx="5" fill="{AMBER}"/>'
             f'<rect x="4" y="20" width="56" height="3" rx="1.5" fill="{AMBER_LIGHT}" opacity=".9"/>')
    inner_ears = (f'<path d="M14.2 9.4 L16 6.6 L17.8 9.4 Z M23.2 9.4 L25 6.6 L26.8 9.4 Z" fill="{ROSE}" opacity=".85"/>')
    return svg(back + inner_ears + front + (f'<g fill="{INK}" opacity=".72">{emblem}</g>' if emblem else ""))


EMBLEMS = {
    "folder": "",
    # house with an ear-shaped roof line
    "folder-home": '<path d="M32 27 L43 36 L40 36 L40 47 L35 47 L35 41 L29 41 L29 47 L24 47 L24 36 L21 36 Z"/>',
    # arrow down into a tray
    "folder-downloads": '<path d="M29 27 H35 V36 H40 L32 44 L24 36 H29 Z"/><rect x="22" y="46" width="20" height="3" rx="1.5"/>',
    # page with folded corner and lines
    "folder-documents": ('<path d="M24 27 H36 L41 32 V49 H24 Z" opacity=".9"/>'
                         f'<path d="M27 36 H38 M27 40 H38 M27 44 H34" stroke="{AMBER}" stroke-width="2" stroke-linecap="round"/>'),
    # mountains and a sun
    "folder-pictures": '<circle cx="38" cy="31" r="3"/><path d="M21 47 L29 35 L34 42 L37 38 L44 47 Z"/>',
    # music note
    "folder-music": '<path d="M29 29 L41 26 V43 A4 3.5 0 1 1 38 39.6 V31 L32 32.4 V45 A4 3.5 0 1 1 29 41.6 Z"/>',
    # play button
    "folder-videos": '<rect x="21" y="28" width="22" height="18" rx="3"/>'
                     f'<path d="M29 32 L37 37 L29 42 Z" fill="{AMBER}"/>',
    # monitor
    "folder-desktop": f'<rect x="21" y="28" width="22" height="14" rx="2"/><rect x="24" y="31" width="16" height="8" rx="1" fill="{AMBER}"/>'
                      '<rect x="29" y="43" width="6" height="3"/><rect x="25" y="46" width="14" height="2" rx="1"/>',
    # paw print (the suite's own folder)
    "folder-favorites": '<ellipse cx="32" cy="41" rx="6.5" ry="5.5"/><circle cx="24.5" cy="34" r="2.6"/><circle cx="29" cy="30" r="2.6"/>'
                        '<circle cx="35" cy="30" r="2.6"/><circle cx="39.5" cy="34" r="2.6"/>',
}


def trash(full: bool) -> str:
    paper = (f'<path d="M22 15 L27 8 L33 13 L38 7 L43 14 Z" fill="{CREAM}" stroke="{SLATE_DARK}" stroke-width="1"/>'
             if full else "")
    lid = (f'<path d="M14 18 L17 12 L20 16 L44 16 L47 12 L50 18 Q51 21 48 21 L16 21 Q13 21 14 18 Z" fill="{SLATE_DARK}"/>'
           f'<path d="M16.4 16.6 L17.2 14.2 L18.6 16.2 Z M45.4 16.2 L46.8 14.2 L47.6 16.6 Z" fill="{ROSE}"/>')
    can = (f'<path d="M17 23 H47 L44 55 Q43.6 58 40.6 58 H23.4 Q20.4 58 20 55 Z" fill="{SLATE}"/>'
           f'<path d="M25 28 L26 52 M32 28 V52 M39 28 L38 52" stroke="{CREAM}" stroke-width="2.4" stroke-linecap="round" opacity=".55"/>')
    return svg(paper + can + lid)


def main() -> None:
    places = ROOT / "places" / "scalable"
    places.mkdir(parents=True, exist_ok=True)
    for name, emblem in EMBLEMS.items():
        (places / f"{name}.svg").write_text(folder(emblem))
    (places / "user-trash.svg").write_text(trash(False))
    (places / "user-trash-full.svg").write_text(trash(True))
    print(f"wrote {len(EMBLEMS) + 2} icons to {places}")


if __name__ == "__main__":
    main()
