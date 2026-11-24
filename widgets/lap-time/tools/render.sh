#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

# Ensure C++ harness is compiled
mkdir -p /tmp/wk/bin /tmp/wk/conf /tmp/wk/cache /tmp/wk/data /tmp/wk/run
if [ ! -f /tmp/wk/bin/render_harness ] || [ tools/render_harness.cpp -nt /tmp/wk/bin/render_harness ]; then
    echo "Compiling render harness..."
    g++ -O2 tools/render_harness.cpp $(pkg-config --cflags --libs Qt6Quick Qt6Qml) -o /tmp/wk/bin/render_harness
fi

cat << 'EOF' > /tmp/wk/conf/kdeglobals
[Icons]
Theme=breeze-dark

[General]
ColorScheme=TabbyAndTweedDark
EOF

export QT_QPA_PLATFORM=offscreen
export QML_DISABLE_DISK_CACHE=1
export XDG_CONFIG_HOME=/tmp/wk/conf
export XDG_CACHE_HOME=/tmp/wk/cache
export XDG_DATA_HOME=/tmp/wk/data
export XDG_RUNTIME_DIR=/tmp/wk/run
export PULSE_SERVER=/dev/null
export PULSE_AUTOSPAWN=0
export CANBERRA_DRIVER=null

HARNESS=/tmp/wk/bin/render_harness
PREV=widgets/lap-time/preview
mkdir -p "$PREV"

echo "Rendering Lap Time Panel states..."
$HARNESS widgets/lap-time/tools/harness/panel_dark.qml "$PREV/panel_dark.png" 360 56
$HARNESS widgets/lap-time/tools/harness/panel_light.qml "$PREV/panel_light.png" 360 56

echo "Rendering Lap Time Popup dialogs..."
$HARNESS widgets/lap-time/tools/harness/popup_dark.qml "$PREV/popup_dark.png" 420 500
$HARNESS widgets/lap-time/tools/harness/popup_light.qml "$PREV/popup_light.png" 420 500
$HARNESS widgets/lap-time/tools/harness/popup_large_font.qml "$PREV/popup_large_font.png" 480 580

echo "Rendering Eye Break strips (1920x1080)..."
$HARNESS widgets/lap-time/tools/harness/eye_strip_dark.qml "$PREV/eye_strip_dark.png" 1920 1080
$HARNESS widgets/lap-time/tools/harness/eye_strip_light.qml "$PREV/eye_strip_light.png" 1920 1080

echo "Rendering Fullscreen Stretch Overlays (1920x1080)..."
$HARNESS widgets/lap-time/tools/harness/stretch_overlay_dark.qml "$PREV/stretch_overlay_dark.png" 1920 1080
$HARNESS widgets/lap-time/tools/harness/stretch_overlay_light.qml "$PREV/stretch_overlay_light.png" 1920 1080

echo "Generating composite preview..."
python3 -I widgets/lap-time/tools/composite_previews.py

echo "Done rendering Lap Time previews."
