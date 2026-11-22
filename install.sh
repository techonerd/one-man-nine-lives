#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
# Install One Man Nine Lives KDE Plasma 6 suite for the current user.
# User paths only. No sudo; nothing outside your home directory is touched.
#
# Usage:
#   ./install.sh [--dry-run] [--apply light|dark] [--auto] [--with-catnap] [component ...]
#
# Undo:
#   ./uninstall.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BIN_DIR="${HOME}/.local/bin"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/one-man-nine-lives"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
MANIFEST="${STATE_DIR}/manifest"
PREV_INI="${STATE_DIR}/previous.ini"

apply=""
auto=0
with_catnap=0
dry_run=0
selected_components=()

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [component ...]

Options:
  --dry-run             Show what would be installed/executed without writing files
  --apply <light|dark>  Install and apply theme variant immediately
  --auto                Enable automatic Light/Dark switching with time of day
  --with-catnap         Install Catnap lock screen directly into global theme
  -h, --help            Show this help message

Components:
  colors, icons, splash, themes, plasma-style, konsole, window-perch, widgets, whiskers

Note:
  With no component specified, every finished component is installed.
EOF
}

while (( $# )); do
  case $1 in
    --dry-run)
      dry_run=1 ;;
    --apply)
      apply=${2:-}
      [[ $apply == light || $apply == dark ]] || { echo "Error: --apply requires 'light' or 'dark'"; exit 1; }
      shift ;;
    --auto)
      auto=1 ;;
    --with-catnap)
      with_catnap=1 ;;
    -h|--help)
      usage; exit 0 ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1 ;;
    *)
      selected_components+=("$1") ;;
  esac
  shift
done

# Determine which components are active
install_colors=0
install_icons=0
install_splash=0
install_themes=0
install_plasma_style=0
install_konsole=0
install_window_perch=0
install_widgets=0
install_whiskers=0

if (( ${#selected_components[@]} == 0 )); then
  # Default: every finished component (the global theme references all of them)
  install_colors=1
  install_icons=1
  install_splash=1
  install_themes=1
  install_plasma_style=1
  install_konsole=1
  install_window_perch=1
  install_widgets=1
  install_whiskers=1
else
  for c in "${selected_components[@]}"; do
    case "$c" in
      colors|color-scheme|color-schemes|tabby-and-tweed)
        install_colors=1 ;;
      icons|thumbs-and-paws)
        install_icons=1 ;;
      splash|morning-stretch)
        install_splash=1 ;;
      themes|theme|global-theme|global-themes|look-and-feel)
        install_themes=1 ;;
      plasma-style|night-shift|desktoptheme)
        install_plasma_style=1 ;;
      konsole)
        install_konsole=1 ;;
      window-perch|aurorae|window-decoration)
        install_window_perch=1 ;;
      widgets|plasmoids|name-tag|lap-time)
        install_widgets=1 ;;
      whiskers)
        install_whiskers=1 ;;
      *)
        echo "Unknown component: $c" >&2
        usage >&2
        exit 1 ;;
    esac
  done
fi

if (( dry_run )); then
  echo "=== [DRY RUN] Installing One Man Nine Lives KDE Plasma 6 Suite ==="
else
  echo "=== Installing One Man Nine Lives KDE Plasma 6 Suite ==="
fi

# Clean override: Remove old hand-installed Night Shift files from user paths
echo "Cleaning old hand-installed copies..."
old_paths=(
  "${DATA_DIR}/konsole/Night Shift.profile"
  "${DATA_DIR}/aurorae/themes/WindowPerch"
  "${DATA_DIR}/aurorae/themes/WindowPerchLight"
  "${DATA_DIR}/aurorae/themes/WindowPerchDark"
  "${DATA_DIR}/konsole/Night Shift Light.profile"
  "${DATA_DIR}/konsole/Night Shift Dark.profile"
  "${DATA_DIR}/konsole/NightShiftLight.colorscheme"
  "${DATA_DIR}/konsole/NightShiftDark.colorscheme"
  "${DATA_DIR}/plasma/desktoptheme/night-shift"
)
for old_p in "${old_paths[@]}"; do
  if [[ -e "$old_p" ]]; then
    if (( dry_run )); then
      echo "  [dry-run] Would remove old: $old_p"
    else
      rm -rf "$old_p"
    fi
  fi
