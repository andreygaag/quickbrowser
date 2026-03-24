import Foundation

final class LearningTracker {
    private static let path = ("~/.config/quickbrowser.learn" as NSString).expandingTildeInPath
    private var counts: [String: Int]

    init() {
        counts = Self.load()
    }

    func record(domain: String, browserKey: String) -> Int {
        let key = "\(domain) \(browserKey)"
        counts[key, default: 0] += 1
        save()
        return counts[key]!
    }

    func reset(domain: String, browserKey: String) {
        counts.removeValue(forKey: "\(domain) \(browserKey)")
        save()
    }

    private static func load() -> [String: Int] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return [:] }
        var result: [String: Int] = [:]
        for line in content.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: " ")
            guard parts.count == 3, let count = Int(parts[2]) else { continue }
            result["\(parts[0]) \(parts[1])"] = count
        }
        return result
    }

    private func save() {
        let content = counts.map { "\($0.key) \($0.value)" }.joined(separator: "\n")
        try? content.write(toFile: Self.path, atomically: true, encoding: .utf8)
    }
}
