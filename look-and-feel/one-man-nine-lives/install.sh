#!/usr/bin/env bash
# Install the One Man Nine Lives global themes (Light + Dark) and the suite parts they use.
# User-level, no sudo. Your panels and wallpaper are never touched.
#
#   ./install.sh                 install only (pick it later in System Settings > Global Theme)
#   ./install.sh --apply dark    install and switch to the dark variant now (or: light)
#   ./install.sh --auto          also let Plasma switch Light/Dark automatically with the time of day
set -euo pipefail
cd "$(dirname "$0")"
SUITE=$(cd ../.. && pwd)
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/one-man-nine-lives
LIGHT_ID=com.github.techonerd.onemanninelives.light
DARK_ID=com.github.techonerd.onemanninelives.dark

apply="" auto=0
while (( $# )); do
  case $1 in
    --apply) apply=${2:-}; shift ;;
    --auto) auto=1 ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
  shift
done
[[ -z $apply || $apply == light || $apply == dark ]] || { echo "--apply takes light or dark"; exit 1; }

for dep in kpackagetool6 plasma-apply-lookandfeel kwriteconfig6 kreadconfig6; do
  command -v "$dep" >/dev/null || { echo "Missing $dep (part of Plasma 6)"; exit 1; }
done

echo "Installing Tabby & Tweed colours and Thumbs & Paws icons..."
mkdir -p "$DATA/color-schemes" "$DATA/icons"
install -m 644 "$SUITE"/color-scheme/tabby-and-tweed/*.colors "$DATA/color-schemes/"
rm -rf "$DATA/icons/thumbs-and-paws"
cp -r "$SUITE/icons/thumbs-and-paws" "$DATA/icons/"
rm -rf "$DATA/icons/thumbs-and-paws/tools"

pkg() { # id dir
  if kpackagetool6 -t Plasma/LookAndFeel -s "$1" >/dev/null 2>&1; then kpackagetool6 -t Plasma/LookAndFeel -u "$2"
  else kpackagetool6 -t Plasma/LookAndFeel -i "$2"; fi
}
echo "Installing the Morning Stretch splash and the global themes..."
pkg com.github.techonerd.morningstretch "$SUITE/splash/morning-stretch"
pkg "$LIGHT_ID" light
pkg "$DARK_ID" dark

# Remember what you used before, so uninstall.sh can put it back
mkdir -p "$STATE"
if [[ ! -f $STATE/previous-global-theme ]]; then
  kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage --default org.kde.breeze.desktop > "$STATE/previous-global-theme"
  kreadconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel --default false > "$STATE/previous-automatic"
fi

if (( auto )); then
  kwriteconfig6 --file kdeglobals --group KDE --key DefaultLightLookAndFeel "$LIGHT_ID"
  kwriteconfig6 --file kdeglobals --group KDE --key DefaultDarkLookAndFeel "$DARK_ID"
  kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel true
  echo "Automatic Light/Dark switching is on (fully active after your next login)."
fi
if [[ -n $apply ]]; then
  id=$LIGHT_ID; [[ $apply == dark ]] && id=$DARK_ID
  if (( auto )); then plasma-apply-lookandfeel --keep-auto -a "$id"   # --apply alone would turn automatic mode off
  else plasma-apply-lookandfeel -a "$id"; fi
fi

cat <<MSG

Done. Choose it any time in System Settings > Colors & Themes > Global Theme:
  "One Man Nine Lives Light" / "One Man Nine Lives Dark"
Undo: ./uninstall.sh  (restores your previous global theme)
MSG
