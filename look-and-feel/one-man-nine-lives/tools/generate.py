#!/usr/bin/env python3
"""Generate the One Man Nine Lives global themes (Light + Dark) for KDE Plasma 6.

Writes light/ and dark/ Plasma/LookAndFeel packages (metadata.json, contents/defaults, previews)
from the Tabby & Tweed palette, so the pair always matches. Previews need ImageMagick (magick).
Run: python3 -I tools/generate.py      SPDX-License-Identifier: GPL-3.0-or-later
"""
import html
import json
import shutil
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent.parent
SUITE = HERE.parent.parent
sys.path.insert(0, str(SUITE / "color-scheme" / "tabby-and-tweed" / "tools"))
from generate import LIGHT, DARK  # noqa: E402  (the suite palette)

VERSION = "0.1.0"
ICONS = SUITE / "icons" / "thumbs-and-paws" / "places" / "scalable"
WHISKERS_ICON = SUITE / "whiskers" / "widget" / "contents" / "icons" / "whiskers.svg"

VARIANTS = {
    "light": dict(palette=LIGHT, name="One Man Nine Lives Light", scheme="TabbyAndTweedLight",
                  desc="One Man Nine Lives, light: Tabby & Tweed Light colours, Thumbs & Paws icons and the Morning Stretch splash."),
    "dark": dict(palette=DARK, name="One Man Nine Lives Dark", scheme="TabbyAndTweedDark",
                 desc="One Man Nine Lives, dark: Tabby & Tweed Dark colours, Thumbs & Paws icons and the Morning Stretch splash."),
}

# Parts not drawn yet fall back to Breeze (window decoration, cursors, Plasma style, lock screen, logout).
# No [Wallpaper] and no layouts: applying the theme never replaces your wallpaper or touches your panels.
DEFAULTS = """[kdeglobals][KDE]
widgetStyle=Breeze

[kdeglobals][General]
ColorScheme={scheme}

[kdeglobals][Icons]
Theme=thumbs-and-paws

[plasmarc][Theme]
name=default

[kcminputrc][Mouse]
cursorTheme=breeze_cursors

[kwinrc][org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze

[ksplashrc][KSplash]
Theme=com.github.techonerd.morningstretch
"""


def metadata(key: str, v: dict) -> dict:
    return {
        "KPackageStructure": "Plasma/LookAndFeel",
        "KPlugin": {
            "Authors": [{"Email": "22074809+techonerd@users.noreply.github.com", "Name": "techonerd"}],
            "Category": "",
            "Description": v["desc"],
            "Id": f"com.github.techonerd.onemanninelives.{key}",
            "License": "GPL-3.0-or-later",
            "Name": v["name"],
            "Version": VERSION,
            "Website": "https://github.com/techonerd/one-man-nine-lives",
        },
        "Keywords": "Desktop;Workspace;Appearance;Look and Feel;Cat;Tabby;One Man Nine Lives;",
        "X-Plasma-APIVersion": "2",
    }


PLACED: list = []
BACKGROUND: list = []   # (svg path, x, y, size) composited after the scene is rendered


def nested(path: pathlib.Path, x: float, y: float, size: float) -> str:
    """Queue an icon to be composited at (x, y); ImageMagick's SVG renderer can't nest SVGs."""
    PLACED.append((path, int(x), int(y), int(size)))
    return ""


