#!/usr/bin/env bash
# Regenerates the Google Play feature graphic (1024x500) from the app
# logo and brand colours. Output: fastlane/metadata/android/en-US/images/featureGraphic.png
# Requires ImageMagick (magick).
set -euo pipefail
cd "$(dirname "$0")/.."

LOGO=images/generated/linux/launcher_512.png
OUT=fastlane/metadata/android/en-US/images/featureGraphic.png

# 1) Solid brand-green background (no gradient)
magick -size 1024x500 xc:'#7ED957' /tmp/fg_bg.png

# 2) Trim the mascot to its content so there is no transparent padding,
#    then scale it up. Placed bottom-left with SouthWest gravity and a 0
#    vertical offset so it hugs the bottom edge of the canvas.
magick "$LOGO" -trim +repage -resize x470 /tmp/fg_logo.png
magick /tmp/fg_bg.png /tmp/fg_logo.png -gravity SouthWest -geometry +96+0 -composite /tmp/fg_step.png

# 3) Title + tagline in the brand's dark on-green colour (white fails
#    contrast on the bright brand green), right of the mascot.
magick /tmp/fg_step.png \
  -gravity NorthWest -font DejaVu-Sans-Bold -fill '#0A1F0E' \
  -pointsize 82 -annotate +470+150 'Custom RR' \
  -pointsize 32 -annotate +474+288 'Custom ROMs, Recoveries' \
  -pointsize 32 -annotate +474+332 '& Treble GSIs' \
  "$OUT"

identify -format 'feature graphic: %wx%h %m %b\n' "$OUT"
