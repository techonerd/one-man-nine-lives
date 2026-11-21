# Agent tasks

Task briefs for AI agents (Antigravity, VS Code agents, Claude). **One task per agent conversation.** Paste the task file's contents (or point the agent at it) and let it work only inside this repository. `AGENTS.md` (repo root) applies to every task.

## Ground rules for every task
- **Build and test, never install.** No `sudo`, no `kpackagetool6 -i` into your real profile, no `plasma-apply-*`, no `systemctl`, no copying into `~/.local/share` or `/usr`. All testing happens with files inside the repo or in a temporary directory.
- **No commits.** Leave changes in the working tree; the owner reviews with `git diff` and commits.
- **Generated, original artwork.** Draw with code: SVG written by a `tools/generate.py` in the component's folder, rendered with ImageMagick. Colours come only from `color-scheme/tabby-and-tweed/tools/generate.py` (import `LIGHT` / `DARK`). AI-generated images may be used as *mood references in the conversation*, never committed as artwork.
- **Light and dark.** Follow the system colour scheme where Plasma allows it; ship Light + Dark variants where it doesn't.
- **Finish with `REVIEW.md`** in the component folder: what was built, how it was tested (exact commands and results), preview images to look at, open questions, and the exact commands the owner should run to install/try/undo.

## Order (each one stands alone)
| # | Task | Folder | Risk |
|---|---|---|---|
| 1 | [Name Tag](name-tag.md): window-title widget | `widgets/name-tag/` | low |
| 2 | [Window Perch](window-perch.md): window decoration | `window-decoration/window-perch/` | low |
| 3 | [Night Shift](night-shift.md): Plasma style + Konsole colours | `plasma-style/night-shift/` | low |
| 4 | [Sunbeam](sunbeam.md): day/night wallpapers | `wallpapers/sunbeam/` | low |
| 5 | [Laser Pointer](laser-pointer.md): cursors | `cursors/laser-pointer/` | low |
| 6 | [Thumbs & Paws, redesign](thumbs-and-paws.md): "cat that won't let you work" icon set | `icons/thumbs-and-paws/` | low |
| 7 | [Doorstep](doorstep.md): SDDM login screen | `sddm/doorstep/` | medium: owner tests in a window first |
| 8 | [Catnap](catnap.md): lock screen | `look-and-feel/one-man-nine-lives/` | **high**: a broken lock screen can lock you out; owner tests only in a window |

## Safe test tools on this machine
| Need | Command (nothing gets installed) |
|---|---|
| Lint QML | `/usr/lib/qt6/bin/qmllint -I /usr/lib/x86_64-linux-gnu/qt6/qml <files>` ("unqualified" warnings for `i18n`/`root` are expected) |
| Render SVG → PNG | `magick -background none -density 300 in.svg -resize 256x256 out.png` |
| Contact sheets | `magick montage ... -background '#eff0f1'` (light) and `'#202326'` (dark) |
| Validate JSON / desktop files | `python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' file`, `desktop-file-validate file` |
| Build archives | `./build.sh` |
