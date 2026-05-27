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

# Adaptive foreground (Android): bust at 820px (~80% of 1024) anchored
# to the bottom of the canvas so the shoulders hug the lower edge of the
# adaptive mask. Top of the head sits ~200px below the canvas top, which
# is still inside the squircle/rounded-square safe area.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x820 \
  -background none -gravity south -extent 1024x1024 \
  "$OUT/launcher_adaptive_fg.png"

# Themed icon (Android 13+ Material You): instead of filling the whole
# silhouette solid white (which throws away every line in the line-art
# source and produces a featureless blob once the system tints it),
# extract the DARK INK as the alpha mask. Pipeline:
#   1. take the bust, drop its alpha, convert to grayscale, negate -
#      so original black lines are now bright (255) and the white fill
#      is dark (0).
#   2. multiply by the original alpha so anything outside the bust
#      stays fully transparent.
#   3. light -level pass to crisp the line edges without going binary
#      (keeps anti-aliasing so the lines don't shimmer at small sizes).
#   4. composite that mask onto a solid white RGBA canvas so the system
#      can tint it with the wallpaper accent.
magick "$OUT/launcher_adaptive_fg.png" \
  \( -clone 0 -alpha off -colorspace Gray -negate \) \
  \( -clone 0 -alpha extract \) \
  -delete 0 \
  -compose Multiply -composite \
  -level 10%,80% \
  /tmp/launcher_monochrome_mask.png

magick -size 1024x1024 canvas:white \
  /tmp/launcher_monochrome_mask.png \
  -alpha off -compose CopyOpacity -composite \
  -define png:color-type=6 \
  PNG32:"$OUT/launcher_monochrome.png"
rm -f /tmp/launcher_monochrome_mask.png

# Android 12 splash: 1152x1152, bust at ~760px, centered. The system
# crops splash icons to a 768px circle and uses different framing than
# the adaptive launcher mask, so we keep this one centered for balance.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x760 \
  -background none -gravity center -extent 1152x1152 \
  "$OUT/splash_android12.png"

# Legacy / iOS / web splash: 1024x1024, bust at 640px leaving headroom for
# the branding wordmark beneath.
magick "$SRC_LAUNCHER" -trim +repage \
  -resize x640 \
  -background none -gravity center -extent 1024x1024 \
  "$OUT/splash_legacy.png"

# Linux hicolor icons: GTK/KDE/GNOME pick the closest installed size at
# runtime, so we ship the standard freedesktop ladder. Source is the
# already-padded launcher_full.png so the bust is properly framed at
# every size. install.sh copies each into hicolor/<size>x<size>/apps/.
mkdir -p "$OUT/linux"
for sz in 48 64 128 256 512; do
  magick "$OUT/launcher_full.png" -resize ${sz}x${sz} \
    "$OUT/linux/launcher_${sz}.png"
done

echo "Regenerated:"
ls -lh "$OUT"
