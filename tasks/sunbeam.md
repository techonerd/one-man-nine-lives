# Task: Sunbeam (day/night wallpapers)

*Morning light / the warm spot on the floor.* Read `AGENTS.md`, `tasks/README.md`, `wallpapers/sunbeam/README.md`.

## Build
- An original, minimal, vector-style scene: a sunbeam crossing a wooden floor with a sleeping cat silhouette in the warm spot; night version with moonlight and the cat curled up. Drawn by `wallpapers/sunbeam/tools/generate.py` (SVG → PNG), palette from Tabby & Tweed.
- A Plasma 6 wallpaper package `wallpapers/sunbeam/Sunbeam/` with `metadata.json`, `contents/images/` (day) and `contents/images_dark/` (night), so Plasma swaps them with light/dark automatically.
- Sizes: 1920x1080, 1920x1200 (16:10, the owner's laptop), 2560x1600, 3840x2160. Keep files small (PNG/JPEG, no huge noise).
- Also export a 1920x1080 `doorstep-background.jpg` for the login screen task.

## Test (no install)
- `preview.png`: day and night side by side; check at 16:10 and 16:9.
- Check the cat stays clear of where desktop icons and the panel usually sit (left column, bottom 60 px).

## Deliver
`REVIEW.md` with: `cp -r wallpapers/sunbeam/Sunbeam ~/.local/share/wallpapers/` then pick it in Desktop → Configure; undo by deleting the folder.
