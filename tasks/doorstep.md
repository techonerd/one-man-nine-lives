# Task: Doorstep (SDDM login screen)

*Coming home / waiting at the door.* Read `AGENTS.md`, `tasks/README.md`, `sddm/doorstep/README.md`. **Medium risk:** a broken login theme can make logging in hard, so the owner tests it in a window before installing.

## Build
- A Qt 6 SDDM theme in `sddm/doorstep/doorstep/`: `metadata.desktop` (with `QtVersion=6`), `theme.conf`, `Main.qml`, `preview.png`.
- Layout: Sunbeam background (use `wallpapers/sunbeam/.../doorstep-background.jpg` if the Sunbeam task is done, else a palette gradient); a card with avatar, user list/username field, password field, session selector, keyboard-layout indicator, and power buttons: **Suspend, Restart, Shut down only, no Hibernate button**.
- Standard SDDM QML API only (`sddm`, `userModel`, `sessionModel`, `keyboard`, `config`); Casper Mono colours (see Look and feel below); touch-friendly sizes (the laptop has a touchscreen); a virtual keyboard toggle if `QtQuick.VirtualKeyboard` is available.
- Clear error message on wrong password; Caps Lock warning.

## Look and feel (owner decision, applies to Doorstep and Catnap)
- **Native, modern controls only:** `org.kde.plasma.components` (PlasmaComponents3), `org.kde.plasma.extras` and `org.kde.kirigami`. No hand-drawn `Rectangle` buttons or boxes; use `PlasmaComponents3.Button`/`ToolButton`/`ComboBox` (flat, rounded, hover/press states come from Plasma).
- **Password:** `PlasmaExtras.PasswordField` (built-in show/hide eye), the same look as the current system.
- **Icons:** system icon names only (`system-suspend`, `system-reboot`, `system-shutdown`, `system-switch-user`, `input-keyboard`, `input-keyboard-virtual`, `go-next`, `dialog-error`, `data-warning`). Do **not** generate icons. The only custom artwork is Casper.
- **Glass:** blurred background (`QtQuick.Effects` `MultiEffect`, blur on, ~0.6 to 0.8) behind a semi-transparent panel: `MONO_*.overlay` fill, 1 px `rim` border at low opacity, `Kirigami.Units` corner radius and spacing. No gradients, no tints.
- **Colours:** text and Casper strictly `MONO_*` (black and white). Errors, Caps Lock and warnings use the system's own semantic colours (`Kirigami.Theme.negativeTextColor`, `neutralTextColor`) plus an icon and text, exactly as the system shows them; never colour alone.
- **Own work:** write every file from scratch. Breeze may be read **only** to learn interface names (ids, properties, signals). Do not copy code, structure, comments, artwork or strings; add no "based on" credits or third-party attribution. Each file has a single header: `SPDX-License-Identifier: GPL-3.0-or-later` and `SPDX-FileCopyrightText: techonerd`.

## Test (no install)
- `qmllint` the QML.
- The **owner** previews it in a window (safe, needs no root and changes nothing):
  `sddm-greeter-qt6 --test-mode --theme ./sddm/doorstep/doorstep`

## Deliver
`REVIEW.md` with the test command above, plus the install commands for later (needs sudo, owner only):
`sudo cp -r sddm/doorstep/doorstep /usr/share/sddm/themes/` and `/etc/sddm.conf.d/20-theme.conf` with `[Theme] Current=doorstep`; undo: delete both. Note: the existing `/etc/sddm.conf.d/10-wayland.conf` must stay untouched.
