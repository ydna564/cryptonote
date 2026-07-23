#!/usr/bin/env python3
"""
Cryptonote font generator.

Idea: the TEXT you type stays as real Unicode characters. We only change how
each character is DRAWN, by remapping the font's cmap so that the glyph shown
for 'a' is actually the outline of some other character. The bytes are never
touched, so copy/paste, search engines and every app receive the TRUE text.
Switch the display font back to a normal one and the same text reads normally.

This builds two things from one base monospace font (Menlo):
  Cryptonote.ttf   -> scrambled glyphs (screen shows gibberish)
The permutation is fixed (seeded) so it is deterministic and reversible.
"""
import sys, random
from fontTools.ttLib import TTFont
from fontTools.ttLib.ttCollection import TTCollection

BASE = "/System/Library/Fonts/Menlo.ttc"   # monospace, wide coverage
OUT  = "/Users/mac/Cryptonote/Cryptonote.ttf"
FAMILY = "Cryptonote"
SEED = 1337  # change this to get a different scramble

import string
LOWER = list("abcdefghijklmnopqrstuvwxyz")
UPPER = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
DIGIT = list("0123456789")

def build_perm():
    """Return dict char->char. Derangement-ish within each class so nothing
    maps to itself (every visible char changes)."""
    rnd = random.Random(SEED)
    perm = {}
    for group in (LOWER, UPPER, DIGIT):
        src = list(group)
        while True:
            dst = list(group)
            rnd.shuffle(dst)
            if all(a != b for a, b in zip(src, dst)):  # true derangement
                break
        for a, b in zip(src, dst):
            perm[a] = b
    return perm

def load_base():
    if BASE.endswith(".ttc"):
        coll = TTCollection(BASE)
        # pick the Regular face
        for f in coll.fonts:
            name = f["name"].getDebugName(4) or ""
            if "Regular" in name and "Bold" not in name and "Italic" not in name:
                return f
        return coll.fonts[0]
    return TTFont(BASE)

def rename(font, family):
    name = font["name"]
    # Set family, subfamily, full, postscript, unique across common IDs/platforms
    def setn(nameID, value):
        name.setName(value, nameID, 3, 1, 0x409)  # Windows Unicode English
        name.setName(value, nameID, 1, 0, 0)      # Mac Roman English
    setn(1, family)
    setn(2, "Regular")
    setn(4, family)
    setn(6, family.replace(" ", "") + "-Regular")
    setn(3, family + "-1337")          # unique id
    setn(16, family)
    setn(17, "Regular")

def main():
    perm = build_perm()
    font = load_base()

    # Collect original codepoint -> glyphName from the best unicode cmap
    cmap = font["cmap"]
    best = cmap.getBestCmap()  # {codepoint: glyphName}

    # Build the remap: for each source char c, we want codepoint(c) to point at
    # the glyph that currently draws perm[c].
    remap = {}
    for c, target in perm.items():
        cp_src = ord(c)
        gname_of_target = best.get(ord(target))
        if gname_of_target and cp_src in best:
            remap[cp_src] = gname_of_target

    # Apply to every unicode cmap subtable
    changed = 0
    for sub in cmap.tables:
        if sub.isUnicode():
            for cp, gname in remap.items():
                if cp in sub.cmap:
                    sub.cmap[cp] = gname
                    changed += 1

    rename(font, FAMILY)
    font.save(OUT)
    print(f"Wrote {OUT}")
    print(f"Remapped {len(remap)} codepoints, {changed} cmap entries.")
    # Print the mapping for reference
    print("Sample mapping (real -> shown-as glyph of):")
    for c in "hello elon musk 2024":
        if c in perm:
            print(f"   {c} -> {perm[c]}")

if __name__ == "__main__":
    main()
