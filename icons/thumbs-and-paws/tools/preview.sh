#!/usr/bin/env bash
# Render preview.png: full set at 96px, 22px, and 16px on light and dark panels.
# Also prints contrast check for slate elements against #eff0f1 and #202326.
# Needs ImageMagick with SVG support. Usage: tools/preview.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Print Contrast Verification
python3 -I tools/generate.py --check-contrast
echo ""

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# Ordered canonical icons (29 unique icons)
ICONS=(
  "places:folder"
  "places:folder-home"
  "places:folder-documents"
  "places:folder-downloads"
  "places:folder-pictures"
  "places:folder-music"
  "places:folder-videos"
  "places:folder-desktop"
  "places:folder-favorites"
  "places:folder-git"
  "places:folder-development"
  "places:folder-network"
  "places:folder-cloud"
  "places:folder-templates"
  "places:folder-public"
  "places:folder-locked"
  "places:folder-temp"
  "places:user-trash"
  "places:user-trash-full"
  "apps:utilities-terminal"
  "apps:system-file-manager"
  "apps:preferences-system"
  "actions:system-search"
  "devices:drive-harddisk"
  "devices:drive-removable-media"
  "places:folder-symbolic"
  "places:user-home-symbolic"
  "places:user-trash-symbolic"
  "actions:system-search-symbolic"
)

echo "Rendering icons for preview..."
idx=0
for entry in "${ICONS[@]}"; do
  ctx="${entry%%:*}"
  name="${entry##*:}"
  seq=$(printf "%02d" "$idx")
  
  # 96px render from scalable
  if [[ -f "$ctx/scalable/$name.svg" ]]; then
    magick -background none -density 300 "$ctx/scalable/$name.svg" -resize 96x96 "$tmp/big-$seq-$name.png"
  else
    magick -background none -density 300 "$ctx/16/$name.svg" -resize 96x96 "$tmp/big-$seq-$name.png"
  fi
  
  # 22px render from 22/ (or 16/ for symbolic)
  if [[ -f "$ctx/22/$name.svg" ]]; then
    magick -background none -density 300 "$ctx/22/$name.svg" -resize 22x22 "$tmp/m22-$seq-$name.png"
  else
    magick -background none -density 300 "$ctx/16/$name.svg" -resize 22x22 "$tmp/m22-$seq-$name.png"
  fi
  
  # 16px render from 16/
  magick -background none -density 300 "$ctx/16/$name.svg" -resize 16x16 "$tmp/s16-$seq-$name.png"
  
  idx=$((idx + 1))
done

echo "Assembling preview montage on light (#eff0f1) and dark (#202326)..."
for bg in '#eff0f1' '#202326'; do
  clean_bg="${bg#\#}"
  # 96px full set (10 per row)
  magick montage "$tmp"/big-*.png -tile 10x -geometry 96x96+10+10 -background "$bg" "$tmp/row96-$clean_bg.png"
  # 22px row
  magick montage "$tmp"/m22-*.png -tile 29x -geometry 22x22+6+6 -background "$bg" "$tmp/row22-$clean_bg.png"
  # 16px row
  magick montage "$tmp"/s16-*.png -tile 29x -geometry 16x16+6+6 -background "$bg" "$tmp/row16-$clean_bg.png"
  
  # Combine light / dark section
  magick "$tmp/row96-$clean_bg.png" "$tmp/row22-$clean_bg.png" "$tmp/row16-$clean_bg.png" -append "$tmp/section-$clean_bg.png"
done

# Combine light panel + dark panel into final preview.png
magick "$tmp/section-eff0f1.png" "$tmp/section-202326.png" -append preview.png
echo "wrote preview.png successfully."
