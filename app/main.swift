import Cocoa
import CoreText

// ---- Cryptonote scratchpad: a menu-bar app ----
// The text view always holds the REAL text. In Crypt mode it is drawn with the
// remapped "Cryptonote" font (scrambled glyphs). "Copy real text" copies the
// true characters, so you can paste them into Safari / anywhere.

let cryptFontName = "Cryptonote"
let defaultSize: CGFloat = 20
let minSize: CGFloat = 10
let maxSize: CGFloat = 48

let cjkFontName = "CryptonoteCJK"

func registerCryptFont() {
    // Runtime-register the fonts so no system install is required.
    // Prefer the copies bundled inside the .app; fall back to ~/Cryptonote.
    for base in ["Cryptonote", "Cryptonote-CJK"] {
        var url: URL
        if let bundled = Bundle.main.url(forResource: base, withExtension: "ttf") {
            url = bundled
        } else {
            let path = ("~/Cryptonote/\(base).ttf" as NSString).expandingTildeInPath
            url = URL(fileURLWithPath: path)
        }
        var err: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err)
    }
}

func cryptFont(_ size: CGFloat) -> NSFont {
    // Primary font scrambles Latin, Greek and Cyrillic. Chinese characters are
    // absent from it, so a cascade sends them to the scrambled CJK font instead
    // of the system font, which would otherwise show them as readable.
    let base = NSFont(name: cryptFontName, size: size)
        ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    let cjk = NSFontDescriptor(fontAttributes: [.name: cjkFontName])
    let desc = base.fontDescriptor.addingAttributes([.cascadeList: [cjk]])
    return NSFont(descriptor: desc, size: size) ?? base
}
func plainFont(_ size: CGFloat) -> NSFont {
    NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
}

final class ScratchVC: NSViewController {
    let textView = NSTextView()
    let toggleButton = NSButton()
    let sizeSlider = NSSlider()
    let sizeLabel = NSTextField(labelWithString: "")
    var crypt = true
    var size: CGFloat = defaultSize

    func currentFont() -> NSFont { crypt ? cryptFont(size) : plainFont(size) }
    func fontFor(_ scrambled: Bool) -> NSFont { scrambled ? cryptFont(size) : plainFont(size) }

    // A run is "scrambled" when it is drawn with the Cryptonote font.
    func isCryptFont(_ f: NSFont?) -> Bool {
        guard let f = f else { return true }
        return f.fontName.contains(cryptFontName) || (f.familyName?.contains(cryptFontName) ?? false)
    }

