# Task: Thumbs & Paws, round 2 (more icons)

Read `AGENTS.md`, `tasks/README.md`, `icons/thumbs-and-paws/README.md`. Extend `tools/generate.py`; never hand-copy icons from other themes.

## Build
- **Places:** `folder-git`, `folder-development`, `folder-network`, `folder-cloud`, `folder-templates`, `folder-public`, `folder-locked`, `folder-temp`, `drive-harddisk`, `drive-removable-media`, `network-workgroup`.
- **Symbolic (monochrome, `ColorScheme-Text` class, 16 px grid):** `folder-symbolic`, `user-home-symbolic`, `user-trash-symbolic`, `system-search-symbolic`, plus a `whiskers-symbolic` matching the widget icon.
- **Apps (full colour):** `utilities-terminal` (a terminal with a cat-ear prompt), `system-file-manager`, `preferences-system`, `org.kde.konsole`, `org.kde.dolphin`, `org.kde.systemsettings` (alias the KDE ids to the generic ones).
- Add the needed `Directories=` sections to `index.theme` (scalable + `symbolic`).
- Hand-check legibility at 16 and 22 px; simplify emblems for small sizes if needed (separate 16 px variants allowed).

## Test (no install)
- `tools/preview.sh` → `preview.png` on light and dark; small-size row must be readable.

## Deliver
`REVIEW.md` listing every new icon name and the preview to review.
