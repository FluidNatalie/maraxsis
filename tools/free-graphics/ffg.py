#!/usr/bin/env python3
"""ffg.py - selective fetcher for snouz/factorio_free_graphics_for_modders.

Upstream is ~7.4 GB / 29k files, so nothing is ever cloned wholesale. This caches
the git tree manifest + README, resolves a license for every path (from the
in-path "(LICENSE)" tag, else from the README mod list), then downloads only the
files that survive the filters.

Commands
--------
  update                       refresh cached manifest + README
  stats                        tier coverage + how licenses were resolved
  packs    [filters]           group matches by source pack (browsing view)
  list     [filters]           show matching paths (no download)
  fetch    [filters] --out DIR download matches (+ manifest.json provenance)
  dims     [filters]           PNG dimensions via HTTP Range (no save)
  credits  --manifest FILE     emit CREDITS.md-ready markdown

Cache and downloads default to `.cache/` next to this file and are gitignored;
set FFG_CACHE to move them. `fetch`/`credits` default to `<cache>/downloads/`.

Filters
-------
  --match REGEX / --exclude REGEX   filename regex
  --path PREFIX               path must start with this
  --ext png,ogg               extension allow-list
  --tier permissive|noncommercial|copyleft|restricted|all     (default permissive)
  --license "MIT,CC BY"       explicit license values (overrides --tier)
  --min-bytes N / --max-bytes N / --limit N
  --explain / --json

Tiers
-----
  permissive      MIT, CC BY, CC0, public domain, Apache, Mozilla, WTFPL
  noncommercial   anything NC (free to play, forbids monetisation)
  copyleft        GPL/LGPL, CC BY-SA - would relicense this MIT mod
  restricted      Wube's EULA, "ASK ... FOR PERMISSION", unclear/AI/unknown

Anything whose tier cannot be established stays `unknown` and is NEVER fetched
under the default `--tier permissive`. The catalog is a preview set: animations,
rotations, shadows and masks are stripped upstream, so results are icon/kitbash
sources, not drop-in sprites.
"""

import argparse
import collections
import hashlib
import json
import os
import re
import sys
import urllib.parse
import urllib.request

REPO = "snouz/factorio_free_graphics_for_modders"
BRANCH = "main"
RAW = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}/"
API_TREE = f"https://api.github.com/repos/{REPO}/git/trees/{BRANCH}?recursive=1"

# Everything the tool writes lives under CACHE_DIR: the checkout stays clean and
# there is nothing to clean up by hand. Set FFG_CACHE to put it elsewhere (a
# tmpfs, a bigger disk) - the cache is ~2 MB, the downloads are not.
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE_DIR = os.environ.get("FFG_CACHE", os.path.join(HERE, ".cache"))
TREE_CACHE = os.path.join(CACHE_DIR, "tree.json")
README_CACHE = os.path.join(CACHE_DIR, "README.md")
OVERRIDES = os.path.join(CACHE_DIR, "license_overrides.json")
DOWNLOADS = os.path.join(CACHE_DIR, "downloads")
MANIFEST = os.path.join(DOWNLOADS, "manifest.json")

TIER_ORDER = {"permissive": 0, "noncommercial": 1, "copyleft": 2, "restricted": 3, "unknown": 4}

# Hint strings are compared against a separator-normalised lowercase license text,
# so write them with plain spaces (never hyphens/slashes).
PERMISSIVE_HINTS = ("mit", "cc by", "cc zero", "cc0", "public domain", "apache",
                    "mozilla", "wtfpl", "do what the fuck", "unlicense", "bsd", "ofl")
COPYLEFT_HINTS = ("gpl", "cc by sa", "share alike")
RESTRICTED_HINTS = ("wube", "eula", "turbosquid", "original license", "unclear",
                    "no derivative", "all rights reserved")

