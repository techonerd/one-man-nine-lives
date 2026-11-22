# One Man Nine Lives Suite Installer Review (Item 7)

## Overview
Root-level installation (`install.sh`) and uninstallation (`uninstall.sh`) scripts for the One Man Nine Lives KDE Plasma 6 suite:
- **Clean Override**: Deletes any existing installed copies first, copies fresh versions, and registers all installed paths in `~/.local/state/one-man-nine-lives/manifest`.
- **Previous Settings Preservation**: Automatically records the user's active desktop settings in `~/.local/state/one-man-nine-lives/previous.ini` before making any modifications. Never overwrites an existing `previous.ini` on subsequent runs or upgrades.
- **Cache Invalidation**: Clears `ksvg`, `plasma-svgelements*`, `plasma_theme*`, and icon caches (`icon-cache.kcache`, `ksycoca6*`), invoking `kbuildsycoca6` when available.
- **User Paths Only**: Strictly installs to user directories (`~/.local/share`, `~/.local/bin`, `~/.config/systemd/user`, `~/.local/state`). Never requires `sudo` or modifies system files.
- **Commands-Only for Doorstep & Catnap**:
  - Doorstep (SDDM login theme) requires system root permissions (`/usr/share/sddm/themes/`, `/etc/sddm.conf.d/`) and is printed as commands only with window-preview instructions.
  - Catnap (lock screen) carries high lockout risk and is excluded from automatic global theme installation by default; safe window-testing and manual installation commands are printed instead.
- **Clean Uninstall**: `uninstall.sh` removes only manifest-tracked paths, restores previous settings from `previous.ini`, cleans caches, and prunes any empty parent directories left behind.

---

## Component Manifest & Target Paths

All components are installed to standard user directories and tracked in `~/.local/state/one-man-nine-lives/manifest`:

| Component | Type | Installed Path |
|---|---|---|
| **Tabby & Tweed** | Colour Schemes | `~/.local/share/color-schemes/TabbyAndTweedLight.colors`<br>`~/.local/share/color-schemes/TabbyAndTweedDark.colors` |
| **Thumbs & Paws** | Icon Theme | `~/.local/share/icons/thumbs-and-paws/` |
| **Morning Stretch** | Splash Screen | `~/.local/share/plasma/look-and-feel/com.github.techonerd.morningstretch/` |
| **One Man Nine Lives** | Global Themes | `~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.light/`<br>`~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.dark/` |
| **Night Shift** | Desktop Style | `~/.local/share/plasma/desktoptheme/night-shift/` |
| **Night Shift** | Konsole Themes & Profiles | `~/.local/share/konsole/NightShiftLight.colorscheme`<br>`~/.local/share/konsole/NightShiftDark.colorscheme`<br>`~/.local/share/konsole/Night Shift Light.profile`<br>`~/.local/share/konsole/Night Shift Dark.profile` |
| **Window Perch** | Aurorae Decoration | `~/.local/share/aurorae/themes/WindowPerch/` |
| **Name Tag** | Plasma 6 Widget | `~/.local/share/plasma/plasmoids/com.github.techonerd.nametag/` |
| **Lap Time** | Plasma 6 Widget | `~/.local/share/plasma/plasmoids/com.github.techonerd.laptime/` |
| **Whiskers** | Plasma 6 Widget | `~/.local/share/plasma/plasmoids/com.github.techonerd.whiskers/` |
| **Whiskers** | CLI Tool & Libs | `~/.local/bin/whiskers`<br>`~/.local/share/whiskers/`<br>`~/.local/share/applications/whiskers.desktop`<br>`~/.local/share/icons/hicolor/scalable/apps/whiskers*.svg` |
| **Whiskers** | Systemd User Units | `~/.config/systemd/user/whiskers.service`<br>`~/.config/systemd/user/whiskers.timer`<br>`~/.config/systemd/user/whiskers-watch.service` |

---

## State and Settings Tracking

### 1. `previous.ini` Format
Recorded in `${XDG_STATE_HOME:-$HOME/.local/state}/one-man-nine-lives/previous.ini`:
```ini
[Meta]
kdeglobals_existed=true
plasmarc_existed=true
kwinrc_existed=true
ksplashrc_existed=true

[KDE]
LookAndFeelPackage=org.kde.breeze.desktop
AutomaticLookAndFeel=false
DefaultLightLookAndFeel=
DefaultDarkLookAndFeel=

[General]
ColorScheme=BreezeLight

[Icons]
Theme=breeze

[PlasmaTheme]
name=default

[WindowDecoration]
library=org.kde.breeze
theme=Breeze

[KSplash]
Theme=org.kde.breeze.desktop
Engine=KSplashQML
```

### 2. Restoration Logic in `uninstall.sh`
When `uninstall.sh` executes:
1. Manifest-tracked paths are read in reverse order and removed (`rm -rf` for dirs, `rm -f` for files).
2. If `previous.ini` exists, settings for LookAndFeel, Auto mode, ColorScheme, Icons, Plasma theme, Window Decoration, and Splash Screen are restored to their saved values.
3. If any configuration file (`kdeglobals`, `plasmarc`, `kwinrc`, `ksplashrc`) did not exist before install (`_existed=false`), it is cleanly deleted rather than leaving orphan configs.
4. Caches (`ksvg`, `plasma-svgelements*`, `plasma_theme*`, `icon-cache.kcache`, `ksycoca6*`) are invalidated and removed.
5. `manifest` and `previous.ini` are removed. Empty parent directories are recursively pruned up to `$HOME`.