def desktop(p: dict) -> str:
    """A 1920x1080 mock desktop in the given palette."""
    f = 'font-family="sans-serif"'
    dark = p is DARK
    sky_top, sky_bottom = ("#2B2F3A", "#4A3A2C") if dark else ("#F6E7CF", "#E7B983")
    sun = "#E8A256" if not dark else "#C47A33"
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">',
           f'<path d="M1500 0 L1920 0 L1920 260 L700 1080 L260 1080 Z" fill="{sun}" opacity=".22"/>',
           f'<path d="M1640 0 L1920 0 L1920 120 L1000 1080 L720 1080 Z" fill="{sun}" opacity=".18"/>']
    BACKGROUND[:] = [sky_top, sky_bottom]
    # desktop icons
    names = [("folder-home", "Home"), ("folder-documents", "Documents"), ("folder-downloads", "Downloads"),
             ("folder-pictures", "Pictures"), ("user-trash", "Trash")]
    label = "#2B2620" if not dark else "#EDE6DA"
    for i, (n, text) in enumerate(names):
        y = 60 + i * 150
        out.append(nested(ICONS / f"{n}.svg", 70, y, 96))
        out.append(f'<text x="118" y="{y + 122}" {f} font-size="20" text-anchor="middle" fill="{label}">{text}</text>')
    # a window
    wx, wy, ww, wh = 420, 150, 1000, 640
    out.append(f'<rect x="{wx + 6}" y="{wy + 10}" width="{ww}" height="{wh}" rx="14" fill="#000" opacity=".18"/>')
    out.append(f'<rect x="{wx}" y="{wy}" width="{ww}" height="{wh}" rx="12" fill="{p["window"]}"/>')
    out.append(f'<path d="M{wx} {wy + 12} Q{wx} {wy} {wx + 12} {wy} H{wx + ww - 12} Q{wx + ww} {wy} {wx + ww} {wy + 12} V{wy + 52} H{wx} Z" fill="{p["header"]}"/>')
    out.append(f'<text x="{wx + ww / 2}" y="{wy + 34}" {f} font-size="20" font-weight="600" text-anchor="middle" fill="{p["text"]}">Home — Dolphin</text>')
    for k, c in enumerate((p["negative"], p["inactive"], p["inactive"])):
        out.append(f'<circle cx="{wx + ww - 30 - k * 34}" cy="{wy + 26}" r="10" fill="{c}"/>')
    # sidebar + content
    out.append(f'<rect x="{wx}" y="{wy + 52}" width="220" height="{wh - 52}" fill="{p["window_alt"]}"/>')
    side = ["Home", "Documents", "Downloads", "Music", "Pictures", "Videos", "Trash"]
    for i, s in enumerate(side):
        y = wy + 90 + i * 44
        if i == 0:
            out.append(f'<rect x="{wx + 10}" y="{y - 28}" width="200" height="38" rx="6" fill="{p["selection"]}"/>')
        out.append(f'<text x="{wx + 30}" y="{y}" {f} font-size="18" fill="{p["selection_text"] if i == 0 else p["text"]}">{s}</text>')
    out.append(f'<rect x="{wx + 220}" y="{wy + 52}" width="{ww - 220}" height="{wh - 52}" fill="{p["view"]}"/>')
    grid = ["folder-desktop", "folder-documents", "folder-downloads", "folder-music", "folder-pictures",
            "folder-videos", "folder-favorites", "folder"]
    labels = ["Desktop", "Documents", "Downloads", "Music", "Pictures", "Videos", "One Man Nine Lives", "Projects"]
    for i, (n, t) in enumerate(zip(grid, labels)):
        cx, cy = wx + 270 + (i % 4) * 180, wy + 90 + (i // 4) * 200
        out.append(nested(ICONS / f"{n}.svg", cx, cy, 112))
        out.append(f'<text x="{cx + 56}" y="{cy + 140}" {f} font-size="17" text-anchor="middle" fill="{p["text"]}">{html.escape(t)}</text>')
    # panel
    out.append(f'<rect x="0" y="1020" width="1920" height="60" fill="{p["window"]}" opacity=".96"/>')
    out.append(f'<rect x="0" y="1020" width="1920" height="1" fill="{p["window_alt"]}"/>')
    out.append(nested(ICONS / "folder-home.svg", 20, 1030, 40))
    out.append(f'<rect x="80" y="1028" width="200" height="44" rx="8" fill="{p["selection"]}" opacity=".25"/>')
    out.append(f'<text x="100" y="1057" {f} font-size="18" fill="{p["text"]}">Home — Dolphin</text>')
    out.append(nested(WHISKERS_ICON, 1700, 1032, 36))
    out.append(f'<text x="1890" y="1058" {f} font-size="20" text-anchor="end" fill="{p["text"]}">09:41</text>')
    out.append("</svg>")
    return "\n".join(out)


def render(svg: str, outs: list) -> None:
    """Render background gradient, the SVG scene and the queued icons; write each (path, size) in outs."""
    tmpdir = pathlib.Path(tempfile.mkdtemp(dir=HERE / "tools"))
    try:
        scene = tmpdir / "scene.svg"
        scene.write_text(svg)
        cmd = ["magick", "-size", "1920x1080", f"gradient:{BACKGROUND[0]}-{BACKGROUND[1]}",
               "(", "-background", "none", "-density", "96", str(scene), ")", "-composite"]
        for i, (path, x, y, size) in enumerate(PLACED):
            png = tmpdir / f"icon{i}.png"
            subprocess.run(["magick", "-background", "none", "-density", "600", str(path), "-resize", f"{size}x{size}", str(png)], check=True)
            cmd += [str(png), "-geometry", f"+{x}+{y}", "-composite"]
        full = tmpdir / "full.png"
        subprocess.run(cmd + [str(full)], check=True)
        for out, size in outs:
            subprocess.run(["magick", str(full), "-resize", size, "-quality", "90", str(out)], check=True)
    finally:
        for f in tmpdir.iterdir():
            f.unlink()
        tmpdir.rmdir()


def main() -> int:
    for key, v in VARIANTS.items():
        pkg = HERE / key
        (pkg / "contents" / "previews").mkdir(parents=True, exist_ok=True)
        (pkg / "metadata.json").write_text(json.dumps(metadata(key, v), indent=4, ensure_ascii=False) + "\n")
        (pkg / "contents" / "defaults").write_text(DEFAULTS.format(scheme=v["scheme"]))
        PLACED.clear()
        svg = desktop(v["palette"])
        prev = pkg / "contents" / "previews"
        render(svg, [(prev / "fullscreenpreview.jpg", "1920x1080"), (prev / "preview.png", "600x337")])
        shutil.copyfile(SUITE / "splash" / "morning-stretch" / "contents" / "previews" / "splash.png", prev / "splash.png")
        print(f"wrote {pkg.relative_to(SUITE)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