done

# Record previous settings before touching configuration (never overwrite existing)
if (( ! dry_run )); then
  mkdir -p "$STATE_DIR"
  if [[ ! -f "$PREV_INI" ]]; then
    echo "Recording previous settings in $PREV_INI..."

    cfg_kde_existed=false
    cfg_plasma_existed=false
    cfg_kwin_existed=false
    cfg_ksplash_existed=false
    [[ -f "${CONFIG_DIR}/kdeglobals" ]] && cfg_kde_existed=true
    [[ -f "${CONFIG_DIR}/plasmarc" ]] && cfg_plasma_existed=true
    [[ -f "${CONFIG_DIR}/kwinrc" ]] && cfg_kwin_existed=true
    [[ -f "${CONFIG_DIR}/ksplashrc" ]] && cfg_ksplash_existed=true

    val_lookandfeel=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage --default org.kde.breeze.desktop 2>/dev/null || echo "org.kde.breeze.desktop")
    val_auto=$(kreadconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel --default false 2>/dev/null || echo "false")
    val_light=$(kreadconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel 2>/dev/null || echo "")
    val_dark=$(kreadconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel 2>/dev/null || echo "")
    val_colorscheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme --default BreezeLight 2>/dev/null || echo "BreezeLight")
    val_icons=$(kreadconfig6 --file kdeglobals --group Icons --key Theme --default breeze 2>/dev/null || echo "breeze")
    val_plasma_theme=$(kreadconfig6 --file plasmarc --group Theme --key name --default default 2>/dev/null || echo "default")
    val_windec_lib=$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library --default org.kde.breeze 2>/dev/null || echo "org.kde.breeze")
    val_windec_theme=$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme --default Breeze 2>/dev/null || echo "Breeze")
    val_ksplash_theme=$(kreadconfig6 --file ksplashrc --group KSplash --key Theme --default org.kde.breeze.desktop 2>/dev/null || echo "org.kde.breeze.desktop")
    val_ksplash_engine=$(kreadconfig6 --file ksplashrc --group KSplash --key Engine --default KSplashQML 2>/dev/null || echo "KSplashQML")

    cat > "$PREV_INI" <<EOF
[Meta]
kdeglobals_existed=$cfg_kde_existed
plasmarc_existed=$cfg_plasma_existed
kwinrc_existed=$cfg_kwin_existed
ksplashrc_existed=$cfg_ksplash_existed

[KDE]
LookAndFeelPackage=$val_lookandfeel
AutomaticLookAndFeel=$val_auto
DefaultLightLookAndFeel=$val_light
DefaultDarkLookAndFeel=$val_dark

[General]
ColorScheme=$val_colorscheme

[Icons]
Theme=$val_icons

[PlasmaTheme]
name=$val_plasma_theme

[WindowDecoration]
library=$val_windec_lib
theme=$val_windec_theme

[KSplash]
Theme=$val_ksplash_theme
Engine=$val_ksplash_engine
EOF
    chmod 644 "$PREV_INI"
  else
    echo "Preserving existing previous settings in $PREV_INI"
  fi

  # Initialize clean manifest
  > "$MANIFEST"
  chmod 644 "$MANIFEST"
fi

track() {
  local p=$1
  if (( ! dry_run )); then
    echo "$p" >> "$MANIFEST"
  fi
}

install_file() {
  local src=$1 dst=$2 mode=${3:-644}
  if (( dry_run )); then
    echo "  [dry-run] Would install file: $src -> $dst ($mode)"
  else
    mkdir -p "$(dirname "$dst")"
    rm -f "$dst"
    install -m "$mode" "$src" "$dst"
    track "$dst"
  fi
}

install_dir() {
  local src=$1 dst=$2
  if (( dry_run )); then
    echo "  [dry-run] Would install directory: $src -> $dst"
  else
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    cp -r "$src" "$dst"
    track "$dst"
  fi
}

# 1. Color Schemes: Tabby & Tweed (Light + Dark)
if (( install_colors )); then
  echo "Installing Tabby & Tweed colour schemes..."
  install_file "color-scheme/tabby-and-tweed/TabbyAndTweedLight.colors" "$DATA_DIR/color-schemes/TabbyAndTweedLight.colors" 644
  install_file "color-scheme/tabby-and-tweed/TabbyAndTweedDark.colors" "$DATA_DIR/color-schemes/TabbyAndTweedDark.colors" 644
