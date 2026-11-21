# Task: Catnap (lock screen)

*A quick nap at the desk / the sixteenth nap of the day.* Read `AGENTS.md`, `tasks/README.md`. **High risk:** a broken lock screen can lock the owner out. Do not run any lock-screen binary; build and lint only.

## Build
- `contents/lockscreen/` inside **both** `look-and-feel/one-man-nine-lives/light/` and `dark/` (or generated into both by `look-and-feel/one-man-nine-lives/tools/generate.py`). Start from the structure the Plasma 6 lock screen expects (`LockScreen.qml` / `LockScreenUi.qml` entry points; study `/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/lockscreen/` for the **interface only**: required ids, properties and signals. Do not copy its code or artwork).
- Must keep every safety feature: password field always reachable, keyboard layout switch, virtual keyboard, switch user, media controls optional, **no Hibernate button**.
- Look: dimmed Sunbeam night wallpaper, a sleeping cat line-art above the clock, Tabby & Tweed colours.

## Test (no install)
- `qmllint` every file; document every interface item checked against Breeze in `REVIEW.md`.
- Do **not** run `kscreenlocker_greet`.

## Deliver
`REVIEW.md` with the owner's **safe** test: `/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing` *after* installing the global theme to a test user or with a second TTY logged in (Ctrl+Alt+F3) as an escape hatch; and the rollback: re-run `look-and-feel/one-man-nine-lives/install.sh` from a version without `lockscreen/`, or switch the global theme back.