    func setFont(_ scrambled: Bool, range: NSRange) {
        guard range.length > 0, let ts = textView.textStorage else { return }
        ts.addAttribute(.font, value: fontFor(scrambled), range: range)
    }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 420))

        // scrollable text area
        let scroll = NSScrollView(frame: NSRect(x: 14, y: 132, width: 432, height: 274))
        scroll.hasVerticalScroller = true
        scroll.borderType = .lineBorder
        scroll.autoresizingMask = [.width, .height]
        textView.frame = scroll.bounds
        textView.isEditable = true
        textView.isRichText = true           // allow per-range fonts for partial reveal
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.textColor = .textColor
        textView.typingAttributes = [.font: currentFont(), .foregroundColor: NSColor.textColor]
        textView.string = "how many money does elon musk has"
        let full = NSRange(location: 0, length: (textView.string as NSString).length)
        textView.textStorage?.addAttribute(.font, value: cryptFont(size), range: full)
        textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.textColor, range: full)
        scroll.documentView = textView
        root.addSubview(scroll)

        // Row 1: reveal the whole document (original toggle) or just the selection
        toggleButton.frame = NSRect(x: 14, y: 90, width: 210, height: 30)
        toggleButton.bezelStyle = .rounded
        toggleButton.title = "Reveal all (Crypt: ON)"
        toggleButton.target = self
        toggleButton.action = #selector(toggleCrypt)
        root.addSubview(toggleButton)

        let revealSelBtn = NSButton(frame: NSRect(x: 232, y: 90, width: 214, height: 30))
        revealSelBtn.bezelStyle = .rounded
        revealSelBtn.title = "Reveal selection"
        revealSelBtn.target = self
        revealSelBtn.action = #selector(revealSelection)
        root.addSubview(revealSelBtn)

        // Row 2: copy the real text, or clear
        let copyBtn = NSButton(frame: NSRect(x: 14, y: 52, width: 210, height: 30))
        copyBtn.bezelStyle = .rounded
        copyBtn.title = "Copy real text"
        copyBtn.keyEquivalent = "\r"
        copyBtn.target = self
        copyBtn.action = #selector(copyReal)
        root.addSubview(copyBtn)

        let clearBtn = NSButton(frame: NSRect(x: 232, y: 52, width: 214, height: 30))
        clearBtn.bezelStyle = .rounded
        clearBtn.title = "Clear"
        clearBtn.target = self
        clearBtn.action = #selector(clearText)
        root.addSubview(clearBtn)

        // Font size control (user-adjustable)
        let sizeCaption = NSTextField(labelWithString: "Size")
        sizeCaption.frame = NSRect(x: 14, y: 14, width: 34, height: 20)
        sizeCaption.textColor = .secondaryLabelColor
        sizeCaption.font = NSFont.systemFont(ofSize: 11)
        root.addSubview(sizeCaption)

        sizeSlider.frame = NSRect(x: 50, y: 12, width: 176, height: 24)
        sizeSlider.minValue = Double(minSize)
        sizeSlider.maxValue = Double(maxSize)
        sizeSlider.doubleValue = Double(size)
        sizeSlider.isContinuous = true
        sizeSlider.target = self
        sizeSlider.action = #selector(sizeChanged)
        root.addSubview(sizeSlider)

        sizeLabel.frame = NSRect(x: 232, y: 14, width: 46, height: 20)
        sizeLabel.textColor = .secondaryLabelColor
        sizeLabel.font = NSFont.systemFont(ofSize: 11)
        sizeLabel.stringValue = "\(Int(size)) pt"
        root.addSubview(sizeLabel)

        let quitBtn = NSButton(frame: NSRect(x: 386, y: 12, width: 60, height: 24))
        quitBtn.bezelStyle = .inline
        quitBtn.title = "Quit"
        quitBtn.target = NSApp
        quitBtn.action = #selector(NSApplication.terminate(_:))
        root.addSubview(quitBtn)

        self.view = root
    }

    @objc func sizeChanged() {
        size = CGFloat(sizeSlider.doubleValue.rounded())
        sizeLabel.stringValue = "\(Int(size)) pt"
        guard let ts = textView.textStorage else { return }
        // Resize every run while keeping whether it is scrambled or revealed.
        var runs: [(NSRange, Bool)] = []
        ts.enumerateAttribute(.font, in: NSRange(location: 0, length: ts.length)) { v, r, _ in
            runs.append((r, isCryptFont(v as? NSFont)))
        }
        ts.beginEditing()
        for (r, scrambled) in runs { ts.addAttribute(.font, value: fontFor(scrambled), range: r) }
        ts.endEditing()
        textView.typingAttributes[.font] = currentFont()
    }

    @objc func toggleCrypt() {
        // Whole-document reveal or scramble. This is the original behaviour.
        crypt.toggle()
        setFont(crypt, range: NSRange(location: 0, length: textView.textStorage?.length ?? 0))
        textView.typingAttributes[.font] = currentFont()
        toggleButton.title = crypt ? "Reveal all (Crypt: ON)" : "Scramble all (Crypt: OFF)"
    }

    @objc func revealSelection() {
        // Reveal, or re-hide, only the range selected with the mouse.
        guard let ts = textView.textStorage else { return }
        let sel = textView.selectedRange()
        guard sel.length > 0 else { NSSound.beep(); return }
        var anyScrambled = false
        ts.enumerateAttribute(.font, in: sel) { v, _, _ in
            if isCryptFont(v as? NSFont) { anyScrambled = true }
        }
        // If any of the selection is still scrambled, reveal it. Otherwise hide it.
        setFont(!anyScrambled, range: sel)
    }

    @objc func copyReal() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(textView.string, forType: .string)
    }

    @objc func clearText() {
        textView.string = ""
        textView.typingAttributes[.font] = currentFont()
        view.window?.makeFirstResponder(textView)
    }

    func focus() { view.window?.makeFirstResponder(textView) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    let vc = ScratchVC()

    func applicationDidFinishLaunching(_ n: Notification) {
        registerCryptFont()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = statusItem.button {
            b.title = "🔒"
            b.target = self
            b.action = #selector(togglePopover)
        }
        popover.contentViewController = vc
        popover.behavior = .transient
    }

    @objc func togglePopover() {
        guard let b = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            vc.focus()
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // menu-bar only, no dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
