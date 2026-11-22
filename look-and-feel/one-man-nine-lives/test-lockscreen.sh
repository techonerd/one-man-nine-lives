#!/usr/bin/env bash
# Test the Catnap lock screen safely in a window without installing permanently.
# Usage:
#   ./test-lockscreen.sh         # tests dark lockscreen (pure white Casper)
#   ./test-lockscreen.sh light   # tests light lockscreen (pure black Casper)
set -euo pipefail
cd "$(dirname "$0")"

variant=${1:-dark}
[[ $variant == light || $variant == dark ]] || { echo "Usage: $0 [dark|light]"; exit 1; }

ID="com.github.techonerd.catnap.$variant"
TARGET_DIR="$HOME/.local/share/plasma/shells"
TARGET="$TARGET_DIR/$ID"

mkdir -p "$TARGET_DIR"
ln -snf "$(pwd)/shells/$ID" "$TARGET"

echo "=========================================================="
echo " Starting Catnap ($variant mode) in a safe test window..."
echo " Casper coat: $([ "$variant" == "dark" ] && echo "Pure White (#FFFFFF)" || echo "Pure Black (#1B1714)")"
echo " Close the test window or unlock with Enter to exit."
echo "=========================================================="

/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing --shell "$ID" || true

rm -f "$TARGET"
echo "Test finished. Temporary package link removed."