fi

# 2. Icons: Thumbs & Paws (Only installed when explicitly requested)
if (( install_icons )); then
  echo "Installing Thumbs & Paws icon theme..."
  install_dir "icons/thumbs-and-paws" "$DATA_DIR/icons/thumbs-and-paws"
  if (( ! dry_run )); then
    rm -rf "$DATA_DIR/icons/thumbs-and-paws/tools"
  fi
fi

# 3. Splash Screen: Morning Stretch
if (( install_splash )); then
  echo "Installing Morning Stretch splash screen..."
  install_dir "splash/morning-stretch" "$DATA_DIR/plasma/look-and-feel/com.github.techonerd.morningstretch"
fi

# 4. Global Themes: One Man Nine Lives (Light + Dark)
if (( install_themes )); then
  echo "Installing One Man Nine Lives global themes (Light & Dark)..."
  install_dir "look-and-feel/one-man-nine-lives/light" "$DATA_DIR/plasma/look-and-feel/com.github.techonerd.onemanninelives.light"
  install_dir "look-and-feel/one-man-nine-lives/dark" "$DATA_DIR/plasma/look-and-feel/com.github.techonerd.onemanninelives.dark"

  if (( ! with_catnap && ! dry_run )); then
    rm -rf "$DATA_DIR/plasma/look-and-feel/com.github.techonerd.onemanninelives.light/contents/lockscreen"
    rm -rf "$DATA_DIR/plasma/look-and-feel/com.github.techonerd.onemanninelives.dark/contents/lockscreen"
  fi
fi

# 5. Plasma Desktop Theme: Night Shift
if (( install_plasma_style )); then
  echo "Installing Night Shift Plasma desktop style..."
  install_dir "plasma-style/night-shift/night-shift" "$DATA_DIR/plasma/desktoptheme/night-shift"
fi

# 6. Konsole Colour Schemes and Profiles: Night Shift
if (( install_konsole )); then
  echo "Installing Night Shift Konsole colour schemes and profiles..."
  install_file "plasma-style/night-shift/konsole/NightShiftLight.colorscheme" "$DATA_DIR/konsole/NightShiftLight.colorscheme" 644
  install_file "plasma-style/night-shift/konsole/NightShiftDark.colorscheme" "$DATA_DIR/konsole/NightShiftDark.colorscheme" 644
  install_file "plasma-style/night-shift/konsole/Night Shift Light.profile" "$DATA_DIR/konsole/Night Shift Light.profile" 644
  install_file "plasma-style/night-shift/konsole/Night Shift Dark.profile" "$DATA_DIR/konsole/Night Shift Dark.profile" 644
fi

# 7. Window Decoration: Window Perch
if (( install_window_perch )); then
  echo "Installing Window Perch window decoration..."
  # Window Perch is a compiled KWin plugin (Breeze fork): it installs system-wide with sudo,
  # so this script only prints the commands (see the summary at the end).
  if [[ ! -e /usr/lib/x86_64-linux-gnu/qt6/plugins/org.kde.kdecoration3/com.github.techonerd.windowperch.so ]]; then
    echo "  Window Perch is not built/installed yet; see the commands printed at the end."
  fi
fi

# 8. Widgets / Plasmoids: Name Tag & Lap Time
if (( install_widgets )); then
  echo "Installing Plasma widgets (Name Tag, Lap Time)..."
  install_dir "widgets/name-tag" "$DATA_DIR/plasma/plasmoids/com.github.techonerd.nametag"
  if (( ! dry_run )); then
    rm -f "$DATA_DIR/plasma/plasmoids/com.github.techonerd.nametag/README.md" "$DATA_DIR/plasma/plasmoids/com.github.techonerd.nametag/REVIEW.md"
  fi

  install_dir "widgets/lap-time" "$DATA_DIR/plasma/plasmoids/com.github.techonerd.laptime"
  if (( ! dry_run )); then
    rm -rf "$DATA_DIR/plasma/plasmoids/com.github.techonerd.laptime/tools" "$DATA_DIR/plasma/plasmoids/com.github.techonerd.laptime/preview" \
           "$DATA_DIR/plasma/plasmoids/com.github.techonerd.laptime/README.md" "$DATA_DIR/plasma/plasmoids/com.github.techonerd.laptime/REVIEW.md"
  fi
