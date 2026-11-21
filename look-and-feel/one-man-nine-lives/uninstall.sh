#!/usr/bin/env bash
# Remove the One Man Nine Lives global themes and restore the global theme you used before.
#   ./uninstall.sh          remove the global themes (keeps colours, icons and splash for separate use)
#   ./uninstall.sh --all    also remove Tabby & Tweed, Thumbs & Paws and Morning Stretch
set -uo pipefail
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/one-man-nine-lives
prev=$(cat "$STATE/previous-global-theme" 2>/dev/null || echo org.kde.breeze.desktop)
prev_auto=$(cat "$STATE/previous-automatic" 2>/dev/null || echo false)

current=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)
if [[ $current == com.github.techonerd.onemanninelives.* ]]; then
  echo "Switching back to $prev..."
  plasma-apply-lookandfeel -a "$prev"
fi
kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel "$prev_auto"
for k in DefaultLightLookAndFeel DefaultDarkLookAndFeel; do
  [[ $(kreadconfig6 --file kdeglobals --group KDE --key "$k") == com.github.techonerd.onemanninelives.* ]] && \
    kwriteconfig6 --file kdeglobals --group KDE --key "$k" --delete
done
kpackagetool6 -t Plasma/LookAndFeel -r com.github.techonerd.onemanninelives.light 2>/dev/null
kpackagetool6 -t Plasma/LookAndFeel -r com.github.techonerd.onemanninelives.dark 2>/dev/null
if [[ ${1:-} == --all ]]; then
  kpackagetool6 -t Plasma/LookAndFeel -r com.github.techonerd.morningstretch 2>/dev/null
  rm -f "$DATA/color-schemes/TabbyAndTweedLight.colors" "$DATA/color-schemes/TabbyAndTweedDark.colors"
  rm -rf "$DATA/icons/thumbs-and-paws"
fi
rm -rf "$STATE"
echo "Removed. Global theme: $prev"
