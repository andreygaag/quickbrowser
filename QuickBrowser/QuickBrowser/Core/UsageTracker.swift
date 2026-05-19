import Foundation

final class UsageTracker {
    struct BrowserStats: Codable {
        var manual: Int = 0
        var auto: Int = 0
        var total: Int { manual + auto }
    }

    private static let path = ("~/.config/quickbrowser.stats" as NSString).expandingTildeInPath
    private var stats: [String: BrowserStats]

    init() {
        stats = Self.load()
    }

    func recordManual(browserKey: String) {
        stats[browserKey, default: BrowserStats()].manual += 1
        save()
    }

    func recordAuto(browserKey: String) {
        stats[browserKey, default: BrowserStats()].auto += 1
        save()
    }

    func summary(browsers: [BrowserEntry]) -> String {
        guard !stats.isEmpty else { return String(localized: "No data") }

        var lines: [String] = []
        var totalManual = 0
        var totalAuto = 0

        for browser in browsers {
            let s = stats[browser.key] ?? BrowserStats()
            guard s.total > 0 else { continue }
            totalManual += s.manual
            totalAuto += s.auto
            lines.append(String(localized: "\(browser.name): \(s.total)  (\(s.manual) manual, \(s.auto) auto)"))
        }

        guard !lines.isEmpty else { return String(localized: "No data") }

        lines.append("")
        lines.append(String(localized: "Total: \(totalManual + totalAuto)  (\(totalManual) manual, \(totalAuto) auto)"))

        return lines.joined(separator: "\n")
    }

    private static func load() -> [String: BrowserStats] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let decoded = try? JSONDecoder().decode([String: BrowserStats].self, from: data)
        else { return [:] }
        return decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        try? data.write(to: URL(fileURLWithPath: Self.path))
    }
}
