# Tabby & Tweed – Review

## What changed
- Switched Tabby & Tweed palette to soft, neutral greys:
  - Dark: background `~#141414`/`#1C1C1C`, text `#E6E6E6`, muted text `#A0A0A0`
  - Light: background `~#F7F7F7`, text `#1C1C1C` (`~#1A1A1A`), muted text `#666666`
  - Amber accent: `#964C12` (light) and `#E8A256` (dark) for selection and focus
  - Standard semantic colours: negative (`#A83434` / `#F0807A`), neutral (`#8F560B` / `#F0B35B`), positive (`#2D6E46` / `#73C694`)
- Standardized all palette keys to strict `snake_case` (removed hyphenated keys from `CASPER_*` and `MONO_*`).
- Regenerated `TabbyAndTweedLight.colors`, `TabbyAndTweedDark.colors`, and `preview.png`.
- Added ceiling check to verify text contrast passes WCAG AA (≥ 4.5:1) while staying under ~16:1.

## Palette summary

| Token | Light | Dark |
|---|---|---|
| `view` (content) | `#F7F7F7` | `#141414` |
| `window` (frame) | `#EFEFEF` | `#1C1C1C` |
| `button` | `#E8E8E8` | `#242424` |
| `header` | `#E8E8E8` | `#1C1C1C` |
| `tooltip` | `#F7F7F7` | `#202020` |
| `text` | `#1C1C1C` | `#E6E6E6` |
| `inactive` (muted) | `#666666` | `#A0A0A0` |
| `selection` (accent) | `#964C12` | `#D98A3D` |
| `selection_text` | `#F7F7F7` | `#141414` |
| `accent` / `focus` | `#964C12` | `#E8A256` |
| `negative` | `#A83434` | `#F0807A` |
| `neutral` | `#8F560B` | `#F0B35B` |
| `positive` | `#2D6E46` | `#73C694` |
| `MONO_*.bg` | `#F7F7F7` | `#141414` |
| `MONO_*.fg` | `#1C1C1C` | `#E6E6E6` |
| `MONO_*.fg_muted` | `#666666` | `#A0A0A0` |
| `MONO_*.rim` | `rgba(0, 0, 0, 0.12)` | `rgba(255, 255, 255, 0.12)` |
| `MONO_*.overlay` | `rgba(247, 247, 247, 0.75)` | `rgba(20, 20, 20, 0.70)` |

## Real command output
```
$ python3 -I color-scheme/tabby-and-tweed/tools/generate.py
[Tabby & Tweed Light]
  on view    (#F7F7F7): text=15.91:1, inactive=5.36:1
  on window  (#EFEFEF): text=14.82:1, inactive=4.99:1
  on button  (#E8E8E8): text=13.91:1, inactive=4.69:1
  on header  (#E8E8E8): text=13.91:1, inactive=4.69:1
  on tooltip (#F7F7F7): text=15.91:1, inactive=5.36:1
  selection text (#F7F7F7) on selection (#964C12): 5.87:1
[Tabby & Tweed Dark]
  on view    (#141414): text=14.76:1, inactive=7.04:1
  on window  (#1C1C1C): text=13.65:1, inactive=6.52:1
  on button  (#242424): text=12.44:1, inactive=5.94:1
  on header  (#1C1C1C): text=13.65:1, inactive=6.52:1
  on tooltip (#202020): text=13.05:1, inactive=6.23:1
  selection text (#141414) on selection (#D98A3D): 6.71:1

wrote TabbyAndTweedLight.colors and TabbyAndTweedDark.colors
Text contrast range across all surfaces: 12.44:1 to 15.91:1 (WCAG AA >= 4.5:1, ceiling <= 16.5:1)
```

## Preview
- [preview.png](preview.png) — rendered mock windows in Tabby & Tweed Light and Dark

## Owner try / undo
```bash
# Try
cp color-scheme/tabby-and-tweed/*.colors ~/.local/share/color-schemes/
plasma-apply-colorscheme TabbyAndTweedDark   # or TabbyAndTweedLight

# Undo
plasma-apply-colorscheme BreezeLight
rm ~/.local/share/color-schemes/TabbyAndTweed*.colors
```
