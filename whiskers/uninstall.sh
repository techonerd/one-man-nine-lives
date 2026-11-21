#!/usr/bin/env bash
# Remove Whiskers. Settings, your own checks and history are kept unless you pass --purge.
set -uo pipefail
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
systemctl --user disable --now whiskers.timer whiskers-watch.service 2>/dev/null
rm -f "$CFG/systemd/user/whiskers.service" "$CFG/systemd/user/whiskers.timer" "$CFG/systemd/user/whiskers-watch.service"
rm -rf "$CFG/systemd/user/whiskers.timer.d"
systemctl --user daemon-reload
kpackagetool6 -t Plasma/Applet -r com.github.techonerd.whiskers 2>/dev/null
rm -rf "$DATA/whiskers"
rm -f "$HOME/.local/bin/whiskers" "$DATA/applications/whiskers.desktop" \
      "$DATA/icons/hicolor/scalable/apps/whiskers.svg" "$DATA/icons/hicolor/scalable/apps/whiskers-symbolic.svg"
if [[ ${1:-} == --purge ]]; then
  rm -rf "$CFG/whiskers" "${XDG_STATE_HOME:-$HOME/.local/state}/whiskers"
  echo "Whiskers removed, including settings and history."
else
  echo "Whiskers removed. Settings kept in $CFG/whiskers (use --purge to delete them)."
fi
echo "Remove the widget from your panel if it is still shown."
