#!/usr/bin/env bash
# Regenerates the Google Play feature graphic (1024x500) from the app
# logo and brand colours. Output: fastlane/metadata/android/en-US/images/featureGraphic.png
# Requires ImageMagick (magick).
set -euo pipefail
cd "$(dirname "$0")/.."

LOGO=images/generated/linux/launcher_512.png
OUT=fastlane/metadata/android/en-US/images/featureGraphic.png

# 1) Brand-green diagonal gradient (seed top-left -> deep bottom-right)
magick -size 1024x500 xc: -sparse-color barycentric '0,0 #7ED957 1024,500 #233D18' /tmp/fg_bg.png

# 2) White rounded card with the mascot centered
magick -size 360x360 xc:none -fill white -draw 'roundrectangle 0,0 359,359 72,72' /tmp/fg_card.png
magick /tmp/fg_card.png \( "$LOGO" -resize 300x300 \) -gravity center -composite /tmp/fg_iconcard.png

# soft drop shadow under the card
magick /tmp/fg_iconcard.png \( +clone -background black -shadow 55x14+0+10 \) +swap -background none -layers merge +repage /tmp/fg_iconcard_sh.png

# 3) Card onto bg (left, vertically centered: (500-360)/2=70, nudged up a touch)
magick /tmp/fg_bg.png /tmp/fg_iconcard_sh.png -geometry +86+62 -composite /tmp/fg_step.png

# 4) Title + tagline, white with a subtle dark shadow for legibility
magick /tmp/fg_step.png \
  -gravity NorthWest -font DejaVu-Sans-Bold \
  -pointsize 72 -fill '#0A1F0E' -annotate +502+164 'Custom RR' \
  -pointsize 72 -fill white     -annotate +499+161 'Custom RR' \
  -pointsize 30 -fill '#0A1F0E' -annotate +506+286 'Custom ROMs, Recoveries' \
  -pointsize 30 -fill white     -annotate +504+284 'Custom ROMs, Recoveries' \
  -pointsize 30 -fill '#0A1F0E' -annotate +506+328 '& Treble GSIs' \
  -pointsize 30 -fill white     -annotate +504+326 '& Treble GSIs' \
  "$OUT"

identify -format 'feature graphic: %wx%h %m %b\n' "$OUT"
