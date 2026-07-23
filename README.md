<div align="center">

# 🔒 Cryptonote

### Type in plain sight. Let the screen lie for you.

**Cryptonote scrambles what appears on your screen while every app, search box, and your clipboard receive the *real* text.** Shoulder-surfers see nonsense; your work stays correct. Flip the mode off and the same text reveals itself.

<br>

`type: how many money does elon musk has`
`screen shows: igl dhqr dgqcr ygck cugq dvkz ihk`
`app receives: how many money does elon musk has`

<br>

![platform](https://img.shields.io/badge/platform-macOS%2012%2B-000000?style=flat-square)
![language](https://img.shields.io/badge/Swift-6.1-F05138?style=flat-square)
![font](https://img.shields.io/badge/font-fontTools-2A7?style=flat-square)
![license](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

</div>

---

## Why

You're on a train, in a café, in an open office. Someone glances at your screen — a password hint, a private search, a message they shouldn't read. **Cryptonote** makes anything you type render as unreadable glyphs, without changing a single byte of the underlying text. The search still runs. The note still saves. The clipboard still pastes the truth. Only the *pixels* lie.

## How it actually works

There is **no supported way on macOS** to make an arbitrary app draw text differently from what it holds — apps render their own buffers, and System Integrity Protection blocks injecting a display filter into other processes. So Cryptonote doesn't touch your text at all.

**It changes the _font_, not the text.**

`Cryptonote.ttf` is an ordinary font whose glyph table is remapped: the outline drawn for `a` is secretly some other letter's outline. The character `a` is still really `a` in memory.

```
 you type    "a"  "b"  "c"  "d"  "e"  "f"  ...   real Unicode, untouched
                │    │    │    │    │    │
 font draws    ▼    ▼    ▼    ▼    ▼    ▼
              "q"  "x"  "k"  "j"  "c"  "m"  ...   scrambled glyphs on screen
```

The consequences fall out for free:

| | Result |
|---|---|
| 👁️ **Screen** | scrambled glyphs — a glance reveals nothing |
| 📋 **Copy / paste** | the true characters |
| 🔍 **Search engines / forms** | the true query |
| 💾 **Save to disk** | the true text |
| 🔓 **"Turn off the mode"** | switch the display font back — same text, now readable |

The scramble is a fixed, seeded derangement (every visible character maps to a *different* one), so it is deterministic and perfectly reversible.

## Two ways to use it

### 1 · The font — for editors and documents

Install `Cryptonote.ttf` and set it as the display font anywhere you can choose one:

| App | Where |
|---|---|
| **TextEdit** | Format → Font → Cryptonote |
| **Pages / Word** | font picker |
| **VS Code** | `"editor.fontFamily": "Cryptonote"` |
| **Terminal / iTerm** | Profile → Font → Cryptonote |
| **Notes** | any text box styled with it |

To **decrypt**, switch the font back to a normal one (e.g. Menlo). Same text, instantly readable.

```bash
# one-click install for your user
open install.command      # → copies the font to ~/Library/Fonts
```

### 2 · The menu-bar app — for Safari and everywhere else

Some fields (Safari's address/search bar, menu chrome) have a fixed font you can't change. `Cryptonote.app` is a native menu-bar scratchpad that covers them:

- Launch it → a **🔒** appears in the menu bar (no dock icon).
- Click **🔒** → a scratchpad drops down. Type: the screen shows scrambled glyphs, the buffer holds the real text.
- **Reveal (Crypt: ON/OFF)** — flip between scrambled and readable on screen.
- **Copy real text** — puts the true characters on the clipboard.

**Safari flow:** click 🔒 → type your private query (gibberish on screen) → *Copy real text* → click Safari's search bar → ⌘V. Safari runs the real search; anyone watching saw only noise.

```bash
open /Applications/Cryptonote.app      # after install, 🔒 lives in your menu bar
```

## Try it right now

`demo.html` is a self-contained page (font embedded, no server) that demonstrates the full effect — type, watch the screen scramble, see the real text mirrored, toggle reveal, copy the truth. Just double-click it.

## Build from source

Requires the Xcode command-line tools (`swiftc`) and, only if you want to regenerate the font, Python + `fonttools`.

```bash
# build the menu-bar app
cd app
swiftc main.swift -o cryptonote-bin -framework Cocoa -framework CoreText

# assemble the .app bundle (font is bundled inside and registered at runtime)
#   Contents/MacOS/Cryptonote          <- cryptonote-bin
#   Contents/Resources/Cryptonote.ttf  <- the font

# regenerate the font with a different scramble
python3 -m venv .venv && ./.venv/bin/pip install fonttools
./.venv/bin/python make_font.py        # edit SEED in the script to reshuffle
```

## Project structure

```
Cryptonote/
├── README.md
├── LICENSE
├── make_font.py          # remaps a base monospace font's glyph table
├── Cryptonote.ttf        # the font to install (full Menlo coverage)
├── Cryptonote-web.ttf    # ASCII subset used by demo.html
├── demo.html             # self-contained live demo / scratchpad
├── install.command       # one-click user font install
└── app/
    └── main.swift        # native AppKit menu-bar scratchpad
```

## ⚠️ Honest limitations

- **It's a substitution cipher, not cryptography.** It defeats a glance or a shoulder-surfer — its actual purpose. It does **not** hide secrets from anyone who has the font file and a screenshot. Don't treat it as encryption.
- **Fixed-font fields stay readable.** Safari's search bar, menu bars, and similar chrome can't be restyled; use the app's copy-paste for those.
- **Not a system-wide transparent layer.** As explained above, macOS makes that impossible. Cryptonote is the honest, working approximation.

## License

MIT — see [LICENSE](LICENSE).
