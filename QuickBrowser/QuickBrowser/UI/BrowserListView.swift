import Cocoa

final class BrowserListView: NSView {
    private static let rowHeight: CGFloat = 52
    private static let headerHeight: CGFloat = 40
    private static let padding: CGFloat = 16
    private static let iconSize: CGFloat = 32
    private static let badgeSize: CGFloat = 24

    private let browsers: [BrowserEntry]

    init(frame: NSRect, browsers: [BrowserEntry]) {
        self.browsers = browsers
        super.init(frame: frame)
        buildSubviews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSubviews() {
        addHeader()
        browsers.enumerated().forEach { addRow(index: $0, browser: $1) }
    }

    private func addHeader() {
        let y = bounds.height - Self.headerHeight

        let label = NSTextField(labelWithString: "Открыть в браузере")
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.sizeToFit()
        label.setFrameOrigin(NSPoint(
            x: Self.padding,
            y: y + (Self.headerHeight - label.frame.height) / 2
        ))
        addSubview(label)

        let separator = NSBox()
        separator.boxType = .separator
        separator.frame = NSRect(x: 0, y: y, width: bounds.width, height: 1)
        addSubview(separator)
    }

    private func addRow(index: Int, browser: BrowserEntry) {
        let y = bounds.height - Self.headerHeight - CGFloat(index + 1) * Self.rowHeight

        let icon = NSImageView()
        icon.image = NSWorkspace.shared.icon(forFile: browser.path)
        icon.frame = NSRect(
            x: Self.padding,
            y: y + (Self.rowHeight - Self.iconSize) / 2,
            width: Self.iconSize,
            height: Self.iconSize
        )
        addSubview(icon)

        let nameLabel = NSTextField(labelWithString: browser.name)
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = .labelColor
        nameLabel.sizeToFit()
        nameLabel.setFrameOrigin(NSPoint(
            x: Self.padding + Self.iconSize + 10,
            y: y + (Self.rowHeight - nameLabel.frame.height) / 2
        ))
        addSubview(nameLabel)

        let badge = KeyBadgeView(key: browser.key)
        badge.frame = NSRect(
            x: bounds.width - Self.padding - Self.badgeSize,
            y: y + (Self.rowHeight - Self.badgeSize) / 2,
            width: Self.badgeSize,
            height: Self.badgeSize
        )
        addSubview(badge)

        guard index < browsers.count - 1 else { return }
        let separator = NSBox()
        separator.boxType = .separator
        let sepX = Self.padding + Self.iconSize + 10
        separator.frame = NSRect(x: sepX, y: y, width: bounds.width - sepX, height: 1)
        addSubview(separator)
    }
}

private final class KeyBadgeView: NSView {
    private let key: String

    init(key: String) {
        self.key = key
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        NSColor.quaternaryLabelColor.setFill()
        path.fill()
        NSColor.tertiaryLabelColor.setStroke()
        path.lineWidth = 0.5
        path.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let str = key as NSString
        let strSize = str.size(withAttributes: attrs)
        str.draw(at: NSPoint(
            x: (bounds.width - strSize.width) / 2,
            y: (bounds.height - strSize.height) / 2
        ), withAttributes: attrs)
    }
}
