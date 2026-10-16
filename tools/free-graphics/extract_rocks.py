#!/usr/bin/env python3
"""extract_rocks.py - split a sprite sheet into individual rock sprites.

The snouz catalog strips prototype data, so sheets arrive without their
sprite rectangles. We recover them by connected-component labelling of the
alpha channel, then emit one tightly cropped PNG per rock plus the centre
offset (relative to the sheet centre) needed to place it via `shift`.

Usage: python3 extract_rocks.py SHEET.png OUTDIR NAME [--min-area N] [--min-dim N]
"""

import argparse
import os
import sys

from PIL import Image


def components(alpha, w, h, min_area):
    seen = bytearray(w * h)
    px = alpha.load()
    out = []
    for sy in range(h):
        for sx in range(w):
            if seen[sy * w + sx] or px[sx, sy] == 0:
                continue
            stack = [(sx, sy)]
            seen[sy * w + sx] = 1
            area = 0
            x0 = x1 = sx
            y0 = y1 = sy
            while stack:
                x, y = stack.pop()
                area += 1
                x0, x1 = min(x0, x), max(x1, x)
                y0, y1 = min(y0, y), max(y1, y)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and px[nx, ny]:
                            seen[ny * w + nx] = 1
                            stack.append((nx, ny))
            if area >= min_area:
                out.append((x0, y0, x1, y1, area))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet")
    ap.add_argument("outdir")
    ap.add_argument("name")
    ap.add_argument("--min-area", type=int, default=120)
    ap.add_argument("--min-dim", type=int, default=12)
    args = ap.parse_args()

    im = Image.open(args.sheet).convert("RGBA")
    w, h = im.size
    os.makedirs(args.outdir, exist_ok=True)
    comps = components(im.split()[3], w, h, args.min_area)
    kept = 0
    for x0, y0, x1, y1, area in sorted(comps, key=lambda c: -c[4]):
        cw, ch = x1 - x0 + 1, y1 - y0 + 1
        if cw < args.min_dim or ch < args.min_dim:
            continue
        kept += 1
        crop = im.crop((x0, y0, x1 + 1, y1 + 1))
        out = os.path.join(args.outdir, f"{args.name}-{kept}.png")
        crop.save(out)
        cx = (x0 + x1) / 2 - (w - 1) / 2
        cy = (y0 + y1) / 2 - (h - 1) / 2
        print(f"{out}  {cw}x{ch}  centre_offset=({cx:+.1f},{cy:+.1f})px  area={area}")
    print(f"-- {kept} rock(s) from {len(comps)} component(s)", file=sys.stderr)


if __name__ == "__main__":
    main()
