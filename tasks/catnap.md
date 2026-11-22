# Task: Catnap (lock screen)

*A quick nap at the desk / the sixteenth nap of the day.* Read `AGENTS.md`, `tasks/README.md`. **High risk:** a broken lock screen can lock the owner out. Do not run any lock-screen binary; build and lint only.

## Build
- `contents/lockscreen/` inside **both** `look-and-feel/one-man-nine-lives/light/` and `dark/` (or generated into both by `look-and-feel/one-man-nine-lives/tools/generate.py`). Start from the structure the Plasma 6 lock screen expects (`LockScreen.qml` / `LockScreenUi.qml` entry points; study `/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/lockscreen/` for the **interface only**: required ids, properties and signals. Do not copy its code or artwork).
- Must keep every safety feature: password field always reachable, keyboard layout switch, virtual keyboard, switch user, media controls optional, **no Hibernate button**.
- Look: dimmed Sunbeam night wallpaper, a sleeping cat line-art above the clock, Casper Mono colours (see Look and feel below).

## Look and feel (owner decision, applies to Doorstep and Catnap)
- **Native, modern controls only:** `org.kde.plasma.components` (PlasmaComponents3), `org.kde.plasma.extras` and `org.kde.kirigami`. No hand-drawn `Rectangle` buttons or boxes; use `PlasmaComponents3.Button`/`ToolButton`/`ComboBox` (flat, rounded, hover/press states come from Plasma).
- **Password:** `PlasmaExtras.PasswordField` (built-in show/hide eye), the same look as the current system.
- **Icons:** system icon names only (`system-suspend`, `system-reboot`, `system-shutdown`, `system-switch-user`, `input-keyboard`, `input-keyboard-virtual`, `go-next`, `dialog-error`, `data-warning`). Do **not** generate icons. The only custom artwork is Casper.
- **Glass:** blurred background (`QtQuick.Effects` `MultiEffect`, blur on, ~0.6 to 0.8) behind a semi-transparent panel: `MONO_*.overlay` fill, 1 px `rim` border at low opacity, `Kirigami.Units` corner radius and spacing. No gradients, no tints.
- **Colours:** text and Casper strictly `MONO_*` (black and white). Errors, Caps Lock and warnings use the system's own semantic colours (`Kirigami.Theme.negativeTextColor`, `neutralTextColor`) plus an icon and text, exactly as the system shows them; never colour alone.
- **Own work:** write every file from scratch. Breeze may be read **only** to learn interface names (ids, properties, signals). Do not copy code, structure, comments, artwork or strings; add no "based on" credits or third-party attribution. Each file has a single header: `SPDX-License-Identifier: GPL-3.0-or-later` and `SPDX-FileCopyrightText: techonerd`.

## Test (no install)
- `qmllint` every file; document every interface item checked against Breeze in `REVIEW.md`.
- Do **not** run `kscreenlocker_greet`.

## Deliver
`REVIEW.md` with the owner's **safe** test: `/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing` *after* installing the global theme to a test user or with a second TTY logged in (Ctrl+Alt+F3) as an escape hatch; and the rollback: re-run `look-and-feel/one-man-nine-lives/install.sh` from a version without `lockscreen/`, or switch the global theme back.
