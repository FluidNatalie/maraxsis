#!/bin/bash

# Recolours the green parts of a PNG purple, leaving every other hue alone.
# Use this to make the fork of a sprite (e.g. the big pumpjack) visually
# distinct from the vanilla one it was copied from.
#
#   ./hue-shift-green-to-purple.sh FILE...
#
# Green pixels are found by hue and turned into purple, so the reds, oranges,
# blues and greys of the pumpjack sprites survive untouched. Saturation,
# lightness and alpha are preserved, and hues outside the green band come out
# unchanged.
#
# The lower edge fades in over many degrees on purpose: the yellow-green
# highlights sit just above src_lo and would otherwise jump straight from
# yellow-green to purple. A long lo_feather blends them into a yellow-purple
# that eases the transition. Because those pixels are only partly shifted they
# stay in the source band, so run this on the original green sprites rather than
# on an already-shifted copy (a second pass would push them further purple).
#
# With no arguments, the forked big pumpjack graphics (relative to this script)
# are processed in place.

# Hue band (degrees) that counts as "green", and the purple band it maps onto.
# Each edge fades out over its own number of degrees, which avoids a hard seam.
# lo_feather is much wider than hi_feather so that the yellow-green highlights
# (hues just above src_lo) fade gradually into purple instead of snapping to it.
src_lo=35
src_hi=135
dst_lo=255
dst_hi=305
lo_feather=45
hi_feather=16

# ImageMagick per-pixel function operating on the hue channel of an HSL image
# (u is the hue as a 0..1 fraction of the colour wheel; hlo/hhi/tlo/thi are the
# bands above expressed the same way).
#
# remap: the purple hue a pixel would get, based on where it sits in the band.
# mask:  how green a pixel is, from 0 outside the band to 1 inside it.
remap="hlo=$src_lo/360; hhi=$src_hi/360; tlo=$dst_lo/360; thi=$dst_hi/360;"
remap+=" frac=(u-hlo)/(hhi-hlo); frac=frac<0?0:(frac>1?1:frac);"
remap+=" tlo+frac*(thi-tlo)"

mask="hlo=$src_lo/360; hhi=$src_hi/360; wlo=$lo_feather/360; whi=$hi_feather/360;"
mask+=" ra=(u-hlo)/wlo; ra=ra<0?0:(ra>1?1:ra); ra=ra*ra*(3-2*ra);"
mask+=" rb=(u-hhi)/whi; rb=rb<0?0:(rb>1?1:rb); rb=rb*rb*(3-2*rb);"
mask+=" ra*(1-rb)"

set -euo pipefail

shift_green_to_purple() {
  local dir purpled greened
  dir="$(mktemp -d)"
  purpled="$dir/purpled.png"
  greened="$dir/greened.png"

  # A fully purple copy of the image.
  convert "$1" -colorspace HSL -channel R -fx "$remap" +channel -colorspace sRGB "$purpled"

  # A 0..1 mask of how green each pixel is.
  convert "$1" -colorspace HSL -channel R -separate +channel -fx "$mask" "$greened"

  # Mix the two in RGB space, not hue space: partly green pixels then fade
  # straight from green to purple instead of sweeping through blue. Compositing
  # would also bake the mask into the alpha, so the original alpha is put back.
  convert "$1" \
    \( "$purpled" "$greened" -compose CopyOpacity -composite \) \
    -compose Over -composite \
    \( "$1" -alpha extract \) -compose CopyOpacity -composite \
    "$dir/out.png"

  mv "$dir/out.png" "$1"
  rm -rf "$dir"
}

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  files=(
    "$dir/entity/big-pumpjack/big-pumpjack-base.png"
    "$dir/entity/big-pumpjack/big-pumpjack-base-flipped.png"
    "$dir/entity/big-pumpjack/big-pumpjack-horsehead.png"
    "$dir/entity/big-pumpjack/remnants/big-pumpjack-remnants.png"
    "$dir/icons/big-pumpjack.png"
    "$dir/technology/big-pumpjack.png"
  )
fi

for f in "${files[@]}"; do
  shift_green_to_purple "$f"
done