# Irreducible name mismatches between filename packs and README entries.
ALIASES = {
    "apm resource pack": "amator phasma resource pack",
    "amator phasma resource pack": "amator phasma resource pack",
    "arch666angel": "angels",
    "angel s": "angels",
    "angel s mods": "angels",
    "bioindustries": "bio industries",
    "bio industries old": "bio industries",
    "natural evolution": "bio industries",
    "yuoki s mods": "yuokitani s mods",
    "yuoki mods": "yuokitani s mods",
    "yuoki industries": "yuokitani s mods",
    "yuokitani": "yuokitani s mods",
    "old vanilla": "wube",
    "brevven mods": "brevven s mods",
    "malcolmriley unused renders": "malcolmriley s unused renders",
    "hurricane046 buildings": "hurricane046 s buildings",
    "factorio plus": "factorioplus",
    "krastorio1": "krastorio 1",
    "krastorio2": "krastorio 2",
    "exotic space industries": "exotic space industries",
    "se space trains": "space exploration space trains",
    "moshine": "moshine assets",
    "realistic fusion power": "realistic fusion power",
}

WUBE_PACKS = {"factorio", "factorio 0 12", "factorio 0 14", "factorio 0 7", "old vanilla"}

_TREE = _README_TABLE = _OVERRIDES = None


def norm(name):
    name = name.strip().lower().replace("\u2019", " ").replace("'", " ")
    name = re.sub(r"\([^)]*\)", " ", name)            # drop "(MIT)" / "(old)" tags
    name = re.sub(r"[^a-z0-9]+", " ", name)
    return re.sub(r"\s+", " ", name).strip()


def compact(name):
    return norm(name).replace(" ", "")


def singular(tok):
    return tok[:-1] if len(tok) > 4 and tok.endswith("s") else tok


def http_get(url, headers=None, timeout=60):
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


def cmd_update(_args):
    os.makedirs(CACHE_DIR, exist_ok=True)
    print("fetching tree manifest ...", file=sys.stderr)
    data = json.loads(http_get(API_TREE, {"User-Agent": "ffg-fetcher"}))
    with open(TREE_CACHE, "w") as fh:
        json.dump(data, fh)
    print(f"  {len(data['tree'])} objects, truncated={data.get('truncated')}", file=sys.stderr)
    print("fetching README ...", file=sys.stderr)
    with open(README_CACHE, "wb") as fh:
        fh.write(http_get(RAW + "README.md"))
    print("done", file=sys.stderr)


def load_tree():
    global _TREE
    if _TREE is None:
        if not os.path.exists(TREE_CACHE):
            sys.exit("no cached manifest - run: ffg.py update")
        with open(TREE_CACHE) as fh:
            _TREE = json.load(fh)
    return _TREE


LINK = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def load_readme_licenses():
    """README mod list -> {normalized pack name: {license, authors, url}}.

    Handles every entry shape the README actually uses:
      - [Name](url) | license | authors
      - [Name](a) [graphics](b) | license | authors
      - Plain Name: [1](a) [2](b) | license | authors
      - YuokiTani's mods: [Industries](a) ... | CC BY-NC-SA 4.0 / MIT | YuokiTani
    """
    global _README_TABLE
    if _README_TABLE is not None:
        return _README_TABLE
    table = {}
    if not os.path.exists(README_CACHE):
        _README_TABLE = table
        return table
    with open(README_CACHE, encoding="utf-8") as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if not line.startswith("- ") or "|" not in line:
                continue                       # dependency-only bullets carry no license
            fields = [f.strip() for f in line[2:].split("|")]
            if len(fields) < 2 or not fields[1]:
                continue
            name_field, license_, authors = fields[0], fields[1], (fields[2] if len(fields) > 2 else "")
            links = LINK.findall(name_field)
            url = links[0][1] if links else ""
            names = [n for n, _ in links]
            plain = LINK.sub("", name_field).strip().rstrip(":").strip()
            if plain:
                names.append(plain)            # "YuokiTani's mods: [Industries]..." -> also key the prefix
            if not names:
                continue
            rec = {"license": license_, "authors": authors, "url": url}
            for name in names:
                key = norm(name)
                if key:
                    table.setdefault(key, rec)
    _README_TABLE = table
    return table


def load_overrides():
    global _OVERRIDES
    if _OVERRIDES is None:
        _OVERRIDES = {}
        if os.path.exists(OVERRIDES):
            with open(OVERRIDES) as fh:
                _OVERRIDES = json.load(fh)
    return _OVERRIDES


