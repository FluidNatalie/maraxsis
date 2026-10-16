#!/bin/bash

# Recolours the crude-oil sprites so that the near-black oil reads as glowing
# orange lava. Use this to make core lava's fork of the crude-oil graphics
# visually distinct from the vanilla oil patches it was copied from.
#
#   ./recolor-crude-oil-to-lava.sh FILE...
#
# This is a gradient map rather than a hue shift: crude oil has almost no
# saturation, so shifting its hue would leave it black. Instead each pixel's
# brightness is used as an index into an orange gradient, so the black body of
# the oil becomes bright orange and the pale grey vapour on top warms towards
# yellow, the way a lava flow is brighter where it is hottest. Alpha is left
# untouched, so the silhouette of the oil is preserved exactly.
#
# Run this on freshly copied vanilla sprites rather than on an already
# recoloured copy: a second pass would push the orange further towards yellow.
#
# With no arguments, the forked core-lava graphics (relative to this script)
# are processed in place.

# Gradient stops the greys are mapped through, brightest end last: the black of
# the oil lands on bright orange, midtones stay pure orange, and the white
# highlights come out pale yellow.
lut_lo="#ff6a00"
lut_mid="#ffa500"
lut_hi="#fff0b3"

set -euo pipefail

recolor() {
  local dir lut
  dir="$(mktemp -d)"
  lut="$dir/lut.png"

  # A 256px-wide lookup table: bright orange -> orange -> pale yellow.
  convert \
    \( -size 128x1 gradient:"$lut_lo-$lut_mid" \) \
    \( -size 128x1 gradient:"$lut_mid-$lut_hi" \) \
    +append "$lut"

  # Map every pixel's intensity through the table, keeping the original alpha.
  convert "$1" "$lut" -clut "$dir/out.png"

  mv "$dir/out.png" "$1"
  rm -rf "$dir"
}

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  files=(
    "$dir/entity/core-lava/core-lava.png"
    "$dir/entity/core-lava/core-lava-animation.png"
    "$dir/entity/core-lava/core-lava-smoke-inner.png"
    "$dir/entity/core-lava/core-lava-smoke-outer.png"
    "$dir/icons/core-lava-resource.png"
  )
fi

for f in "${files[@]}"; do
  recolor "$f"
done
