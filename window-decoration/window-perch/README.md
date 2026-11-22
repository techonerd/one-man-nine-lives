# Window Perch (window decoration)

*Windows on the screen / the favourite windowsill.*

The KWin window decoration of the One Man Nine Lives suite. It is the **Breeze** decoration with
one change: the title-bar buttons are cat heads. At rest each button is a soft cat silhouette; on
hover it fills in and its "eyes" show what it does:

| Button | Eyes |
|---|---|
| Minimise | `- -` |
| Maximise | `o o` |
| Restore | `^ ^` |
| Close | `x x` (red head) |
| Keep above / below | `^ ^` raised / `v v` |
| Shade | `= =` |
| On all desktops | `. .` (big eyes when pinned) |

Everything else is Breeze: colours follow your colour scheme live (light and dark), the shadow,
border sizes, button sizes and the settings page (System Settings → Window Decorations →
Window Perch → configure).

## Build and install (needs root, like any KWin plugin)
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF
cmake --build build -j"$(nproc)"
sudo cmake --install build
qdbus6 org.kde.KWin /KWin reconfigure
```
Then pick **Window Perch** in System Settings → Window Decorations (the global theme does this for you).

Undo: pick Breeze, then `sudo xargs rm < build/install_manifest.txt`.

Rebuild after every KWin/KDecoration upgrade (`sudo apt upgrade` that updates kwin): a plugin built
against an older KDecoration can fail to load, and KWin then falls back to its default decoration.

## Attribution
Window Perch is a fork of the **Breeze window decoration** from KDE Plasma 6.7.4
(<https://invent.kde.org/plasma/breeze>, `kdecoration/` and `libbreezecommon/`).
Original copyright: Hugo Pereira Da Costa, Martin Gräßlin, Lubos Lunak, Vlad Zahorodnii,
Paul McAuley and the KDE contributors (see the SPDX headers in each file).

Changes for One Man Nine Lives (techonerd): renamed plugin, namespace, config file
(`windowperchrc`) and settings module so it installs next to Breeze; cat-head buttons with
hover-only "eyes" in `src/kdecoration/breezebutton.cpp`.

Licence: the forked files keep their original licences (GPL-2.0-or-later, GPL-2.0-only OR
GPL-3.0-only, MIT); the combined work is distributed under GPL-3.0-or-later.