---

## Verification & Test Results

### Test 1: Fake HOME Clean Installation and Removal
```bash
FAKE=$(mktemp -d)
HOME=$FAKE ./install.sh >/dev/null
echo "Manifest entries: $(wc -l < "$FAKE/.local/state/one-man-nine-lives/manifest")"
HOME=$FAKE ./uninstall.sh >/dev/null
remaining=$(find "$FAKE" -mindepth 1)
[[ -z "$remaining" ]] && echo "SUCCESS: fake HOME is completely clean!"
rm -rf "$FAKE"
```
**Result:**
```
Manifest entries: 23
SUCCESS: fake HOME is completely clean!
```

### Test 2: Clean Override & Previous Settings Preservation
Verifies that:
- Running `install.sh` a second time preserves original `previous.ini` without overwriting.
- Modified/existing installed files are deleted first and cleanly overridden with fresh repository files.
```bash
FAKE=$(mktemp -d)
HOME=$FAKE ./install.sh >/dev/null
orig_ini=$(cat "$FAKE/.local/state/one-man-nine-lives/previous.ini")
echo "# modified" >> "$FAKE/.local/share/color-schemes/TabbyAndTweedLight.colors"

HOME=$FAKE ./install.sh >/dev/null
new_ini=$(cat "$FAKE/.local/state/one-man-nine-lives/previous.ini")

[[ "$orig_ini" == "$new_ini" ]] && echo "SUCCESS: previous.ini preserved across repeated installs!"
grep -q "# modified" "$FAKE/.local/share/color-schemes/TabbyAndTweedLight.colors" || echo "SUCCESS: Clean override deleted previous file and copied fresh!"

HOME=$FAKE ./uninstall.sh >/dev/null
[[ -z "$(find "$FAKE" -mindepth 1)" ]] && echo "SUCCESS: fake HOME completely clean!"
rm -rf "$FAKE"
```
**Result:**
```
SUCCESS: previous.ini preserved across repeated installs!
SUCCESS: Clean override deleted previous file and copied fresh!
SUCCESS: fake HOME completely clean!
```

### Test 3: Setting Application and Restoration
Verifies that:
- Pre-existing settings (`BreezeLight`, `org.kde.breeze.desktop`) are captured.
- `--apply dark --auto` updates settings to `TabbyAndTweedDark` and `com.github.techonerd.onemanninelives.dark`.
- `uninstall.sh` restores pre-existing settings exactly.
```bash
FAKE=$(mktemp -d)
mkdir -p "$FAKE/.config"
cat > "$FAKE/.config/kdeglobals" <<EOF
[General]
ColorScheme=BreezeLight

[KDE]
AutomaticLookAndFeel=false
LookAndFeelPackage=org.kde.breeze.desktop
EOF

HOME=$FAKE ./install.sh --apply dark --auto >/dev/null
HOME=$FAKE ./uninstall.sh >/dev/null

scheme=$(kreadconfig6 --file "$FAKE/.config/kdeglobals" --group General --key ColorScheme 2>/dev/null)
pkg=$(kreadconfig6 --file "$FAKE/.config/kdeglobals" --group KDE --key LookAndFeelPackage 2>/dev/null)

[[ "$scheme" == "BreezeLight" && "$pkg" == "org.kde.breeze.desktop" ]] && echo "SUCCESS: Prior settings correctly restored!"
rm -rf "$FAKE"
```
**Result:**
```
SUCCESS: Prior settings correctly restored!
```

---

## Commands for Owner

### Try / Install (User-level, safe):
```bash
# Install all components (choose theme in System Settings > Global Theme):
./install.sh

# Or install and apply Dark theme immediately:
./install.sh --apply dark

# Or install and enable automatic Light/Dark switching:
./install.sh --apply dark --auto
```

### Doorstep SDDM Login Theme (Commands only, owner runs):
```bash
# Preview safely in a window without installing:
sddm-greeter-qt6 --test-mode --theme ./sddm/doorstep/doorstep

# Install system-wide (requires sudo):
sudo cp -r sddm/doorstep/doorstep /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d && echo -e "[Theme]\nCurrent=doorstep" | sudo tee /etc/sddm.conf.d/20-theme.conf

# Uninstall / Rollback:
sudo rm -rf /usr/share/sddm/themes/doorstep /etc/sddm.conf.d/20-theme.conf
```

### Catnap Lock Screen (Commands only, owner runs):
```bash
# Test safely in a window without locking system:
./look-and-feel/one-man-nine-lives/test-lockscreen.sh         # dark
./look-and-feel/one-man-nine-lives/test-lockscreen.sh light   # light

# Optional: Install directly into user global theme after testing:
cp -r look-and-feel/one-man-nine-lives/dark/contents/lockscreen ~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.dark/contents/
cp -r look-and-feel/one-man-nine-lives/light/contents/lockscreen ~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.light/contents/

# Rollback:
rm -rf ~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.*/contents/lockscreen
```

### Complete Uninstall / Rollback:
```bash
./uninstall.sh
```
Restores previous settings from `previous.ini`, removes all 23 manifest-installed files/directories, and cleans SVG/icon caches.
