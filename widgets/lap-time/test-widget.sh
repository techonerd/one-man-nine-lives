#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
# Test the Lap Time widget safely in a standalone window without installing permanently.
# Usage:
#   ./widgets/lap-time/test-widget.sh
set -euo pipefail
cd "$(dirname "$0")"

ID="com.github.techonerd.laptime"
WIDGET_DIR="$(pwd)"

# Create an isolated temporary XDG data directory structure for Plasma package discovery
TMP_XDG=$(mktemp -d /tmp/plasma-laptime-XXXXXX)

cleanup() {
    rm -rf "$TMP_XDG"
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP_XDG/plasma/plasmoids"
ln -snf "$WIDGET_DIR" "$TMP_XDG/plasma/plasmoids/$ID"

echo "=========================================================="
echo " Starting Lap Time widget in a safe test window..."
echo " Applet ID: $ID"
echo " Package path: $WIDGET_DIR"
echo " Close the test window to exit."
echo "=========================================================="

export XDG_DATA_DIRS="$TMP_XDG:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

if [[ "${1:-}" == "--viewer" ]] && command -v plasmoidviewer >/dev/null 2>&1; then
    shift
    plasmoidviewer -a "$ID" "$@"
else
    plasmawindowed "$ID" "$@"
fi
