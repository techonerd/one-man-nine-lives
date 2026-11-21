# One Man Nine Lives

A KDE Plasma 6 suite made by one man and his cat, Casper. Every piece is named half for the human and half for the cat. Everything follows your light or dark theme.

## The suite
| Component | Name | Human side | Cat side | Folder | KDE Store category | Status |
|---|---|---|---|---|---|---|
| Global theme | **One Man Nine Lives** | one man | nine lives | [`look-and-feel/one-man-nine-lives`](look-and-feel/one-man-nine-lives) | Plasma 6 Global Themes | ✅ ready (Light + Dark) |
| Lock screen | **Catnap** | a quick nap at the desk | the 16th nap of the day | inside the global theme | – | planned |
| Splash screen | **Morning Stretch** | waking up | the first big stretch | [`splash/morning-stretch`](splash/morning-stretch) | Plasma 6 Splashscreens | ✅ ready |
| System watch | **Whiskers** | the beard you forgot to trim | senses trouble before it lands | [`whiskers`](whiskers) | Plasma 6 Widgets + CLI | ✅ ready |
| Colour schemes | **Tabby & Tweed** (Light + Dark) | a tweed jacket | a tabby coat | [`color-scheme/tabby-and-tweed`](color-scheme/tabby-and-tweed) | Plasma 6 Color Schemes | ✅ ready |
| Icons | **Thumbs & Paws** | thumbs | paws | [`icons/thumbs-and-paws`](icons/thumbs-and-paws) | Full Icon Themes | 🚧 started (11 icons) |
| Login screen (SDDM) | **Doorstep** | coming home | waiting at the door | [`sddm/doorstep`](sddm/doorstep) | Plasma 6 SDDM Login Themes | planned |
| Plasma style + Konsole | **Night Shift** | late-night work | a nocturnal hunter | [`plasma-style/night-shift`](plasma-style/night-shift) | Plasma 6 Themes | planned |
| Window decoration | **Window Perch** | windows on the screen | the favourite windowsill | [`window-decoration/window-perch`](window-decoration/window-perch) | Plasma 6 Window Decorations | planned |
| Cursors | **Laser Pointer** | the hand holding it | the cat chasing it | [`cursors/laser-pointer`](cursors/laser-pointer) | Cursors | planned |
| Wallpapers | **Sunbeam** (day + night) | morning light | the warm spot on the floor | [`wallpapers/sunbeam`](wallpapers/sunbeam) | Plasma 6 Wallpapers | planned |
| Window title widget | **Name Tag** | a name badge | a collar tag | [`widgets/name-tag`](widgets/name-tag) | Plasma 6 Widgets | planned |
| Sound theme | **Purr & Ping** | a ping | a purr | [`sounds/purr-and-ping`](sounds/purr-and-ping) | Sound themes | idea |

Each component is published on its own in its KDE Store category. The global theme then ties them together and switches between light and dark with the system.

## Using each part
Nothing needs sudo except Doorstep (the login screen), which is installed system-wide.

| Part | Try it | Remove it |
|---|---|---|
| **Everything at once** | `./look-and-feel/one-man-nine-lives/install.sh --apply dark --auto` (colours, icons, splash, both global themes; Light/Dark switch automatically) | `./look-and-feel/one-man-nine-lives/uninstall.sh --all` (restores your previous theme) |
| Morning Stretch | `kpackagetool6 -t Plasma/LookAndFeel -i splash/morning-stretch`, then System Settings → Splash Screen. Preview with `ksplashqml --test --window ./splash/morning-stretch` | `kpackagetool6 -t Plasma/LookAndFeel -r com.github.techonerd.morningstretch` |
| Whiskers | `./whiskers/install.sh`, then add the widget to a panel | `./whiskers/uninstall.sh` |
| Tabby & Tweed | `cp color-scheme/tabby-and-tweed/*.colors ~/.local/share/color-schemes/ && plasma-apply-colorscheme TabbyAndTweedDark` (or `TabbyAndTweedLight`) | `plasma-apply-colorscheme BreezeLight` and delete the two files |
| Thumbs & Paws | `cp -r icons/thumbs-and-paws ~/.local/share/icons/`, then System Settings → Icons | `rm -r ~/.local/share/icons/thumbs-and-paws` |

Details are in each folder's README.

## Repository layout
```
look-and-feel/one-man-nine-lives/   global themes Light + Dark (+ Catnap later)  ready
splash/morning-stretch/             splash screen                                ready
whiskers/                           system watch: CLI, plugins, live watch, widget  ready
color-scheme/tabby-and-tweed/       light + dark colour schemes + generator      ready
icons/thumbs-and-paws/              icon theme + generator                       started
sddm/doorstep/                      login screen                                 planned
plasma-style/night-shift/           Plasma style + Konsole colours               planned
window-decoration/window-perch/     Aurorae window decoration                    planned
cursors/laser-pointer/              cursor theme                                 planned
wallpapers/sunbeam/                 day/night wallpapers                         planned
widgets/name-tag/                   window title widget                          planned
sounds/purr-and-ping/               sound theme                                  idea
build.sh                            builds every finished component into dist/
AGENTS.md                           rules for AI agents and contributors
tasks/                              one brief per remaining component, for AI agents
```

## Build release archives
```bash
./build.sh      # dist/: one archive per finished component, ready for the KDE Store or GitHub releases
```

## Rules for every component
- Plasma 6 format only: `metadata.json`, Qt 6 / QML imports, no private Plasma modules.
- Configuration pages declare a `cfg_<key>` and a `cfg_<key>Default` for every key in `main.xml`.
- **Follow the system light/dark theme:** use Kirigami/Plasma theme colours and themed icons, `ColorScheme-Text` for monochrome art, and ship light and dark variants wherever a component can't follow automatically (cursors, wallpapers, global theme).
- Colours come from the Tabby & Tweed palette (`color-scheme/tabby-and-tweed/tools/generate.py`).
- Original work only. Generated artwork is produced by the `tools/` scripts in each folder.
- Ids follow `com.github.techonerd.<name>`; every component stays at 0.1.0 until the whole suite is finished and tested, then all become 1.0.0 together.

## License
GPL-3.0-or-later. All code and artwork are original work by techonerd.
