import Cocoa

final class BrowserListView: NSView {
    private let browsers: [BrowserEntry]

    init(browsers: [BrowserEntry]) {
        self.browsers = browsers
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.withAlphaComponent(0.9).setFill()
        dirtyRect.fill()

        let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let textColor = NSColor(red: 0, green: 1, blue: 0, alpha: 1)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let lineHeight: CGFloat = 20
        let startY = bounds.height - 40

        for (index, browser) in browsers.enumerated() {
            let text = "[\(browser.key)] \(browser.name)"
            let y = startY - CGFloat(index) * lineHeight
            let point = NSPoint(x: 20, y: y)
            text.draw(at: point, withAttributes: attributes)
        }
    }
}
