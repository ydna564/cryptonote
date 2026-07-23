<div align="center">

# Cryptonote

### On-screen text scrambling for macOS that keeps the real characters underneath.

</div>

Cryptonote makes anything you type render as unreadable glyphs on screen, while every app, search box, and your clipboard still receive the true text. A person glancing at your screen sees nonsense. Your search still runs, your note still saves, your message still sends. Turn the mode off and the same text becomes readable again.

<div align="center">

![platform](https://img.shields.io/badge/platform-macOS%2012%2B-000000?style=flat-square)
![language](https://img.shields.io/badge/Swift-6.1-F05138?style=flat-square)
![font](https://img.shields.io/badge/font-fontTools-2A7?style=flat-square)
![license](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

</div>

```text
you type       how many money does elon musk has
screen shows   igl dhqr dgqcr ygck cugq dvkz ihk
apps receive   how many money does elon musk has
```

## What is this

Cryptonote is a privacy tool for anyone who types in places where other people can see the screen. On a train, in a café, in an open office, a single glance can expose a private search, a draft message, or a hint about a password. Cryptonote turns what appears on screen into glyphs nobody can read, without altering a single byte of the underlying text.

It exists because macOS offers no supported way to make an arbitrary app draw text differently from what it holds. Apps render their own buffers, and System Integrity Protection blocks injecting a display filter into other processes. So Cryptonote never touches your text. It changes the font instead. `Cryptonote.ttf` is an ordinary font whose glyph table has been remapped, so the outline drawn for the letter `a` is really some other letter's outline, while the character in memory stays a true `a`.

It deliberately does not encrypt anything. This is protection against a glance, not against an analyst. Read the security notes below before relying on it.

## Highlights

- **The real text is never altered.** Copy, paste, search, and save all receive the true characters, because only the glyph shapes change.
- **Instant reveal.** Switch the display font back and the same text reads normally. Nothing to decrypt.
- **Works in real editors.** Set the font in TextEdit, Pages, VS Code, Terminal, and any field that lets you choose a font.
- **Covers Safari too.** A menu-bar scratchpad holds the scrambled text and copies the real text for pasting into fixed-font fields.
- **No installation of dependencies to run the app.** The font is bundled inside the app and registered at runtime.
- **Deterministic and reversible.** The scramble is a fixed seeded derangement, so every character maps to a different one and the mapping never drifts.

## How it works

You type real Unicode. The font draws each character as a different one.

```text
 you type    "a"  "b"  "c"  "d"  "e"  "f"     real Unicode, untouched
              |    |    |    |    |    |
 font draws   v    v    v    v    v    v
             "q"  "x"  "k"  "j"  "c"  "m"     scrambled glyphs on screen
```

Because the bytes never change, the consequences follow on their own.

| Surface | Result |
| --- | --- |
| Screen | scrambled glyphs, a glance reveals nothing |
| Copy and paste | the true characters |
| Search engines and forms | the true query |
| Save to disk | the true text |
| Turn the mode off | switch the display font back, same text, now readable |

The scramble is generated once from a fixed seed, and every visible character maps to a different visible character. Regenerate it with a new seed to get a fresh mapping.

## Requirements

- macOS 12 or newer
- Xcode command line tools, which provide `swiftc`, only if you build the app from source
- Python 3.11 or newer and `fonttools`, only if you regenerate the font

Neither Python nor Swift is needed to simply install the font and use it in an editor.

## Install

Install the font for your user.

```bash
open install.command      # copies Cryptonote.ttf into ~/Library/Fonts
```

Run the menu-bar app.

```bash
open /Applications/Cryptonote.app      # a lock icon appears in the menu bar
```

## Usage

### The font, for editors and documents

Install `Cryptonote.ttf`, then set it as the display font wherever you can pick one.

| App | Where to set it |
| --- | --- |
| TextEdit | Format, then Font, then Cryptonote |
| Pages and Word | the font picker |
| VS Code | set `editor.fontFamily` to `Cryptonote` |
| Terminal and iTerm | Profile, then Font, then Cryptonote |
| Notes | any text box styled with it |

To reveal, switch the font back to a normal one such as Menlo. The same text becomes readable at once.

### The menu-bar app, for Safari and everywhere else

Some fields have a fixed font you cannot change, including Safari's address bar and the menu bar itself. The scratchpad app covers them.

1. Launch the app. A lock icon appears in the menu bar with no dock icon.
2. Click the icon. A scratchpad drops down. Type into it, and the screen shows scrambled glyphs while the buffer holds the real text.
3. Use **Reveal** to flip between scrambled and readable on screen.
4. Use **Copy real text** to put the true characters on the clipboard.

For a private Safari search, click the icon, type your query so it shows as nonsense on screen, press **Copy real text**, click Safari's search bar, and paste. Safari runs the real query while anyone watching saw only noise.

## Try it now

`demo.html` is a self-contained page with the font embedded, so it needs no server. Double-click it to type, watch the screen scramble, see the real text mirrored, toggle reveal, and copy the true characters.

## Build from source

Build the menu-bar app.

```bash
cd app
swiftc main.swift -o cryptonote-bin -framework Cocoa -framework CoreText
```

Assemble the app bundle so the font ships inside it. Place `cryptonote-bin` at `Contents/MacOS/Cryptonote` and `Cryptonote.ttf` at `Contents/Resources/Cryptonote.ttf`, with an `Info.plist` that sets `LSUIElement` to true for a menu-bar app.

Regenerate the font with a different scramble.

```bash
python3 -m venv .venv
./.venv/bin/pip install fonttools
./.venv/bin/python make_font.py      # edit SEED in the script to reshuffle
```

## Project structure

```text
Cryptonote/
  README.md
  LICENSE
  make_font.py          remaps a base monospace font's glyph table
  Cryptonote.ttf        the font to install, full Menlo coverage
  Cryptonote-web.ttf    an ASCII subset used by demo.html
  demo.html             self-contained live demo and scratchpad
  install.command       one-click user font install
  app/
    main.swift          native AppKit menu-bar scratchpad
```

## Security notes

Cryptonote is a substitution cipher expressed through glyph shapes. It is effective against a glance or a shoulder-surfer, which is its stated purpose. It is not cryptography. Anyone who has the font file and a screenshot can recover the text, so it must never be used to protect real secrets. The text on disk, in the clipboard, and in every app is always the true plaintext, because that is the whole point. Treat the scrambling as a screen-privacy measure only.

## Limitations

- It is a substitution cipher, not encryption. It defeats a glance, nothing stronger.
- Fixed-font fields stay readable. Safari's search bar and menu chrome cannot be restyled, so use the scratchpad app for those.
- It is not a transparent system-wide layer. As explained above, macOS makes that impossible, and Cryptonote is the honest working approximation.

## License

MIT. See [LICENSE](LICENSE).
