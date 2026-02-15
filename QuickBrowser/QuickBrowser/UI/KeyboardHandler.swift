import Cocoa

final class KeyboardHandler: NSView {
    private let browsers: [BrowserEntry]
    private let onSelect: (BrowserEntry) -> Void

    init(browsers: [BrowserEntry], onSelect: @escaping (BrowserEntry) -> Void) {
        self.browsers = browsers
        self.onSelect = onSelect
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard let char = event.charactersIgnoringModifiers?.first else { return }

        if char == "\u{1B}" {
            NSApp.terminate(nil)
        } else if let index = char.wholeNumberValue,
                  index > 0,
                  index <= browsers.count {
            onSelect(browsers[index - 1])
        }
    }
}
