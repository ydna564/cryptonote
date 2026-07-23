#!/usr/bin/env python3
"""
Cryptonote font generator.

The TEXT you type stays as real Unicode characters. We only change how each
character is DRAWN, by remapping the font's cmap so the glyph shown for one
character is actually the outline of another. The bytes are never touched, so
copy/paste, search engines and every app receive the TRUE text. Switch the
display font back to a normal one and the same text reads normally.

Coverage. The base font (Menlo) carries glyphs for Latin, Greek and Cyrillic,
so those scripts are scrambled. That covers a large share of the world's most
spoken languages that use these scripts. English, Spanish, Portuguese, French,
German, Italian, Polish, Turkish, Vietnamese, Indonesian, Russian, Ukrainian,
Greek and many more. Scripts the base font does not contain (CJK, Arabic,
Devanagari) are left untouched, because a glyph the font lacks would fall back
to a system font and render as the real character.
"""
import random, unicodedata
from fontTools.ttLib import TTFont
from fontTools.ttLib.ttCollection import TTCollection

BASE = "/System/Library/Fonts/Menlo.ttc"   # monospace, Latin + Greek + Cyrillic
OUT  = "/Users/mac/Cryptonote/Cryptonote.ttf"
FAMILY = "Cryptonote"
SEED = 1337  # change to reshuffle everything

# Basic ASCII classes, kept exactly as the original build (stable mapping).
LOWER = list("abcdefghijklmnopqrstuvwxyz")
UPPER = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
DIGIT = list("0123456789")

# Extra script ranges to scramble, by (name, lo, hi, seed offset).
SCRIPTS = [
    ("Latin accents",      0x00C0, 0x024F, 1),
    ("Latin extended add", 0x1E00, 0x1EFF, 2),   # Vietnamese and friends
    ("Greek",              0x0370, 0x03FF, 3),
    ("Cyrillic",           0x0400, 0x04FF, 4),
]


def derange(items, rng):
    """Return a shuffled copy with no element in its original position."""
    if len(items) < 2:
        return list(items)
    while True:
        shuffled = list(items)
        rng.shuffle(shuffled)
        if all(a != b for a, b in zip(items, shuffled)):
            return shuffled


def build_basic():
    """The original ASCII permutation. Unchanged so existing output is stable."""
    rnd = random.Random(SEED)
    perm = {}
    for group in (LOWER, UPPER, DIGIT):
        dst = derange(group, rnd)
        for a, b in zip(group, dst):
            perm[a] = b
    return perm


def load_base():
    coll = TTCollection(BASE)
    for f in coll.fonts:
        name = f["name"].getDebugName(4) or ""
        if "Regular" in name and "Bold" not in name and "Italic" not in name:
            return f
    return coll.fonts[0]


def rename(font, family):
    name = font["name"]
    def setn(nameID, value):
        name.setName(value, nameID, 3, 1, 0x409)
        name.setName(value, nameID, 1, 0, 0)
    setn(1, family); setn(2, "Regular"); setn(4, family)
    setn(6, family.replace(" ", "") + "-Regular")
    setn(3, family + "-1337"); setn(16, family); setn(17, "Regular")


def main():
    font = load_base()
    best = font["cmap"].getBestCmap()   # {codepoint: glyphName}

    # Codepoint -> codepoint remap. Start with the stable ASCII permutation.
    remap_cp = {ord(a): ord(b) for a, b in build_basic().items()}

    # Add each extra script, permuting letters within their own case class so
    # only characters the font actually contains are involved.
    for label, lo, hi, off in SCRIPTS:
        rng = random.Random(SEED + off)
        letters = [c for c in range(lo, hi + 1)
                   if c in best and unicodedata.category(chr(c)).startswith("L")]
        upper = [c for c in letters if unicodedata.category(chr(c)) == "Lu"]
        lower = [c for c in letters if unicodedata.category(chr(c)) == "Ll"]
        other = [c for c in letters if c not in set(upper) | set(lower)]
        for group in (upper, lower, other):
            for src, dst in zip(group, derange(group, rng)):
                remap_cp[src] = dst

    # Translate to glyph names and apply to every unicode cmap subtable.
    remap = {cp: best[dst] for cp, dst in remap_cp.items()
             if cp in best and dst in best}
    changed = 0
    for sub in font["cmap"].tables:
        if sub.isUnicode():
            for cp, gname in remap.items():
                if cp in sub.cmap:
                    sub.cmap[cp] = gname
                    changed += 1

    rename(font, FAMILY)
    font.save(OUT)
    print(f"Wrote {OUT}")
    print(f"Remapped {len(remap)} codepoints, {changed} cmap entries.")


if __name__ == "__main__":
    main()
