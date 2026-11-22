#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-all}"

# Build C++ render harness
mkdir -p /tmp/wk/bin /tmp/wk/conf /tmp/wk/cache /tmp/wk/data/color-schemes /tmp/wk/run
if [ ! -f /tmp/wk/bin/render_harness ] || [ tools/render_harness.cpp -nt /tmp/wk/bin/render_harness ]; then
    echo "Compiling render harness..."
    g++ -O2 tools/render_harness.cpp $(pkg-config --cflags --libs Qt6Quick Qt6Qml) -o /tmp/wk/bin/render_harness
fi

# Ensure Tabby & Tweed color schemes are in XDG_DATA_HOME so KDE finds them
cp "$ROOT"/color-scheme/tabby-and-tweed/*.colors /tmp/wk/data/color-schemes/

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

set_env_dark() {
    cat << 'EOF' > /tmp/wk/conf/plasmarc
[Theme]
name=breeze-dark
EOF
    cat << 'EOF' > /tmp/wk/conf/kdeglobals
[Icons]
Theme=breeze-dark

[General]
ColorScheme=TabbyAndTweedDark
EOF
}

set_env_light() {
    cat << 'EOF' > /tmp/wk/conf/plasmarc
[Theme]
name=breeze-light
EOF
    cat << 'EOF' > /tmp/wk/conf/kdeglobals
[Icons]
Theme=breeze

[General]
ColorScheme=TabbyAndTweedLight
EOF
}

if [ "$TARGET" = "all" ] || [ "$TARGET" = "doorstep" ] || [ "$TARGET" = "sddm" ]; then
    echo "Rendering Doorstep SDDM states (2560x1600)..."
    python3 -I sddm/doorstep/tools/generate.py
    mkdir -p sddm/doorstep/preview

    set_env_dark
    $HARNESS tools/harness/doorstep_dark.qml sddm/doorstep/preview/doorstep_dark.png
    $HARNESS tools/harness/doorstep_error.qml sddm/doorstep/preview/doorstep_error.png
    $HARNESS tools/harness/doorstep_capslock.qml sddm/doorstep/preview/doorstep_capslock.png

    set_env_light
    $HARNESS tools/harness/doorstep_light.qml sddm/doorstep/preview/doorstep_light.png
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "catnap" ] || [ "$TARGET" = "lockscreen" ]; then
    echo "Rendering Catnap Lock Screen states (2560x1600)..."
    python3 -I look-and-feel/one-man-nine-lives/tools/generate_lockscreen_art.py
    mkdir -p look-and-feel/one-man-nine-lives/preview

    set_env_dark
    $HARNESS tools/harness/catnap_dark.qml look-and-feel/one-man-nine-lives/preview/catnap_dark.png
    $HARNESS tools/harness/catnap_error.qml look-and-feel/one-man-nine-lives/preview/catnap_error.png
    $HARNESS tools/harness/catnap_capslock.qml look-and-feel/one-man-nine-lives/preview/catnap_capslock.png

    set_env_light
    $HARNESS tools/harness/catnap_light.qml look-and-feel/one-man-nine-lives/preview/catnap_light.png
fi

echo "Generating composite previews..."
python3 -I tools/composite_previews.py

echo "Done rendering previews."
