import Cocoa

final class OverlayWindow: NSPanel {
    override var canBecomeKey: Bool { true }

    init(browsers: [BrowserEntry], onSelect: @escaping (BrowserEntry) -> Void) {
        let width: CGFloat = 400
        let height: CGFloat = 200

        guard let screen = NSScreen.main else {
            fatalError("No main screen found")
        }

        let screenRect = screen.frame
        let x = (screenRect.width - width) / 2
        let y = (screenRect.height - height) / 2
        let rect = NSRect(x: x, y: y, width: width, height: height)

        super.init(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        backgroundColor = NSColor.black.withAlphaComponent(0.9)
        isOpaque = false

        let listView = BrowserListView(browsers: browsers)
        listView.frame = contentView?.bounds ?? .zero
        contentView?.addSubview(listView)

        let keyHandler = KeyboardHandler(browsers: browsers, onSelect: onSelect)
        keyHandler.frame = contentView?.bounds ?? .zero
        contentView?.addSubview(keyHandler)

        makeFirstResponder(keyHandler)
    }
}
