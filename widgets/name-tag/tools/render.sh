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
PREV=widgets/name-tag/preview
mkdir -p "$PREV"

echo "Rendering Name Tag Horizontal Panels..."
$HARNESS widgets/name-tag/tools/harness/panel_dark.qml "$PREV/panel_dark.png" 560 48
$HARNESS widgets/name-tag/tools/harness/panel_light.qml "$PREV/panel_light.png" 560 48

echo "Rendering Name Tag Empty States..."
$HARNESS widgets/name-tag/tools/harness/panel_empty_dark.qml "$PREV/panel_empty_dark.png" 560 48
$HARNESS widgets/name-tag/tools/harness/panel_empty_light.qml "$PREV/panel_empty_light.png" 560 48

echo "Rendering Name Tag Vertical Panels..."
$HARNESS widgets/name-tag/tools/harness/panel_vertical_dark.qml "$PREV/panel_vertical_dark.png" 56 320
$HARNESS widgets/name-tag/tools/harness/panel_vertical_light.qml "$PREV/panel_vertical_light.png" 56 320

echo "Rendering Name Tag Settings Pages..."
$HARNESS widgets/name-tag/tools/harness/config_dark.qml "$PREV/config_dark.png" 620 480
$HARNESS widgets/name-tag/tools/harness/config_light.qml "$PREV/config_light.png" 620 480

echo "Generating composite preview..."
python3 -I widgets/name-tag/tools/composite_previews.py

echo "Done rendering Name Tag previews."
