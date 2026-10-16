#!/usr/bin/env python3
"""make_icon.py - build Maraxsis-style icon sheets from catalog art.

Maraxsis (like vanilla 2.x) ships multi-scale icon sheets rather than a single
64px image, so every source icon is expanded to the house layout:

    item / recipe / fluid : 120x64   -> 64px @ (0,0), 32px @ (64,0), 24px @ (96,0)
    technology            : 480x256  -> 256px @ (0,0), 128px @ (256,0), 96px @ (384,0)

Factorio samples only the top-left cell (icon_size 64 / 256), but the reduced
copies are what every other icon in the repo and in base ships, so we match them.

Subcommands
-----------
  expand  SRC DEST --kind item|tech [--tint #RRGGBB:0.3]
  compose DEST --kind item|tech --layer SRC:X:Y:SIZE [--layer ...] [--tint ...]

Layer syntax is SRC:X:Y:SIZE, where X/Y are the top-left pixel of the placed
layer inside the *full-size cell* (item 64px / tech 256px) and SIZE is the width
of the layer in that same space (aspect ratio is preserved; omit SIZE for the
cell size). Composing is how the vanilla melting icons read (ore + molten pour),
so recipes that lack a single matching asset are built from two catalog pieces.

--tint blends a flat colour over the finished sheet, keeping the alpha channel
and therefore the original shading. It is how a catalog icon is nudged onto a
mod's palette without redrawing it; record the colour and amount in CREDITS.md
under "Changes".
"""

import argparse
import os
import sys

from PIL import Image

LAYOUTS = {
    "item": (120, 64, [64, 32, 24], [0, 64, 96]),
    "tech": (480, 256, [256, 128, 96], [0, 256, 384]),
}
SHEET_SIZES = {(120, 64), (480, 256)}


def top_left_cell(img, kind):
    """Take the top-left icon cell, handling both plain icons and existing sheets."""
    _cw, _ch, sizes, _xs = LAYOUTS[kind]
    cell = sizes[0]
    if img.size in SHEET_SIZES:          # already a house sheet - reuse its main cell
        return img.crop((0, 0, cell, cell))
    if img.size == (cell, cell):
        return img
    fitted = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))   # off-size art: top-left aligned
    fitted.paste(img.crop((0, 0, cell, cell)), (0, 0))
    return fitted


def expand(img, kind):
    """Lay out the icon at full size plus its reduced copies, the way base does."""
    cw, ch, sizes, xs = LAYOUTS[kind]
    cell = top_left_cell(img, kind)
    out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    for size, x in zip(sizes, xs):
        out.paste(cell if size == sizes[0] else cell.resize((size, size), Image.LANCZOS), (x, 0))
    return out


def fit(img, size):
    """Scale `img` to `size` wide, preserving aspect (never upscales past 1:1 by default)."""
    w, h = img.size
    scale = size / w
    return img.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)


def apply_tint(img, spec):
    """Blend a flat colour over the art, keeping the alpha channel and its shading.

    `spec` is "#RRGGBB:AMOUNT" (e.g. "#9FD8BE:0.3"): the result is `img` moved
    AMOUNT of the way towards the colour, so the highlights and shadows survive
    and the icon reads as the same material in another palette.
    """
    colour, _, amount = spec.partition(":")
    amount = float(amount) if amount else 1.0
    r, g, b = (int(colour.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
    solid = Image.new("RGBA", img.size, (r, g, b, 0))
    solid.putalpha(img.getchannel("A"))          # tint only where the art is
    return Image.blend(img, solid, amount)


def compose(kind, layers):
    cw, ch, sizes, _xs = LAYOUTS[kind]
    cell = Image.new("RGBA", (sizes[0], sizes[0]), (0, 0, 0, 0))
    for src, x, y, size in layers:
        img = Image.open(src).convert("RGBA")
        if img.size in SHEET_SIZES:      # strip the reduced copies off an existing sheet
            img = img.crop((0, 0, sizes[0], sizes[0]))
        if size:
            img = fit(img, size)
        cell.alpha_composite(img, (x, y))
    return expand(cell, kind)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("expand")
    p.add_argument("src")
    p.add_argument("dest")
    p.add_argument("--kind", choices=LAYOUTS, default="item")

    p = sub.add_parser("compose")
    p.add_argument("dest")
    p.add_argument("--kind", choices=LAYOUTS, default="item")
    p.add_argument("--layer", action="append", required=True,
                   help="SRC:X:Y:SIZE (SIZE optional, in cell pixels)")

    for name in ("expand", "compose"):
        sub.choices[name].add_argument("--tint", metavar="#RRGGBB:AMOUNT",
                                       help="blend a flat colour over the art")

    args = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.dest)), exist_ok=True)
    if args.cmd == "expand":
        img = Image.open(args.src).convert("RGBA")
        out = expand(img, args.kind)
    else:
        layers = []
        for spec in args.layer:
            parts = spec.rsplit(":", 3)
            if len(parts) == 4:
                src, x, y, size = parts[0], int(parts[1]), int(parts[2]), int(parts[3])
            else:
                src, x, y, size = parts[0], int(parts[1]), int(parts[2]), None
            layers.append((src, x, y, size))
        out = compose(args.kind, layers)
    if args.tint:
        out = apply_tint(out, args.tint)
    out.save(args.dest)
    print(f"{args.dest}  {out.size[0]}x{out.size[1]}")


if __name__ == "__main__":
    main()
