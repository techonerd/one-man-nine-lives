#!/bin/bash
# Build KDE Store / release archives for every finished component of the suite.
# Usage: ./build.sh            -> dist/<component>-<version>.<ext>
set -euo pipefail
cd "$(dirname "$0")"

version() { python3 -I -c 'import json,sys;print(json.load(open(sys.argv[1]))["KPlugin"]["Version"])' "$1"; }
SUITE_VERSION=0.1.0   # all components share this until the suite reaches 1.0.0
rm -rf dist && mkdir -p dist

# Morning Stretch - splash screen (KDE Store: "Plasma 6 Splashscreens", Uncompress=kpackage)
V=$(version splash/morning-stretch/metadata.json)
tar --owner=0 --group=0 -C splash -czf "dist/morning-stretch-$V.tar.gz" morning-stretch

# Whiskers widget (KDE Store: "Plasma 6 Widgets") - .plasmoid is a zip with metadata.json at the top
V=$(version whiskers/widget/metadata.json)
(cd whiskers/widget && zip -qr -X "../../dist/whiskers-widget-$V.plasmoid" metadata.json contents)

# Name Tag widget (KDE Store: "Plasma 6 Widgets")
V_NAMETAG=$(version widgets/name-tag/metadata.json)
(cd widgets/name-tag && zip -qr -X "../../dist/name-tag-$V_NAMETAG.plasmoid" metadata.json contents)

# Lap Time widget (KDE Store: "Plasma 6 Widgets")
V_LAPTIME=$(version widgets/lap-time/metadata.json)
(cd widgets/lap-time && zip -qr -X "../../dist/lap-time-$V_LAPTIME.plasmoid" metadata.json contents)

# Window Perch window decoration (KDE Store: "Aurorae Window Decorations")
V_PERCH=$(version window-decoration/window-perch/WindowPerch/metadata.json)
tar --owner=0 --group=0 -C window-decoration/window-perch -czf "dist/window-perch-$V_PERCH.tar.gz" WindowPerch

# Night Shift plasma style (KDE Store: "Plasma 6 Desktop Themes")
V_NIGHTSHIFT=$(version plasma-style/night-shift/night-shift/metadata.json)
tar --owner=0 --group=0 -C plasma-style/night-shift -czf "dist/plasma-style-night-shift-$V_NIGHTSHIFT.tar.gz" night-shift

# Night Shift Konsole color schemes & profile
tar --owner=0 --group=0 -C plasma-style/night-shift -czf "dist/konsole-night-shift-$SUITE_VERSION.tar.gz" konsole

# Doorstep SDDM theme
tar --owner=0 --group=0 -C sddm/doorstep -czf "dist/sddm-doorstep-$SUITE_VERSION.tar.gz" doorstep

# Whiskers full tool (CLI + timer + widget) - GitHub release asset
tar --owner=0 --group=0 --exclude='*.plasmoid' -czf "dist/whiskers-$V.tar.gz" whiskers

# Thumbs & Paws icons (KDE Store: "Full Icon Themes")
tar --owner=0 --group=0 -C icons --exclude=tools -czf "dist/thumbs-and-paws-$SUITE_VERSION.tar.gz" thumbs-and-paws

# Tabby & Tweed colour schemes (KDE Store: "Plasma 6 Color Schemes")
tar --owner=0 --group=0 -C color-scheme --exclude=tools -czf "dist/tabby-and-tweed-$SUITE_VERSION.tar.gz" tabby-and-tweed

# One Man Nine Lives global themes (KDE Store: "Plasma 6 Global Themes"), one archive per variant
for v in light dark; do
  tar --owner=0 --group=0 -C look-and-feel/one-man-nine-lives -czf "dist/one-man-nine-lives-$v-$SUITE_VERSION.tar.gz" "$v"
done

ls -l dist
