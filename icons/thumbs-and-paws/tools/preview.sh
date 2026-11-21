#!/usr/bin/env bash
# Render preview.png: every icon on a light and a dark panel, at large and panel size.
# Needs ImageMagick with SVG support.  Usage: tools/preview.sh
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for f in places/scalable/*.svg; do
  n=$(basename "$f" .svg)
  magick -background none -density 300 "$f" -resize 96x96 "$tmp/big-$n.png"
  magick -background none -density 300 "$f" -resize 22x22 "$tmp/small-$n.png"
done
for bg in '#eff0f1' '#202326'; do
  magick montage "$tmp"/big-*.png -tile 11x -geometry 96x96+12+12 -background "$bg" "$tmp/row-${bg#\#}.png"
  magick montage "$tmp"/small-*.png -tile 11x -geometry 22x22+49+8 -background "$bg" "$tmp/srow-${bg#\#}.png"
done
magick "$tmp/row-eff0f1.png" "$tmp/srow-eff0f1.png" "$tmp/row-202326.png" "$tmp/srow-202326.png" -append preview.png
echo "wrote preview.png"
