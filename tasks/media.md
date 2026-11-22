# Task: Media overhaul (all artwork and sound for the suite)

Read `AGENTS.md` and `tasks/README.md` first. This task makes every picture, cursor and sound in the suite look like one family. Work in the phases below, **in order**, and stop for the owner's approval at the end of each phase.

---

## 1. Casper, the character

> **Owner context:** Casper is a **pure white** cat.
>
> - **Dark mode:** Casper is luminous white against the night tones. Amber or teal eyes, rose inner ears and toe beans.
> - **Light mode (inversion):** Casper becomes a sleek black silhouette against the cream and amber daytime tones, with the same eyes, ears and beans.

**Colour rule.** Add the cat colours to the palette instead of hard-coding them. Put `CASPER_LIGHT` and `CASPER_DARK` dicts (coat, coat-shade, eye, inner-ear, bean, rim) in `color-scheme/tabby-and-tweed/tools/generate.py`.
- Starting values: coat `#FBF8F2` (dark) and `#1B1714` (light), eye `#E8A256` or `#5CC6B8`, inner ear and beans `#F0807A`.
- The `.colors` output must stay byte-identical. Prove it with `git diff --stat` after regenerating.
- No hex values in any other file.

**Casper Mono (owner decision).** Doorstep, Catnap, the Whiskers icon, cursors, and every symbolic or tray icon use **only black, white and greys**. There is no amber, teal or rose in these.
- **Dark:** a near-black background (`MONO_DARK.bg`, about `#0E0E0E`) with Casper and the text in pure white.
- **Light:** the exact inverse. A white background, with Casper and the text in near-black.
- **Greys:** depth comes only from white or black at reduced opacity (8–60 %). Glass blur is allowed; tints are not.
- **Tokens:** add `MONO_LIGHT` and `MONO_DARK` dicts (bg, fg, fg-muted, rim, overlay) to the palette, next to `CASPER_*`.
- **Accessibility:** text must still pass WCAG AA, and the focus ring is solid `fg`.
- Exceptions: system semantic colours for errors and warnings (as the system shows them), and **Whiskers** may use them for its status (red problem, amber warning). Full-colour folder icons keep their colours.
- Doorstep and Catnap UI rules: see the "Look and feel" section in `tasks/doorstep.md` and `tasks/catnap.md`.

**Shared parts library.** Write `art/casper.py` at the repo root. Every component's `tools/generate.py` imports it, so Casper is drawn one way everywhere.
- **Poses:** loaf, stretch, curl (asleep), sit, peek (ears plus eyes over an edge), paw (pad plus toe beans), tail curl, paw print.
- **Each pose** is one function: `pose(x, y, size, palette) -> SVG string`.
- **Model sheet:** render `art/preview.png` showing every pose at 256 px and 64 px, on `#eff0f1` and `#202326`.

## 2. Inventory (what the suite needs)

| # | Component | Files to deliver | Notes |
|---|---|---|---|
| A | **Thumbs & Paws** icons | Two themes: `thumbs-and-paws` (light, black Casper) and `thumbs-and-paws-dark` (white Casper), each with `scalable/`, `22/` and `16/` | Icon themes can't follow the colour scheme, so the global theme picks one per variant. Symbolic icons stay `ColorScheme-Text` and are shared through `Inherits`. Icon list and quirks are in `tasks/thumbs-and-paws.md`. |
| B | **Sunbeam** wallpapers | Plasma 6 wallpaper package with `contents/images/` (day) and `contents/images_dark/` (night). Sizes: 1920x1080, 1920x1200, 2560x1440, 2560x1600, 3840x2160, plus **portrait** 1200x1920 and 1600x2560. Also `contents/screenshot.png`. | Day: sunbeam across a wooden floor, black Casper stretched in the warm spot. Night: moonlight, white Casper curled in the beam. The Flow X16 rotates into tablet mode, so the portrait sizes are required. Keep the cat out of the centre and the bottom panel area. |
| C | **Doorstep** (SDDM) | `sddm/doorstep/backgrounds/day.jpg` and `night.jpg` at 2560x1600, rendered by the Sunbeam generator. Plus `faces/casper.png` (256x256, round-safe). | SDDM runs before login and can't see the user's theme, so the QML picks day or night by the hour. The avatar is optional; the owner installs it. |
| D | **Catnap** lock screen | Background art: Casper asleep, low contrast, plus a dimmed variant for the password state | Lock-screen QML is a separate task (`tasks/catnap.md`). This task delivers images only. |
| E | **Laser Pointer** cursors | Two themes, `laser-pointer` and `laser-pointer-dark`. SVG sources render to **Xcursor** at 24, 32, 48 and 64 px and to **SVG cursors** (`cursors_scalable/<name>/metadata.json` plus SVG, Plasma 6). | Full set below. Every cursor gets a hotspot, and the hotspot is checked on the preview. |
| F | **Morning Stretch** splash | Optional v2: vector frames of Casper stretching, generated and assembled into the existing `Splash.qml` animation | The current GIF stays for 0.1.0. Replace it only if v2 is approved. |
| G | **Purr & Ping** sounds | Freedesktop sound theme `index.theme` plus `stereo/*.oga` (fall back to `.wav` if no encoder is installed). Each sound under 0.6 s, quiet and soft. | Synthesise in `tools/generate.py` with Python's `wave` module (sine, chirp, envelope). No samples, no stock sounds. Sound names are listed below. |
| H | **Whiskers** icons | Redraw `whiskers.svg` and `whiskers-symbolic.svg` with the Casper parts | The symbolic icon stays `ColorScheme-Text`. |
| I | **Global theme** previews | Regenerate `light|dark/contents/previews/preview.png` and `fullscreenpreview.jpg` from the final wallpaper, icons and colours | Run `look-and-feel/one-man-nine-lives/tools/generate.py`. |
| J | **Suite branding** | `art/logo.svg` (paw mark plus wordmark), `art/social-preview.png` (1280x640, GitHub), and one 1200x675 store screenshot per component in its folder | Used by the root README, the GitHub repo and later the KDE Store. |

