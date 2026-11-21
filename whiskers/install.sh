#!/usr/bin/env bash
# Install or upgrade Whiskers for the current user. No sudo; nothing outside your home is touched.
set -euo pipefail
cd "$(dirname "$0")"

missing=()
for dep in jq curl notify-send busctl flock timeout udevadm journalctl kpackagetool6; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if (( ${#missing[@]} )); then
  echo "Missing: ${missing[*]}"
  echo "Debian/Ubuntu/Kali: sudo apt install jq curl libnotify-bin   Fedora: sudo dnf install jq curl libnotify   Arch: sudo pacman -S jq curl libnotify"
  exit 1
fi

BIN=$HOME/.local/bin
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
UNITS=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
mkdir -p "$BIN" "$UNITS" "$DATA/applications" "$DATA/icons/hicolor/scalable/apps"

install -m 755 bin/whiskers "$BIN/whiskers"
rm -rf "$DATA/whiskers"                       # bundled checks only; your own live in ~/.config/whiskers/checks.d
install -d -m 755 "$DATA/whiskers/lib" "$DATA/whiskers/checks.d" "$DATA/whiskers/share"
install -m 644 lib/* "$DATA/whiskers/lib/"
install -m 755 checks.d/* "$DATA/whiskers/checks.d/"
install -m 644 share/releases.conf.example "$DATA/whiskers/share/"
install -m 644 systemd/whiskers.service systemd/whiskers.timer systemd/whiskers-watch.service "$UNITS/"
sed "s#^Exec=.*#Exec=konsole --hold -e $BIN/whiskers status#" share/whiskers.desktop > "$DATA/applications/whiskers.desktop"
install -m 644 widget/contents/icons/whiskers.svg widget/contents/icons/whiskers-symbolic.svg "$DATA/icons/hicolor/scalable/apps/"

if kpackagetool6 -t Plasma/Applet -s com.github.techonerd.whiskers >/dev/null 2>&1; then
  kpackagetool6 -t Plasma/Applet -u widget
else
  kpackagetool6 -t Plasma/Applet -i widget
fi

systemctl --user daemon-reload
"$BIN/whiskers" setup                  # detects this device, writes defaults, starts the live watch
systemctl --user enable --now whiskers.timer
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true

cat <<MSG

Whiskers installed.
  Terminal:  whiskers status   ·   whiskers events
  Widget:    right-click the panel > Add or Manage Widgets > Whiskers
             (or System Tray > Configure System Tray > Entries > Whiskers)
  If the widget was already on your panel, restart Plasma once:  systemctl --user restart plasma-plasmashell
MSG
