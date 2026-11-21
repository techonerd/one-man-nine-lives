# One Man Nine Lives: workspace rule

Before any work in this repository, read and follow `AGENTS.md` (repository root) and `tasks/README.md`.

Short version of the hard rules:
- Build and test inside this repository or a temporary directory only. Never install, never run `sudo`, `kpackagetool6 -i`, `plasma-apply-*`, `systemctl`, or copy anything into `~/.local/share`, `~/.config` or `/usr`.
- Never commit or push; the owner reviews with `git diff`.
- Plasma 6 public APIs only; follow the system light/dark theme; colours only from `color-scheme/tabby-and-tweed/tools/generate.py`.
- Original artwork drawn by code (`tools/generate.py` per component). AI-generated images are mood references in the conversation, never committed.
- Every task ends with a `REVIEW.md` in the component folder: what was built, exact test commands and results, previews to look at, and the owner's install/undo commands.
- Show a plan (or a concept sheet for artwork) and wait for approval before large changes.
