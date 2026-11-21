# Task: Doorstep (SDDM login screen)

*Coming home / waiting at the door.* Read `AGENTS.md`, `tasks/README.md`, `sddm/doorstep/README.md`. **Medium risk:** a broken login theme can make logging in hard, so the owner tests it in a window before installing.

## Build
- A Qt 6 SDDM theme in `sddm/doorstep/doorstep/`: `metadata.desktop` (with `QtVersion=6`), `theme.conf`, `Main.qml`, `preview.png`.
- Layout: Sunbeam background (use `wallpapers/sunbeam/.../doorstep-background.jpg` if the Sunbeam task is done, else a palette gradient); a card with avatar, user list/username field, password field, session selector, keyboard-layout indicator, and power buttons: **Suspend, Restart, Shut down only, no Hibernate button**.
- Standard SDDM QML API only (`sddm`, `userModel`, `sessionModel`, `keyboard`, `config`); Tabby & Tweed Dark colours; touch-friendly sizes (the laptop has a touchscreen); a virtual keyboard toggle if `QtQuick.VirtualKeyboard` is available.
- Clear error message on wrong password; Caps Lock warning.

## Test (no install)
- `qmllint` the QML.
- The **owner** previews it in a window (safe, needs no root and changes nothing):
  `sddm-greeter-qt6 --test-mode --theme ./sddm/doorstep/doorstep`

## Deliver
`REVIEW.md` with the test command above, plus the install commands for later (needs sudo, owner only):
`sudo cp -r sddm/doorstep/doorstep /usr/share/sddm/themes/` and `/etc/sddm.conf.d/20-theme.conf` with `[Theme] Current=doorstep`; undo: delete both. Note: the existing `/etc/sddm.conf.d/10-wayland.conf` must stay untouched.