def readme_lookup(pack, table):
    """Match a filename pack name against README entries, tolerating plurals/casing.

    Returns (record, matched_entry_name) or (None, ""). Substring and token
    matches must clear a similarity floor, so e.g. pack "Factorio 2 Core" does
    not silently inherit the license of the README entry "Factorio".
    """
    key = norm(pack)
    if not key:
        return None, ""
    key = ALIASES.get(key, key)
    if key in table:
        return table[key], key
    ckey = key.replace(" ", "")
    best, best_name, best_score = None, "", 0.0
    for name, rec in table.items():
        cname = name.replace(" ", "")
        if cname == ckey:
            return rec, name
        a = {singular(t) for t in key.split()}
        b = {singular(t) for t in name.split()}
        if not a or not b:
            continue
        # Majority-token overlap, normalised by the LONGER name, so a short
        # one-token README entry cannot absorb any pack that merely contains it
        # (this is what previously let "Factorio 2 Core" inherit "Factorio+"'s MIT).
        score = len(a & b) / max(len(a), len(b))
        if score >= 0.6 and score > best_score:
            best, best_name, best_score = rec, name, score
    return best, best_name


STRONG_PERMISSIVE = ("mit", "cc0", "cc zero", "public domain", "wtfpl", "do what the fuck",
                     "unlicense", "bsd", "apache", "mozilla")


def tier_of(license_str):
    """Normalise separators, then classify: NC > restricted > strong-permissive > copyleft."""
    low = re.sub(r"[-_/]", " ", (license_str or "").lower())
    if re.search(r"\bask(ed|ing)?\b", low) or "permission" in low:
        return "restricted"
    if re.search(r"(^|[^a-z])nc([^a-z]|$)", low) or "non commercial" in low or "noncommercial" in low:
        return "noncommercial"
    if any(h in low for h in RESTRICTED_HINTS):
        return "restricted"
    if any(h in low for h in STRONG_PERMISSIVE):
        return "permissive"       # e.g. "MIT / CC-BY-SA" - we would take the MIT option
    if any(h in low for h in COPYLEFT_HINTS):
        return "copyleft"
    if any(h in low for h in PERMISSIVE_HINTS):
        return "permissive"
    return "unknown"


PATH_LICENSE = re.compile(
    r"\(([^()]*(?:MIT|CC BY[^()]*|CC0|GNU [^()]*|LGPL[^()]*|GPL[^()]*|Apache[^()]*|"
    r"Mozilla[^()]*|Public Domain|Wube|EULA|WTFPL|Do What[^()]*)[^()]*)\)")


def resolve(path):
    """Best-effort {pack, license, source, tier, authors, url} for a repo path."""
    rec = {"pack": "", "license": "", "source": "", "tier": "unknown",
           "authors": "", "url": "", "matched": ""}

    up = path.upper()
    if "ASK " in up and "PERMISSION" in up:
        rec.update(pack=path.rsplit("/", 1)[-1].split(" - ")[0].strip(),
                   license="ASK FOR PERMISSION", source="path-marker", tier="restricted")
        return rec
    if path.startswith("\u03a8 generated by AI"):
        ai_pack = re.sub(r"\([^)]*\)", "", path.rsplit("/", 1)[-1].split(" - ")[0]).strip()
        rec.update(pack=ai_pack, license="AI-generated (provenance unclear)",
                   source="ai-folder", tier="unknown")
        return rec

    fname = path.rsplit("/", 1)[-1]
    pack = fname.split(" - ")[0].strip()

    m = PATH_LICENSE.search(fname) or PATH_LICENSE.search(path)
    if m:
        rec["license"], rec["source"] = m.group(1), "path-tag"
    if not rec["license"]:
        for seg in path.split("/")[:-1]:
            m = PATH_LICENSE.search(seg)
            if m:
                rec["license"], rec["source"] = m.group(1), "dir-tag"
                break
    rec["pack"] = re.sub(r"\([^)]*\)", "", pack).strip() or pack

    if rec["pack"].startswith("_"):
        rec["pack"] = rec["pack"].lstrip("_").replace("-", " ").strip()
    if norm(rec["pack"]) in WUBE_PACKS:
        rec.update(pack="Factorio (Wube)", license="Wube's EULA", authors="Wube",
                   source="wube-rule", tier="restricted")
        return rec

    if rec["license"]:
        rec["tier"] = tier_of(rec["license"])
    else:
        hit, matched = readme_lookup(rec["pack"], load_readme_licenses())
        if hit:
            rec.update(license=hit["license"], authors=hit["authors"], url=hit["url"],
                       source="readme", matched=matched)
            rec["tier"] = tier_of(rec["license"])
            if path.startswith("\u03a8 upscaled by snouz/") and rec["tier"] == "permissive":
                rec["authors"] = (rec["authors"] + ", snouz (reworked)").strip(", ")

    if not rec["license"] and path.startswith("\u03a8"):
        rec.update(license="original license (reworked by snouz)", source="upscaled", tier="unknown")

    ov = load_overrides().get(path) or load_overrides().get(rec["pack"])
    if ov:
        rec.update(ov)
        rec["source"] = "override"
        rec["tier"] = ov.get("tier", tier_of(rec.get("license", "")))
    return rec


