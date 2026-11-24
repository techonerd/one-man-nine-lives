# Catnap Parts Art Contract (Plasma 6 Wallpaper)

This document specifies the modular vector art contract for Casper asleep on the lock screen, used by `catnap/contents/ui/main.qml` in `look-and-feel/one-man-nine-lives/catnap/` (`com.github.techonerd.catnap`).

All vector assets are generated deterministically by `look-and-feel/one-man-nine-lives/tools/generate_lockscreen_art.py`.

## Palette Rules (Tabby & Tweed Casper Mono)
- **Casper Coat**: Off-white `#F5F5F5` (MONO dark coat; never `#FFFFFF`).
- **Dark Mode Silhouette**: Casper has no stroke (`outline="none"`), subtle floor drop shadow `rgba(0, 0, 0, 0.45)`, detail facial color `#222222`.
- **Inner Ears**: Soft translucent tint `rgba(0, 0, 0, 0.08)`.
- **Background**: Vertical gradient from `#0E0E0E` (top) to `#161616` (bottom), crossed by a soft diagonal ambient light beam from `#FFFFFF` (opacity 0.04 fading to 0).
- **Calm Dream**: Eyes closed smiling, ears and whiskers still, no "Zzz" text.

---

## Scene & Coordinate System

- **Scene Dimensions**: 2560 × 1600 px (`Parts.sceneW`, `Parts.sceneH`).
- **Cat Position**: Lower-right corner at `CAT_X = 1800`, `CAT_Y = 1150`, leaving the central lock screen clock, password field, and session controls clear.
- **Cat Scale**: `CAT_SCALE = 2.4` applied to the master 256 × 140 cat art unit space.
- **Scene Pixel Formula**:
  - `sceneX = CAT_X + catX * CAT_SCALE`
  - `sceneY = CAT_Y + catY * CAT_SCALE`

---

## Parts Specification Table

| Filename | Canvas / Artboard | Scene Size (w × h) | Scene Position (x, y) | Scene Pivot (pivotX, pivotY) | Description |
|---|---|---|---|---|---|
| `background.svg` | 2560 × 1600 px | 2560 × 1600 px | `(0, 0)` | — | Dark mono lock screen background with ambient light beam. Rendered at quarter-resolution (`sourceSize = screen ÷ 4`). |
| `body.svg` | 164 × 96 px | 393.6 × 230.4 px | `(1910.4, 1222.0)` | `(2107.2, 1433.2)` | Torso bean arch, resting tucked paws, and floor shadow. Pivot is the middle of the floor contact line (cat `(128, 118)`). Scales vertically by +2.5% during breathing. |
| `head.svg` | 66 × 76 px | 158.4 × 182.4 px | `(1905.6, 1217.2)` | `(2028.0, 1380.4)` | Rounded head, notched ears, smiling sleeping eyes, nose, and whiskers. Pivot is the neck (cat `(95, 96)`). Follows body breathing rise by 60% with a 150 ms lag. |
| `tail-base.svg` | 56 × 22 px | 134.4 × 52.8 px | `(2184.0, 1320.4)` | `(2217.6, 1356.4)` | Base tail segment emerging from behind the lower body. Overlaps ~2 art units past Joint 1. Pivot is where it joins the body (cat `(174.0, 86.0)`). Turns up to 3° during tail flicks. |
| `tail-mid.svg` | 44 × 30 px | 105.6 × 72.0 px | `(2229.6, 1282.0)` | `(2273.76, 1337.44)` | Middle tail segment. Overlaps ~2 art units before Joint 1 and ~2 art units past Joint 2. Pivot is Joint 1 (cat `(197.4, 78.1)`). Turns up to 6° during tail flicks (120 ms stagger). |
| `tail-tip.svg` | 42 × 33 px | 100.8 × 79.2 px | `(2234.4, 1229.2)` | `(2292.24, 1295.2)` | Curled tail tip. Overlaps ~2 art units before Joint 2. Pivot is Joint 2 (cat `(205.1, 60.5)`). Turns up to 10° during tail flicks (240 ms stagger). |

---

## Joint and Rotation Geometry

1. **Seamless Overlapping Caps with Joint Overlap**:
   - Each tail segment overlaps into the next by ~2 art units (nearly 5 scene pixels each, resulting in ~4 art units / 10 scene pixels of total mutual overlap at every joint).
   - Joint 1 (between `tail-base` and `tail-mid`) is circular with radius `r = 15.5` cat units centered at cat `(197.4, 78.1)`.
   - Joint 2 (between `tail-mid` and `tail-tip`) is circular with radius `r = 13.5–13.8` cat units centered at cat `(205.1, 60.5)`.
   - Both joints use concentric circular arcs centered precisely at the rotation pivots. Because Casper's coat is solid `#F5F5F5` without outlines, overlapping segments render completely seamless solid white with zero subpixel antialiasing gaps or dark bars at rest, and zero seam opening when rotated up to 3°, 6°, 10°.
2. **Rest Alignment (0° Flick, 1.0 Breath)**:
   - When all rotation angles are 0° and scale is 1.0, the union of the 5 vector parts reproduces the canonical sleeping Casper drawing.
3. **Breathing Mechanics**:
   - `body.svg` scales vertically from its floor line pivot `(2107.2, 1433.2)`. Because the pivot is along the bottom floor contact line, the floor line remains stationary while the back arches up by 2.5% (approx 5.3 px at 2560×1600).
   - `head.svg` translates vertically by 60% of the body's rise with a 150 ms phase offset.

---

## QML Integration (`parts.js`)

The generator writes `catnap/contents/ui/parts.js` (`.pragma library`). `main.qml` imports it:

```qml
import "parts.js" as Parts
```

Each part exports `{ x, y, w, h, pivotX, pivotY }` in scene pixels. For any item positioned at `(Parts.<name>.x, Parts.<name>.y)`:
- Local pivot X = `Parts.<name>.pivotX - Parts.<name>.x`
- Local pivot Y = `Parts.<name>.pivotY - Parts.<name>.y`
- Base scene scale = `root.width / Parts.sceneW`
