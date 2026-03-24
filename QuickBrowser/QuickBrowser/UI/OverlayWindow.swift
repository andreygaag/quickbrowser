import Cocoa

final class OverlayWindow: NSPanel {
    override var canBecomeKey: Bool { true }

    private static let windowWidth: CGFloat = 360
    private static let rowHeight: CGFloat = 52
    private static let headerHeight: CGFloat = 40

    init(browsers: [BrowserEntry], onSelect: @escaping (BrowserEntry) -> Void) {
        let size = NSSize(
            width: Self.windowWidth,
            height: Self.headerHeight + CGFloat(browsers.count) * Self.rowHeight + 8
        )

        super.init(
            contentRect: Self.centeredRect(size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        let effect = Self.makeEffectView(size: size)
        contentView = effect

        let listView = BrowserListView(frame: effect.bounds, browsers: browsers)
        effect.addSubview(listView)

        let keyHandler = KeyboardHandler(browsers: browsers, onSelect: onSelect)
        keyHandler.frame = effect.bounds
        effect.addSubview(keyHandler)

        makeFirstResponder(keyHandler)
    }

    private static func centeredRect(size: NSSize) -> NSRect {
        guard let screen = NSScreen.main else { fatalError("No main screen") }
        return NSRect(
            x: (screen.frame.width - size.width) / 2,
            y: (screen.frame.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private static func makeEffectView(size: NSSize) -> NSVisualEffectView {
        let view = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        view.material = .menu
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.masksToBounds = true
        return view
    }
}