def iter_matches(args):
    tree = load_tree()
    blobs = [t for t in tree["tree"] if t["type"] == "blob"]
    exts = [e.strip().lower().lstrip(".") for e in args.ext.split(",")] if args.ext else None
    match_re = re.compile(args.match, re.I) if args.match else None
    exclude_re = re.compile(args.exclude, re.I) if args.exclude else None
    want = [l.strip().lower() for l in args.license.split(",")] if args.license else None
    out = []
    for t in blobs:
        path, size = t["path"], t.get("size", 0)
        if args.path and not path.startswith(args.path):
            continue
        if exts and path.rsplit(".", 1)[-1].lower() not in exts:
            continue
        if match_re and not match_re.search(path):
            continue
        if exclude_re and exclude_re.search(path):
            continue
        if args.min_bytes and size < args.min_bytes:
            continue
        if args.max_bytes and size > args.max_bytes:
            continue
        rec = resolve(path)
        if want:
            if rec["license"].lower() not in want:
                continue
        elif args.tier != "all":
            tier = rec["tier"]
            if tier == "unknown" or TIER_ORDER[tier] > TIER_ORDER[args.tier]:
                continue
        out.append((path, size, rec))
        if args.limit and len(out) >= args.limit:
            break
    return out


def cmd_stats(_args):
    blobs = [t for t in load_tree()["tree"] if t["type"] == "blob"]
    tiers, sources = collections.Counter(), collections.Counter()
    for t in blobs:
        rec = resolve(t["path"])
        tiers[rec["tier"]] += 1
        sources[rec["source"] or "unresolved"] += 1
    total = len(blobs)
    print(f"{total} files")
    for k, v in tiers.most_common():
        print(f"  {v:7d}  {v / total:5.1%}  {k}")
    print("  described by: " + ", ".join(f"{k}={v}" for k, v in sources.most_common()))


def cmd_packs(args):
    rows = iter_matches(args)
    groups = collections.defaultdict(lambda: {"n": 0, "bytes": 0, "pack": "", "license": "", "tier": ""})
    for path, size, rec in rows:
        g = groups[rec["pack"] or "<none>"]
        g["n"] += 1
        g["bytes"] += size
        g["pack"], g["license"], g["tier"] = rec["pack"], rec["license"], rec["tier"]
    for name, g in sorted(groups.items(), key=lambda kv: -kv[1]["n"]):
        print(f"{g['n']:5d} files {g['bytes'] / 1e6:8.1f} MB  [{g['tier']:12}] {name}  <- {g['license']}")
    print(f"-- {len(groups)} pack(s), {len(rows)} file(s)", file=sys.stderr)


def cmd_list(args):
    rows = iter_matches(args)
    if args.json:
        print(json.dumps([{"path": p, "bytes": s, **r} for p, s, r in rows], indent=2))
        return
    for path, size, rec in rows:
        extra = ""
        if args.explain:
            extra = f"  [{rec['license']} / {rec['tier']} via {rec['source']}"
            if rec.get("matched"):
                extra += f" (readme:{rec['matched']})"
            extra += "]"
        print(f"{size / 1024:9.0f} KB  {path}{extra}")
    print(f"-- {len(rows)} match(es)", file=sys.stderr)


