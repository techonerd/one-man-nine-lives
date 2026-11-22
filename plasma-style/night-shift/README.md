# Night Shift (Plasma Style & Konsole)

*Late-night work / a nocturnal hunter.*

**Status:** v0.2.0.

Night Shift is KDE's **Breeze** Plasma style in One Man Nine Lives branding. It ships no artwork of its own: every panel, popup, tooltip and control falls back to Breeze (`/usr/share/plasma/desktoptheme/default`), which recolours itself from the active colour scheme. With Tabby & Tweed Light or Dark selected, you get Breeze shapes in our colours, at any display scale, and Breeze fixes arrive with every Plasma update.

## Layout
- `night-shift/`: the `Plasma/Theme` package (`metadata.json`, and a `plasmarc` matching Breeze's).
- `konsole/`: terminal colour schemes (`NightShiftDark.colorscheme`, `NightShiftLight.colorscheme`) and profiles (`Night Shift Dark.profile`, `Night Shift Light.profile`).
- `tools/generate.py`: writes both from the Tabby & Tweed palette and checks contrast.

## Build
```bash
python3 -I plasma-style/night-shift/tools/generate.py
```
Install with the suite's `./install.sh`.

## Attribution
Panel, popup and control graphics are Breeze by the KDE Visual Design Group (LGPL), used at runtime from the installed `plasma-desktoptheme` package; no Breeze files are copied into this repository. Night Shift's own files are GPL-3.0-or-later.
