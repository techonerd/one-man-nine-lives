#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
# Uninstall One Man Nine Lives KDE Plasma 6 suite.
# Removes only manifest-tracked paths under suite-authorized locations.
# Never deletes kdeglobals, kwinrc, plasmarc, or ksplashrc; only restores keys.
# User paths only.
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

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help    Show this help message
EOF
}

while (( $# )); do
  case $1 in
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1 ;;
  esac
  shift
done

echo "=== Uninstalling One Man Nine Lives KDE Plasma 6 Suite ==="

if [[ ! -f "$MANIFEST" ]]; then
  echo "No manifest file found at $MANIFEST. Nothing to uninstall."
  exit 0
fi

# Stop Whiskers systemd services if active
if systemctl --user is-system-running >/dev/null 2>&1 || [ -e "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/systemd/private" ]; then
  systemctl --user disable --now whiskers.timer whiskers-watch.service laptime-idle.service 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
fi

# Whitelist check for manifest entries: refuse any path not under suite's install locations
is_allowed_suite_path() {
  local p="$1"
  case "$p" in
    */color-schemes/TabbyAndTweed*.colors)
      return 0 ;;
    */icons/thumbs-and-paws|*/icons/thumbs-and-paws/*)
      return 0 ;;
    */plasma/look-and-feel/com.github.techonerd.*)
      return 0 ;;
    */plasma/desktoptheme/night-shift|*/plasma/desktoptheme/night-shift/*)
      return 0 ;;
    */plasma/plasmoids/com.github.techonerd.*)
      return 0 ;;
    */aurorae/themes/WindowPerch|*/aurorae/themes/WindowPerch/*|*/aurorae/themes/WindowPerchLight|*/aurorae/themes/WindowPerchLight/*|*/aurorae/themes/WindowPerchDark|*/aurorae/themes/WindowPerchDark/*)
      return 0 ;;
    */konsole/NightShift*|*/konsole/Night\ Shift*)
      return 0 ;;
    */bin/whiskers)
      return 0 ;;
    */whiskers|*/whiskers/*)
      return 0 ;;
    */applications/whiskers.desktop)
      return 0 ;;
    */icons/hicolor/*/apps/whiskers*)
      return 0 ;;
    */systemd/user/whiskers*)
      return 0 ;;
    */bin/laptime-idle|*/systemd/user/laptime-idle.service|*/wallpapers/com.github.techonerd.catnap|*/wallpapers/com.github.techonerd.catnap/*|*/plasma/wallpapers/com.github.techonerd.catnap|*/plasma/wallpapers/com.github.techonerd.catnap/*)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# 1. Remove only authorized manifest-tracked paths in reverse order
echo "Removing manifest-tracked files and directories..."
(tac "$MANIFEST" 2>/dev/null || awk '{a[i++]=$0} END {for (j=i-1; j>=0; j--) print a[j]}' "$MANIFEST") | while IFS= read -r item || [[ -n "$item" ]]; do
  [[ -z "$item" || "$item" =~ ^# ]] && continue

  if ! is_allowed_suite_path "$item"; then
    echo "Warning: Refusing to remove unauthorized path from manifest: $item" >&2
    continue
  fi

  if [[ -d "$item" && ! -L "$item" ]]; then
    rm -rf "$item"
  elif [[ -f "$item" || -L "$item" ]]; then
    rm -f "$item"
  fi

  # Clean up empty parent directories up to HOME
  parent=$(dirname "$item")
  while [[ "$parent" != "$HOME" && "$parent" != "/" && -d "$parent" ]]; do
    rmdir "$parent" 2>/dev/null || break
    parent=$(dirname "$parent")
  done
done

# 2. Restore previous settings from previous.ini (never delete config files; only restore keys)
if [[ -f "$PREV_INI" ]]; then
  echo "Restoring previous settings from $PREV_INI..."

  get_ini() {
    local sec=$1 key=$2
    awk -F'=' -v s="[$sec]" -v k="$key" '
      $0 == s { in_sec=1; next }
      /^\[/ { in_sec=0 }
      in_sec && $1 ~ "^[[:space:]]*"k"[[:space:]]*$" {
        sub(/^[^=]*=[[:space:]]*/, "");
        print;
        exit;
      }
    ' "$PREV_INI"
  }

  saved_lookandfeel=$(get_ini "KDE" "LookAndFeelPackage")
  saved_auto=$(get_ini "KDE" "AutomaticLookAndFeel")
  saved_light=$(get_ini "KDE" "DefaultLightLookAndFeel")
  saved_dark=$(get_ini "KDE" "DefaultDarkLookAndFeel")
  saved_colorscheme=$(get_ini "General" "ColorScheme")
  saved_icons=$(get_ini "Icons" "Theme")
  saved_plasma_theme=$(get_ini "PlasmaTheme" "name")
  saved_windec_lib=$(get_ini "WindowDecoration" "library")
  saved_windec_theme=$(get_ini "WindowDecoration" "theme")
  saved_splash_theme=$(get_ini "KSplash" "Theme")
  saved_splash_engine=$(get_ini "KSplash" "Engine")

  has_display=0
  if [[ -n "${WAYLAND_DISPLAY:-}" && -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY}" ]]; then
    has_display=1
  elif [[ -n "${DISPLAY:-}" && -e "/tmp/.X11-unix/X${DISPLAY##*:}" ]]; then
    has_display=1
  fi

  # Global Theme restoration
  cur_lookandfeel=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || echo "")
  if [[ "$cur_lookandfeel" == com.github.techonerd.onemanninelives.* ]]; then
    if [[ -n "$saved_lookandfeel" ]]; then
      echo "Restoring global theme to $saved_lookandfeel..."
      if (( has_display )) && command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
        plasma-apply-lookandfeel -a "$saved_lookandfeel" 2>/dev/null || true
      elif command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "$saved_lookandfeel" 2>/dev/null || true
      fi
    else
      command -v kwriteconfig6 >/dev/null 2>&1 && kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage --delete 2>/dev/null || true
    fi
  fi

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    if [[ -n "$saved_auto" ]]; then
      kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel "$saved_auto" 2>/dev/null || true
    else
      kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel --delete 2>/dev/null || true
    fi

    if [[ $(kreadconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel 2>/dev/null || echo "") == com.github.techonerd.* ]]; then
      if [[ -n "$saved_light" ]]; then
        kwriteconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel "$saved_light" 2>/dev/null || true
      else
        kwriteconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel --delete 2>/dev/null || true
      fi
    fi
    if [[ $(kreadconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel 2>/dev/null || echo "") == com.github.techonerd.* ]]; then
      if [[ -n "$saved_dark" ]]; then
        kwriteconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel "$saved_dark" 2>/dev/null || true
      else
        kwriteconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel --delete 2>/dev/null || true
      fi
    fi
  fi

  # Colour Scheme restoration
  cur_colorscheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo "")
  if [[ "$cur_colorscheme" == TabbyAndTweed* ]]; then
    if [[ -n "$saved_colorscheme" ]]; then
      echo "Restoring colour scheme to $saved_colorscheme..."
      if (( has_display )) && command -v plasma-apply-colorscheme >/dev/null 2>&1; then
        plasma-apply-colorscheme "$saved_colorscheme" 2>/dev/null || true
      elif command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$saved_colorscheme" 2>/dev/null || true
      fi
    else
      command -v kwriteconfig6 >/dev/null 2>&1 && kwriteconfig6 --file kdeglobals --group General --key ColorScheme --delete 2>/dev/null || true
    fi
  fi

  # Icons restoration
  cur_icons=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo "")
  if [[ "$cur_icons" == "thumbs-and-paws" ]]; then
    if [[ -n "$saved_icons" ]]; then
      kwriteconfig6 --file kdeglobals --group Icons --key Theme "$saved_icons" 2>/dev/null || true
    else
      kwriteconfig6 --file kdeglobals --group Icons --key Theme --delete 2>/dev/null || true
    fi
  fi

  # Plasma style restoration
  cur_plasma_theme=$(kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null || echo "")
  if [[ "$cur_plasma_theme" == "night-shift" ]]; then
    if [[ -n "$saved_plasma_theme" ]]; then
      kwriteconfig6 --file plasmarc --group Theme --key name "$saved_plasma_theme" 2>/dev/null || true
    else
      kwriteconfig6 --file plasmarc --group Theme --key name --delete 2>/dev/null || true
    fi
  fi

  # Window decoration restoration
  cur_windec_theme=$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme 2>/dev/null || echo "")
  if [[ "$cur_windec_theme" == *WindowPerch* ]]; then
    if [[ -n "$saved_windec_theme" ]]; then
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "$saved_windec_lib" 2>/dev/null || true
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "$saved_windec_theme" 2>/dev/null || true
    else
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library --delete 2>/dev/null || true
      kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme --delete 2>/dev/null || true
    fi
  fi

  # Splash screen restoration
  cur_splash_theme=$(kreadconfig6 --file ksplashrc --group KSplash --key Theme 2>/dev/null || echo "")
  if [[ "$cur_splash_theme" == "com.github.techonerd.morningstretch" ]]; then
    if [[ -n "$saved_splash_theme" ]]; then
      kwriteconfig6 --file ksplashrc --group KSplash --key Theme "$saved_splash_theme" 2>/dev/null || true
      kwriteconfig6 --file ksplashrc --group KSplash --key Engine "$saved_splash_engine" 2>/dev/null || true
    else
      kwriteconfig6 --file ksplashrc --group KSplash --key Theme --delete 2>/dev/null || true
      kwriteconfig6 --file ksplashrc --group KSplash --key Engine --delete 2>/dev/null || true
    fi
  fi
