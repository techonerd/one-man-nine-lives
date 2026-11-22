# Task: Thumbs & Paws, redesign (cat that won't let you work)

Read `AGENTS.md`, `tasks/README.md`, `icons/thumbs-and-paws/README.md` first. This **replaces** the current 11 starter icons with a professional set built around one idea:

> **Every icon is a normal, instantly recognisable icon, plus one small cat interrupting your work.**
> The thing you need comes first; the cat is the wink.

## Design rules
1. **Metaphor first.** At a glance a folder must read as a folder, a trash can as a trash can. The cat never covers the part that identifies the icon (folder tab, emblem, arrow tip).
2. **One quirk per icon**, drawn from a small reusable **cat parts library** in `tools/generate.py`: ears, paw (pad + toe beans), tail curl, sleeping-curl silhouette, eyes, paw-print. The same parts everywhere, so the set looks designed, not random.
3. **Small sizes drop the cat.** At 16 and 22 px the quirk disappears or shrinks to a single detail (two ears or a paw tip). Generate separate `16/` and `22/` variants on the pixel grid, plus `scalable/` for 32 px and up.
4. **Clean geometry:** 64-unit canvas, 2-unit keyline grid, consistent corner radius, a single light source (soft top highlight, no gradients that look muddy on dark panels), no outlines thinner than 1 unit at 32 px.
5. **Palette only from Tabby & Tweed** plus the `CASPER_LIGHT` / `CASPER_DARK` dicts (see `tasks/media.md`): folder body amber, Casper black in the light theme and white in the dark theme, accent rose for inner ears and toe beans. Ship two themes, `thumbs-and-paws` and `thumbs-and-paws-dark`.
6. **Light and dark:** every full-colour icon must pass on `#eff0f1` and `#202326` (a dark rim where needed). Symbolic icons use the `ColorScheme-Text` class.

## Icon list and its quirk
| Icon | Quirk |
|---|---|
| `folder` | Cat loaf lying across the folder top, paws draped over the front |
| `folder-home` | Cat face in the house window |
| `folder-documents` | Cat asleep on the page, tail over the text lines |
| `folder-downloads` | Paw batting the download arrow sideways |
| `folder-pictures` | Paw-print smudge on the photo |
| `folder-music` | Cat ear sticking up between two notes |
| `folder-videos` | Cat silhouette sitting in front of the play screen |
| `folder-desktop` | Cat sitting on top of the monitor, tail hanging over the screen |
| `folder-favorites` | Paw print (the suite mark) |
| `folder-git` | Paw tangled in the branch lines |
| `folder-development` | Paw on the `</>` brackets |
| `folder-network`, `folder-cloud`, `folder-templates`, `folder-public`, `folder-locked`, `folder-temp` | Ears peeking over the tab (quiet variant) |
| `user-trash` | Cat sitting *inside* the empty bin |
| `user-trash-full` | Cat knocked a paper ball out of the full bin |
| `utilities-terminal` (+ aliases `org.kde.konsole`) | Paw on the keyboard; prompt shows `fffffff` |
| `system-file-manager` (+ `org.kde.dolphin`) | Cat curled in an open drawer |
| `preferences-system` (+ `org.kde.systemsettings`) | Paw batting the gear |
| `system-search` | Cat eye looking through the magnifier |
| `drive-harddisk`, `drive-removable-media` | Cat asleep on top, the warm spot |
| Symbolic set (`folder-symbolic`, `user-home-symbolic`, `user-trash-symbolic`, `system-search-symbolic`) | No cat; ears only on the folder |

## Process
1. **Concepts first (no code yet):** sketch each quirk in words, or use an AI image tool for mood boards *in the conversation only*. Show the owner a concept sheet and wait for approval before drawing.
2. **Draw in code:** reusable cat parts plus one function per icon in `tools/generate.py`, writing `scalable/`, `22/` and `16/` folders. Update `index.theme` directories accordingly.
3. **Review renders:** `tools/preview.sh` must output: full set at 96 px on light and dark; 22 px and 16 px rows on light and dark; a "desktop mock" with the icons on the Sunbeam wallpaper if available.
4. **Self-check before handing over:** every icon is still identifiable with the cat removed; nothing is blurry at 16 px; no icon is more than 25 % cat.

## Test (no install)
`python3 -I icons/thumbs-and-paws/tools/generate.py && icons/thumbs-and-paws/tools/preview.sh`, and look at `preview.png`.

## Deliver
`REVIEW.md` with the concept sheet, the final preview, and the try-out commands (`cp -r icons/thumbs-and-paws ~/.local/share/icons/`, pick it in System Settings → Icons; undo by deleting the folder).
