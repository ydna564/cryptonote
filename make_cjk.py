#!/usr/bin/env python3
"""
Cryptonote CJK font generator (Chinese / Han).

Builds a scrambled font for CJK Unified Ideographs from Noto Sans SC, which is
licensed under the SIL Open Font License. Each Han character is drawn as the
outline of a different Han character, while the real codepoint is preserved, so
copy, paste and search still receive the true text.

Source font is downloaded on demand and is not committed. Only the generated
Cryptonote-CJK.ttf and the OFL license are kept in the repository.

Run from the repository root:  ~/.cryptonote-venv/bin/python make_cjk.py
"""
import os, random, urllib.request
from fontTools.ttLib import TTFont
from fontTools import subset
from fontTools.varLib.instancer import instantiateVariableFont

SRC_URL = "https://github.com/google/fonts/raw/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf"
SRC = "/tmp/NotoSC.ttf"
OUT = "/Users/mac/Cryptonote/Cryptonote-CJK.ttf"
LO, HI = 0x4E00, 0x9FFF        # CJK Unified Ideographs
SEED = 1337


def ensure_source():
    if not os.path.exists(SRC):
        print("Downloading Noto Sans SC (OFL)...")
        urllib.request.urlretrieve(SRC_URL, SRC)


def prepare_base():
    f = TTFont(SRC)
    instantiateVariableFont(f, {"wght": 400}, inplace=True)   # static Regular
    opts = subset.Options()
    opts.name_IDs = ["*"]
    opts.drop_tables += ["BASE"]
    ss = subset.Subsetter(options=opts)
    ss.populate(unicodes=list(range(LO, HI + 1)))
    ss.subset(f)
    # Round-trip through disk. The freshly instanced/subset object holds state
    # that discards cmap edits on save; reloading from disk clears it.
    tmp = "/tmp/_cryptonote_cjk_base.ttf"
    f.save(tmp)
    return TTFont(tmp)


def main():
    ensure_source()
    f = prepare_base()
    best = f["cmap"].getBestCmap()
    han = sorted(c for c in range(LO, HI + 1) if c in best)

    rng = random.Random(SEED)
    dst = list(han)
    while True:
        rng.shuffle(dst)
        if all(a != b for a, b in zip(han, dst)):
            break
    # Swap the glyph OUTLINES, leaving the cmap untouched. So character c keeps
    # its real codepoint (copy and paste stay correct) but is drawn with the
    # outline of another Han character d. This is done on glyf rather than the
    # cmap because a fully scattered cmap does not recompile reliably for this
    # font. Snapshot every source first, then write, so the permutation is clean.
    glyf, hmtx = f["glyf"], f["hmtx"]
    new_glyf = {best[c]: glyf[best[d]] for c, d in zip(han, dst)}
    new_hmtx = {best[c]: hmtx[best[d]] for c, d in zip(han, dst)}
    for gn, gl in new_glyf.items():
        glyf[gn] = gl
    for gn, mt in new_hmtx.items():
        hmtx[gn] = mt

    name = f["name"]
    def setn(i, v):
        name.setName(v, i, 3, 1, 0x409)
        name.setName(v, i, 1, 0, 0)
    for i, v in [(1, "CryptonoteCJK"), (2, "Regular"), (4, "CryptonoteCJK"),
                 (6, "CryptonoteCJK-Regular"), (3, "CryptonoteCJK-1337"),
                 (16, "CryptonoteCJK"), (17, "Regular")]:
        setn(i, v)

    f.save(OUT)
    print(f"Wrote {OUT}, scrambled {len(han)} Han characters.")

    # Verify. The cmap stays identity (real text preserved) while the drawn
    # outline for each character changes. Confirm both on the saved file.
    base = TTFont("/tmp/_cryptonote_cjk_base.ttf")
    out = TTFont(OUT)
    cmap_same = base["cmap"].getBestCmap()[ord("马")] == out["cmap"].getBestCmap()[ord("马")]
    def outline(fnt, ch):
        g = fnt["glyf"][fnt["cmap"].getBestCmap()[ord(ch)]]
        g.expand(fnt["glyf"])
        return tuple(getattr(g, "coordinates", ())) or getattr(g, "components", ())
    changed = [ch for ch in "马你北好世界" if outline(base, ch) != outline(out, ch)]
    print(f"  cmap preserved (real text intact): {cmap_same}")
    print(f"  outline scrambled for {len(changed)}/6 sample characters")


if __name__ == "__main__":
    main()
