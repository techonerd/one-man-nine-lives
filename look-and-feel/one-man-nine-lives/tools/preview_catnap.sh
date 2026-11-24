#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
# Generate Catnap preview contact sheet and animated WebP preview loop.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CATNAP_DIR="$(cd "$SCRIPT_DIR/../catnap" && pwd)"
PREVIEW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/preview"
TMP_DIR="$(mktemp -d /tmp/catnap_preview.XXXXXX)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$PREVIEW_DIR" "/tmp/wk/bin"

# 1. Compile C++ batch offscreen frame grabber matching render_harness architecture
HELPER_SRC="/tmp/wk/catnap_batch_render.cpp"
HELPER_BIN="/tmp/wk/bin/catnap_batch_render"

cat << 'EOF' > "$HELPER_SRC"
#include <QGuiApplication>
#include <QQuickView>
#include <QQuickItem>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QImage>
#include <QThread>
#include <iostream>
#include <string>

int main(int argc, char **argv) {
    if (argc < 4) {
        std::cerr << "Usage: catnap_batch_render <qml_file> <width> <height>" << std::endl;
        return 1;
    }

    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    qputenv("PULSE_SERVER", "/dev/null");
    qputenv("PULSE_AUTOSPAWN", "0");
    qputenv("CANBERRA_DRIVER", "null");

    QGuiApplication app(argc, argv);

    int width = std::atoi(argv[2]);
    int height = std::atoi(argv[3]);

    QQmlEngine engine;
    engine.addImportPath("/usr/lib/x86_64-linux-gnu/qt6/qml");

    QQmlComponent comp(&engine, QUrl::fromLocalFile(argv[1]));
    if (comp.isError()) {
        for (const auto &err : comp.errors()) {
            std::cerr << "QML Error: " << err.toString().toStdString() << std::endl;
        }
        return 1;
    }

    QObject *obj = comp.create();
    if (!obj) {
        std::cerr << "Failed to create QML object" << std::endl;
        return 1;
    }

    QQuickItem *item = qobject_cast<QQuickItem*>(obj);
    if (!item) {
        std::cerr << "Root object is not QQuickItem" << std::endl;
        return 1;
    }

    QQuickView view(&engine, nullptr);
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.resize(width, height);
    item->setParentItem(view.contentItem());
    item->setWidth(width);
    item->setHeight(height);
    view.show();

    // Settle layouts, textures, async SVG loaders
    for (int i = 0; i < 25; ++i) {
        QCoreApplication::processEvents();
        QThread::msleep(20);
    }

    item->setProperty("seed", 42);

    // Read timestamps and output filenames: "<time_ms> <output_path>"
    double tMs;
    std::string outPath;
    int count = 0;
    while (std::cin >> tMs >> outPath) {
        item->setProperty("clockMs", tMs);
        for (int i = 0; i < 3; ++i) {
            QCoreApplication::processEvents();
            QThread::msleep(10);
        }
        QImage img = view.grabWindow();
        if (!img.isNull()) {
            img.save(QString::fromStdString(outPath));
            count++;
        } else {
            std::cerr << "Failed to grab window at " << tMs << " ms" << std::endl;
        }
    }
    std::cout << "Successfully rendered " << count << " frames." << std::endl;
    return 0;
}
EOF

g++ -O2 "$HELPER_SRC" $(pkg-config --cflags --libs Qt6Quick Qt6Qml) -o "$HELPER_BIN"

echo "Rendering 12 contact-sheet moments..."
# Moments: 6 across breath cycle (0 to ~3800ms), 6 across first flick (16277ms to 18277ms with seed 42)
cat << 'EOF' > "$TMP_DIR/contact_times.txt"
0 00_rest.png
800 01_inhale.png
1600 02_inhale_peak.png
2550 03_exhale.png
3500 04_exhale_done.png
3800 05_breath_rest.png
16277 06_flick_start.png
16577 07_tail_waving.png
17077 08_max_angle.png
17377 09_returning.png
17877 10_settling.png
18277 11_flick_done.png
EOF

while read -r ms name; do
    echo "$ms $TMP_DIR/$name"
done < "$TMP_DIR/contact_times.txt" | "$HELPER_BIN" "$CATNAP_DIR/contents/ui/main.qml" 640 400

echo "Assembling preview/catnap-frames.png..."
montage \
    -label "0.0s: Rest" "$TMP_DIR/00_rest.png" \
    -label "0.8s: Inhaling" "$TMP_DIR/01_inhale.png" \
    -label "1.6s: Inhale peak (+2.5%)" "$TMP_DIR/02_inhale_peak.png" \
    -label "2.5s: Exhaling" "$TMP_DIR/03_exhale.png" \
    -label "3.5s: Exhale done" "$TMP_DIR/04_exhale_done.png" \
    -label "3.8s: Rest" "$TMP_DIR/05_breath_rest.png" \
    -label "Flick +0.0s: Start" "$TMP_DIR/06_flick_start.png" \
    -label "Flick +0.3s: Tail waves" "$TMP_DIR/07_tail_waving.png" \
    -label "Flick +0.8s: Max angle" "$TMP_DIR/08_max_angle.png" \
    -label "Flick +1.1s: Returning" "$TMP_DIR/09_returning.png" \
    -label "Flick +1.6s: Settling" "$TMP_DIR/10_settling.png" \
    -label "Flick +2.0s: Rest (0°)" "$TMP_DIR/11_flick_done.png" \
    -tile 4x3 \
    -geometry +8+8 \
    -fill '#F5F5F5' \
    -background '#202326' \
    "$PREVIEW_DIR/catnap-frames.png"

echo "Rendering 4-second preview loop (48 frames @ 12 fps, 640x400)..."
rm -f "$TMP_DIR/anim_times.txt"
for i in $(seq 0 47); do
    frame_ms=$(python3 -c "print(15277 + $i * (4000.0 / 48.0))")
    frame_file=$(printf "%s/anim_%03d.png" "$TMP_DIR" "$i")
    echo "$frame_ms $frame_file" >> "$TMP_DIR/anim_times.txt"
done

"$HELPER_BIN" "$CATNAP_DIR/contents/ui/main.qml" 640 400 < "$TMP_DIR/anim_times.txt"

echo "Encoding preview/catnap.webp..."
WEBP_ARGS=(-loop 0)
for i in $(seq 0 47); do
    frame_file=$(printf "%s/anim_%03d.png" "$TMP_DIR" "$i")
    WEBP_ARGS+=(-d 83 -lossy -q 90 "$frame_file")
done

img2webp "${WEBP_ARGS[@]}" -o "$PREVIEW_DIR/catnap.webp"

echo "Generated:"
echo "  - $PREVIEW_DIR/catnap-frames.png ($(identify "$PREVIEW_DIR/catnap-frames.png" | awk '{print $3}'))"
echo "  - $PREVIEW_DIR/catnap.webp ($(identify "$PREVIEW_DIR/catnap.webp" | wc -l) frames)"