fi

# 9. Whiskers: CLI, Library, Checks, Desktop, and Widget
if (( install_whiskers )); then
  echo "Installing Whiskers system watch (CLI & widget)..."
  install_file "whiskers/bin/whiskers" "$BIN_DIR/whiskers" 755

  if (( dry_run )); then
    echo "  [dry-run] Would install Whiskers library and checks into $DATA_DIR/whiskers"
    echo "  [dry-run] Would install Whiskers desktop entry into $DATA_DIR/applications"
  else
    rm -rf "$DATA_DIR/whiskers"
    mkdir -p "$DATA_DIR/whiskers/lib" "$DATA_DIR/whiskers/checks.d" "$DATA_DIR/whiskers/share"
    install -m 644 whiskers/lib/* "$DATA_DIR/whiskers/lib/"
    install -m 755 whiskers/checks.d/* "$DATA_DIR/whiskers/checks.d/"
    install -m 644 whiskers/share/releases.conf.example "$DATA_DIR/whiskers/share/"
    track "$DATA_DIR/whiskers"

    mkdir -p "$DATA_DIR/applications"
    sed "s#^Exec=.*#Exec=konsole --hold -e $BIN_DIR/whiskers status#" whiskers/share/whiskers.desktop > "$DATA_DIR/applications/whiskers.desktop"
    chmod 644 "$DATA_DIR/applications/whiskers.desktop"
    track "$DATA_DIR/applications/whiskers.desktop"
  fi

  install_file "whiskers/widget/contents/icons/whiskers.svg" "$DATA_DIR/icons/hicolor/scalable/apps/whiskers.svg" 644
  install_file "whiskers/widget/contents/icons/whiskers-symbolic.svg" "$DATA_DIR/icons/hicolor/scalable/apps/whiskers-symbolic.svg" 644

  install_file "whiskers/systemd/whiskers.service" "$CONFIG_DIR/systemd/user/whiskers.service" 644
  install_file "whiskers/systemd/whiskers.timer" "$CONFIG_DIR/systemd/user/whiskers.timer" 644
  install_file "whiskers/systemd/whiskers-watch.service" "$CONFIG_DIR/systemd/user/whiskers-watch.service" 644

  install_dir "whiskers/widget" "$DATA_DIR/plasma/plasmoids/com.github.techonerd.whiskers"
fi

# Ensure manifest has unique entries
if (( ! dry_run )) && [[ -f "$MANIFEST" ]]; then
  sort -u -o "$MANIFEST" "$MANIFEST"
fi

# 10. Clear ksvg-elements, plasma-svgelements, and icon caches
echo "Clearing ksvg-elements, plasma-svgelements, and icon caches..."
if (( dry_run )); then
  echo "  [dry-run] Would clear caches in $CACHE_DIR (ksvg-elements, plasma-svgelements, plasma_theme, icon-cache)"
else
  rm -rf "${CACHE_DIR}/ksvg-elements"*
  rm -rf "${CACHE_DIR}/plasma-svgelements"*
  rm -rf "${CACHE_DIR}/plasma_theme"*
  rm -rf "${CACHE_DIR}/icon-cache.kcache"
  if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
  fi
fi

# Enable systemd user timer if systemd user manager is active
if (( ! dry_run && install_whiskers )); then
  if systemctl --user is-system-running >/dev/null 2>&1 || [ -e "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/systemd/private" ]; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now whiskers.timer 2>/dev/null || true
  fi
fi

# Apply theme settings if requested
if (( auto )); then
  if (( dry_run )); then
    echo "  [dry-run] Would configure automatic Light/Dark switching"
  elif command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel "com.github.techonerd.onemanninelives.light" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel "com.github.techonerd.onemanninelives.dark" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel true 2>/dev/null || true
    echo "Automatic Light/Dark switching enabled."
  fi
fi

if [[ -n "$apply" ]]; then
  target_id="com.github.techonerd.onemanninelives.light"
  target_colorscheme="TabbyAndTweedLight"
  if [[ "$apply" == "dark" ]]; then
    target_id="com.github.techonerd.onemanninelives.dark"
    target_colorscheme="TabbyAndTweedDark"
  fi

  if (( dry_run )); then
    echo "  [dry-run] Would apply global theme $target_id and colour scheme $target_colorscheme"
  else
    echo "Applying $target_id..."
    has_display=0
    if [[ -n "${WAYLAND_DISPLAY:-}" && -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY}" ]]; then
      has_display=1
    elif [[ -n "${DISPLAY:-}" && -e "/tmp/.X11-unix/X${DISPLAY##*:}" ]]; then
      has_display=1
    fi

    if (( has_display )) && command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
      if (( auto )); then
        plasma-apply-lookandfeel --keep-auto -a "$target_id" 2>/dev/null || true
      else
        plasma-apply-lookandfeel -a "$target_id" 2>/dev/null || true
      fi
    elif command -v kwriteconfig6 >/dev/null 2>&1; then
      kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "$target_id" 2>/dev/null || true
    fi

    if (( has_display )) && command -v plasma-apply-colorscheme >/dev/null 2>&1; then
      plasma-apply-colorscheme "$target_colorscheme" 2>/dev/null || true
    elif command -v kwriteconfig6 >/dev/null 2>&1; then
      kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$target_colorscheme" 2>/dev/null || true
    fi
  fi
fi

if (( dry_run )); then
  echo ""
  echo "Dry run complete. No files were written."
  exit 0
fi

cat <<MSG

==================================================================
 One Man Nine Lives Suite Installed Successfully
==================================================================
Installed components tracked in: $MANIFEST
Original settings preserved in: $PREV_INI

Components ready to use:
  - Global Theme:       One Man Nine Lives Light / Dark
  - Colour Scheme:      Tabby & Tweed Light / Dark
  - Splash Screen:      Morning Stretch
  - Plasma Style:       Night Shift
  - Konsole:            Night Shift Light / Dark schemes & profiles
  - Window Decoration:  Window Perch
  - Widgets:            Whiskers, Name Tag, Lap Time
  - System Watch CLI:   whiskers (run 'whiskers setup')

------------------------------------------------------------------
 Window Perch (window decoration) - compiled plugin, root required:
------------------------------------------------------------------
  cmake -S window-decoration/window-perch -B window-decoration/window-perch/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF
  cmake --build window-decoration/window-perch/build -j"$(nproc)"
  sudo cmake --install window-decoration/window-perch/build
  Undo: sudo xargs rm < window-decoration/window-perch/build/install_manifest.txt

------------------------------------------------------------------
 Doorstep (SDDM Login Screen) — root required, commands only:
------------------------------------------------------------------
  Safe test in window:
    sddm-greeter-qt6 --test-mode --theme ./sddm/doorstep/doorstep

  Install (system-wide):
    sudo cp -r sddm/doorstep/doorstep /usr/share/sddm/themes/
    sudo mkdir -p /etc/sddm.conf.d && echo -e "[Theme]\nCurrent=doorstep" | sudo tee /etc/sddm.conf.d/20-theme.conf

  Uninstall / Undo:
    sudo rm -rf /usr/share/sddm/themes/doorstep /etc/sddm.conf.d/20-theme.conf

------------------------------------------------------------------
 Catnap (Lock Screen) — high risk, commands only:
------------------------------------------------------------------
  Safe test in window (does not lock system):
    ./look-and-feel/one-man-nine-lives/test-lockscreen.sh         # dark
    ./look-and-feel/one-man-nine-lives/test-lockscreen.sh light   # light

  Install into global theme (only after window test):
    cp -r look-and-feel/one-man-nine-lives/dark/contents/lockscreen ~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.dark/contents/
    cp -r look-and-feel/one-man-nine-lives/light/contents/lockscreen ~/.local/share/plasma/look-and-feel/com.github.techonerd.onemanninelives.light/contents/

  Emergency escape hatch if testing full lock:
    Switch to TTY3 (Ctrl+Alt+F3), log in, and run: loginctl unlock-session

------------------------------------------------------------------
 Undo / Uninstall:
------------------------------------------------------------------
  ./uninstall.sh
MSG