**Cursor names** (alias the legacy names with symlinks):
- **Basic:** `default`, `pointer`, `text`, `vertical-text`, `help`, `context-menu`, `crosshair`, `cell`
- **Busy:** `wait` (animated chasing paw, 8–12 frames), `progress` (arrow plus small paw, animated)
- **Not allowed:** `not-allowed`, `no-drop`
- **Drag and drop:** `copy`, `alias`, `grab`, `grabbing`, `move`, `all-scroll`
- **Resize:** `col-resize`, `row-resize`, `n/s/e/w/ne/nw/se/sw-resize`, `ew/ns/nesw/nwse-resize`
- **Zoom:** `zoom-in`, `zoom-out`

**Sound names:**
- **Messages:** `message-new-instant`, `message-new-email`
- **Dialogs:** `dialog-information`, `dialog-warning`, `dialog-error`
- **General:** `bell`, `complete`, `trash-empty`, `screen-capture`, `audio-volume-change`
- **Devices:** `device-added`, `device-removed`
- **Power:** `power-plug`, `power-unplug`, `battery-low`
- **Session:** `desktop-login`, `desktop-logout`

## 3. Phases (stop after each one)

1. **Palette and Casper.** Add the palette dicts, write `art/casper.py`, and render the model sheet. *Approve the cat before anything else.*
2. **Hero art (B, C, D).** One generator renders the wallpaper, Doorstep and Catnap scenes at every size. Preview: a contact sheet of day, night and portrait.
3. **Icons and Whiskers (A, H).** Rebuild with the Casper parts. Previews at 96, 22 and 16 px, on light and dark.
4. **Cursors (E).** Preview sheet of every cursor at 32 and 64 px with a red hotspot dot, plus the `wait` frames as a strip.
5. **Sounds (G).** Generate the files and write a `listen.sh` that plays each one with its name (`paplay` or `pw-play`).
6. **Splash v2 (F), only if approved; then previews and branding (I, J).**

## 4. Rules

- **Original work only.** Everything is drawn or synthesised by code, or hand-drawn by the owner as plain SVG and committed under `art/src/`.
  - No stock elements, no AI-generated images and no Canva exports in the repo.
  - Canva and AI images may be used as mood boards in the conversation only.
- **Licences.** Code is GPL-3.0-or-later. Artwork and sounds are CC-BY-SA-4.0. Note this in each component's README.
- **Contrast.** Every image must pass on `#eff0f1` and `#202326`. A white Casper needs a soft dark rim where it touches light areas, and the reverse for a black Casper.
- **Fonts.** Ship no fonts. Use only the system UI font.
- **Size budget.** Each wallpaper JPEG at 4K stays under 1.5 MB, at quality 90.
- **No installing.** Test with the commands in `tasks/README.md`. Cursor builds need `xcursorgen`. If it's missing, stop and tell the owner; never install it yourself.

## 5. Deliver

Each phase updates `REVIEW.md` in the folders it touched:
- what changed
- the exact commands that were run, and their results
- the previews to look at
- the owner's try and undo commands, for example `cp -r` into `~/.local/share/...` and `rm -r` to undo
