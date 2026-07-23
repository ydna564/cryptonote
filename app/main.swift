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

func registerCryptFont() {
    // Runtime-register the font so no system install is required.
    // Prefer the copy bundled inside the .app; fall back to ~/Cryptonote.
    var url: URL
    if let bundled = Bundle.main.url(forResource: "Cryptonote", withExtension: "ttf") {
        url = bundled
    } else {
        let path = ("~/Cryptonote/Cryptonote.ttf" as NSString).expandingTildeInPath
        url = URL(fileURLWithPath: path)
    }
    var err: Unmanaged<CFError>?
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err)
}

func cryptFont(_ size: CGFloat) -> NSFont {
    NSFont(name: cryptFontName, size: size)
        ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
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

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 360))

        // scrollable text area
        let scroll = NSScrollView(frame: NSRect(x: 14, y: 92, width: 432, height: 254))
        scroll.hasVerticalScroller = true
        scroll.borderType = .lineBorder
        scroll.autoresizingMask = [.width, .height]
        textView.frame = scroll.bounds
        textView.isEditable = true
        textView.isRichText = false          // single font for the whole buffer
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.font = currentFont()
        textView.string = "how many money does elon musk has"
        scroll.documentView = textView
        root.addSubview(scroll)

        // Crypt toggle
        toggleButton.frame = NSRect(x: 14, y: 50, width: 150, height: 30)
        toggleButton.bezelStyle = .rounded
        toggleButton.title = "Reveal (Crypt: ON)"
        toggleButton.target = self
        toggleButton.action = #selector(toggleCrypt)
        root.addSubview(toggleButton)

        // Copy real text
        let copyBtn = NSButton(frame: NSRect(x: 172, y: 50, width: 150, height: 30))
        copyBtn.bezelStyle = .rounded
        copyBtn.title = "Copy real text"
        copyBtn.keyEquivalent = "\r"
        copyBtn.target = self
        copyBtn.action = #selector(copyReal)
        root.addSubview(copyBtn)

        // Clear
        let clearBtn = NSButton(frame: NSRect(x: 330, y: 50, width: 116, height: 30))
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
        textView.font = currentFont()
    }

    @objc func toggleCrypt() {
        crypt.toggle()
        textView.font = currentFont()
        toggleButton.title = crypt ? "Reveal (Crypt: ON)" : "Scramble (Crypt: OFF)"
    }

    @objc func copyReal() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(textView.string, forType: .string)
    }

    @objc func clearText() {
        textView.string = ""
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
