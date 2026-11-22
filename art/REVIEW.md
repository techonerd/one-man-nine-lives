# Casper Art Library – Phase 1 Review

## What was built
`art/casper.py` — the shared Casper parts library. Every component's `tools/generate.py` imports it, so the cat is drawn one way everywhere.

### Poses (8 total)
| Pose | Description | Function |
|---|---|---|
| **loaf** | Compact rounded body, tucked paws, alert ears, tail curling out | `loaf(x, y, size, pal)` |
| **stretch** | Long body, front paws extended, back arched, beans visible | `stretch(x, y, size, pal)` |
| **curl** | Curled asleep, circular, tail wrapping around, eyes closed | `curl(x, y, size, pal)` |
| **sit** | Upright formal pose, tail curled beside | `sit(x, y, size, pal)` |
| **peek** | Ears and eyes over an edge, paws gripping | `peek(x, y, size, pal)` |
| **paw** | Single paw pad with 4 toe beans (suite signature) | `paw(x, y, size, pal)` |
| **tail** | Sweeping S-curve tail | `tail(x, y, size, pal)` |
| **paw_print** | Paw print stamp (logo mark) | `paw_print(x, y, size, pal)` |

### Design rules followed
- Every colour comes from `color-scheme/tabby-and-tweed/tools/generate.py` (CASPER_LIGHT, CASPER_DARK, MONO_LIGHT, MONO_DARK)
- **Light mode**: off-white Casper (#F5F5F5) with near-black outline (#121212, ≥3:1 against light backgrounds), soft shadow
- **Dark mode**: off-white Casper, no outline, faint shadow
- 64-unit canvas, functions take `(x, y, size, palette)` and return SVG strings
- All shared helper parts: ears, inner ears, eyes, nose, whiskers, paw beans

### Model sheet
`art/preview.png` (2228×896 px) — every pose at 256px and 64px, on `#F0F0F0` (light) and `#0E0E0E` (dark).

## Commands run
```
$ python3 -I art/casper.py
wrote /home/techonerd/one-man-nine-lives/art/preview.png

$ magick identify art/preview.png
art/preview.png PNG 2228x896 2228x896+0+0 16-bit sRGB 231619B
```

## Preview
- [art/preview.png](../art/preview.png) — the model sheet

## Usage by other components
```python
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent.parent / "art"))
from casper import loaf, sit, curl, paw_print, ALL_POSES

svg_fragment = sit(100, 200, 128, palette_dict)
```

## Open questions
1. **Ear shape**: currently triangular with a slight curve (Q bezier). Should they be pointier or rounder?
2. **Eye style**: round with slit pupil. Should the pupil be wider/narrower?
3. **Whisker count**: 3 per side. Acceptable?
4. **Bean visibility at small sizes**: at 64px the toe beans on some poses are very small. Should the paw pose be used only at ≥128px?
5. **Tail thickness**: currently 3–4 units. Good?

## Licence
- SPDX-License-Identifier: GPL-3.0-or-later (code)
- SPDX-FileCopyrightText: techonerd
