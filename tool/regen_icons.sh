#!/usr/bin/env bash
# Rebuilds images/generated/* from the raw artwork in images/.
# Run this whenever images/launcher.png or images/splash_image.png changes,
# then run:
#   dart run flutter_launcher_icons
#   dart run flutter_native_splash:create
#
# Requires ImageMagick 7 (`magick`). On Arch: pacman -S imagemagick
set -euo pipefail
cd "$(dirname "$0")/.."

SRC_LAUNCHER="images/launcher.png"
SRC_SPLASH="images/splash_image.png"
OUT="images/generated"
mkdir -p "$OUT"

# Launcher (full-bleed-safe, centered, 768px on 1024 canvas, transparent bg).
# Used for iOS / web / Windows / macOS launcher icons.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x768 \
  -background none -gravity center -extent 1024x1024 \
  "$OUT/launcher_full.png"

# Adaptive foreground (Android): bust at 576px (~56% of 1024), well inside
# the 66% safe zone Android's adaptive mask carves out.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x576 \
  -background none -gravity center -extent 1024x1024 \
  "$OUT/launcher_adaptive_fg.png"

# Themed icon (Android 13+ Material You): solid white silhouette with the
# original alpha. The system tints this with the user's wallpaper accent.
magick "$OUT/launcher_adaptive_fg.png" \
  -channel RGB -fill white -colorize 100 +channel \
  "$OUT/launcher_monochrome.png"

# Android 12 splash: 1152x1152, bust at ~700px so it sits inside the 768px
# mask circle Android 12+ applies to splash icons.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x700 \
  -background none -gravity center -extent 1152x1152 \
  "$OUT/splash_android12.png"

# Legacy / iOS / web splash: 1024x1024, bust at 640px leaving headroom for
# the branding wordmark beneath.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x640 \
  -background none -gravity center -extent 1024x1024 \
  "$OUT/splash_legacy.png"

echo "Regenerated:"
ls -lh "$OUT"