def cmd_fetch(args):
    rows = iter_matches(args)
    out = args.out
    os.makedirs(out, exist_ok=True)
    manifest_path = os.path.join(out, "manifest.json")
    manifest = []
    if os.path.exists(manifest_path):
        with open(manifest_path) as fh:
            manifest = json.load(fh)
    known = {m["path"] for m in manifest}
    for path, _size, rec in rows:
        target = os.path.join(out, path.split("/")[-1])
        if os.path.exists(target):
            stem, ext = os.path.splitext(target)
            n = 2
            while os.path.exists(f"{stem}~{n}{ext}"):
                n += 1
            target = f"{stem}~{n}{ext}"
        url = RAW + urllib.parse.quote(path)
        blob = http_get(url)
        with open(target, "wb") as fh:
            fh.write(blob)
        print(f"{len(blob) / 1024:9.0f} KB -> {target}")
        if path not in known:
            manifest.append({
                "path": path, "url": url, "local": os.path.basename(target),
                "bytes": len(blob), "sha256": hashlib.sha256(blob).hexdigest(),
                "pack": rec["pack"], "license": rec["license"], "tier": rec["tier"],
                "license_source": rec["source"], "authors": rec["authors"],
                "source_url": rec["url"],
            })
            known.add(path)
    with open(manifest_path, "w") as fh:
        json.dump(manifest, fh, indent=2)
    print(f"-- {len(rows)} downloaded, manifest now {len(manifest)} entr(ies): {manifest_path}", file=sys.stderr)


def png_dims(blob):
    if blob[:8] != b"\x89PNG\r\n\x1a\n" or len(blob) < 24:
        return None
    return (int.from_bytes(blob[16:20], "big"), int.from_bytes(blob[20:24], "big"))


def cmd_dims(args):
    rows = iter_matches(args)
    for path, size, _rec in rows:
        dims = None
        try:
            dims = png_dims(http_get(RAW + urllib.parse.quote(path), {"Range": "bytes=0-31"}, timeout=30))
        except Exception as exc:                       # noqa: BLE001
            print(f"ERR {path}: {exc}", file=sys.stderr)
        label = f"{dims[0]}x{dims[1]}" if dims else "?"
        print(f"{label:>12}  {size / 1024:8.0f} KB  {path}")
    print(f"-- {len(rows)} probed", file=sys.stderr)


def cmd_credits(args):
    with open(args.manifest) as fh:
        manifest = json.load(fh)
    packs = collections.OrderedDict()
    for m in manifest:
        packs.setdefault((m["pack"], m["license"], m["authors"]), []).append(m)
    lines = ["### Credits", ""]
    for (pack, license_, authors), items in sorted(packs.items()):
        url = next((i["source_url"] for i in items if i.get("source_url")), "")
        lines += [
            f"#### {pack}",
            "",
            f"- **Creators**: {authors or 'see upstream README'}",
            f"- **Source**: {url or '(catalog: ' + REPO + ')'}",
            f"- **License**: {license_}",
            f"- **Tier**: {items[0]['tier']}",
            "- **Changes**: <describe edits, or 'No.'>",
            f"- **Files**: {len(items)} (`{items[0]['local']}`{', ...' if len(items) > 1 else ''})",
            "",
        ]
    print("\n".join(lines))


def build_parser():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    simple = {"update": cmd_update, "stats": cmd_stats}
    filt = {"packs": cmd_packs, "list": cmd_list, "fetch": cmd_fetch, "dims": cmd_dims}
    for name, fn in {**simple, **filt}.items():
        p = sub.add_parser(name, help=(fn.__doc__ or "").split("\n")[0])
        p.set_defaults(func=fn)
        if name in simple:
            continue
        p.add_argument("--match")
        p.add_argument("--exclude")
        p.add_argument("--path")
        p.add_argument("--ext")
        p.add_argument("--tier", default="permissive",
                       choices=["permissive", "noncommercial", "copyleft", "restricted", "all"])
        p.add_argument("--license")
        p.add_argument("--min-bytes", type=int)
        p.add_argument("--max-bytes", type=int)
        p.add_argument("--limit", type=int)
        p.add_argument("--explain", action="store_true")
        p.add_argument("--json", action="store_true")
        if name == "fetch":
            p.add_argument("--out", default=DOWNLOADS)
    p = sub.add_parser("credits", help="emit CREDITS.md-ready markdown")
    p.add_argument("--manifest", default=MANIFEST)
    p.set_defaults(func=cmd_credits)
    return ap


if __name__ == "__main__":
    args = build_parser().parse_args()
    args.func(args)