fi

# 3. Clear ksvg-elements, plasma-svgelements, and icon caches
echo "Clearing ksvg-elements, plasma-svgelements, and icon caches..."
rm -rf "${CACHE_DIR}/ksvg-elements"*
rm -rf "${CACHE_DIR}/plasma-svgelements"*
rm -rf "${CACHE_DIR}/plasma_theme"*
rm -rf "${CACHE_DIR}/icon-cache.kcache"
rm -rf "${CACHE_DIR}/ksycoca6"*
rmdir "${CACHE_DIR}" 2>/dev/null || true
if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 >/dev/null 2>&1 || true
  rm -rf "${CACHE_DIR}/ksycoca6"*
  rmdir "${CACHE_DIR}" 2>/dev/null || true
fi

# 4. Remove manifest and previous.ini, prune state directory
rm -f "$MANIFEST" "$PREV_INI"
parent="$STATE_DIR"
while [[ "$parent" != "$HOME" && "$parent" != "/" && -d "$parent" ]]; do
  rmdir "$parent" 2>/dev/null || break
  parent=$(dirname "$parent")
done

cat <<MSG

==================================================================
 One Man Nine Lives Suite Uninstalled Successfully
==================================================================
All manifest-tracked files under suite locations have been cleanly removed.
Previous desktop configuration keys have been restored (config files preserved).

Note for Doorstep & Catnap:
  - If Doorstep SDDM login theme was installed with root/sudo:
      sudo rm -rf /usr/share/sddm/themes/doorstep /etc/sddm.conf.d/20-theme.conf
  - Catnap: if it is still your lock-screen wallpaper, pick another one in
    System Settings → Screen Locking → Appearance.
MSG
