# Task: Name Tag (window title widget)

*A name badge / a collar tag.* Read `AGENTS.md`, `tasks/README.md` and `widgets/name-tag/README.md` first.

## Build
A Plasma 6 panel widget, `widgets/name-tag/` (`Plasma/Applet`, Id `com.github.techonerd.nametag`, version 1.0.0), that shows the **active window's icon and title**.
- Public APIs only: `org.kde.taskmanager` (`TasksModel` filtered to the active task + `VirtualDesktopInfo`/`ActivityInfo`). **No** `org.kde.plasma.private.*` (that's why the old *Window Title* widget broke).
- Options (config page with `cfg_<key>` **and** `cfg_<key>Default` for every key in `main.xml`): show icon / title / both; maximum width; bold title; text when no window is active (default: activity name, or "Desktop").
- Works in horizontal and vertical panels; elides long titles; follows the colour scheme (Kirigami/Plasma theme colours only).
- Icon: a small collar-tag symbolic SVG using the `ColorScheme-Text` class, in `contents/icons/`.

## Test (no install)
- `qmllint` clean apart from the expected unqualified `i18n`/`root` warnings.
- `python3 -I -c 'import json; json.load(open("widgets/name-tag/metadata.json"))'`.
- Add a `build.sh` step producing `dist/name-tag-1.0.0.plasmoid`.

## Deliver
`REVIEW.md` with the owner's try-out commands:
`kpackagetool6 -t Plasma/Applet -i widgets/name-tag` → add to panel → remove the old broken one with `kpackagetool6 -t Plasma/Applet -r org.kde.windowtitle`; undo: `kpackagetool6 -t Plasma/Applet -r com.github.techonerd.nametag`.
