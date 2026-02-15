import Foundation

enum ConfigError: Error {
    case fileNotFound
    case invalidFormat(line: Int)
    case browserNotFound(path: String)
    case emptyConfig
}

final class Config {
    private let fileManager = FileManager.default

    func load() throws -> [BrowserEntry] {
        let configPath = ("~/.config/quickbrowser" as NSString).expandingTildeInPath

        guard fileManager.fileExists(atPath: configPath) else {
            throw ConfigError.fileNotFound
        }

        let content = try String(contentsOfFile: configPath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        guard !lines.isEmpty else {
            throw ConfigError.emptyConfig
        }

        var entries: [BrowserEntry] = []

        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: "=", maxSplits: 1)

            guard parts.count == 2,
                  let key = parts[0].first,
                  key.isNumber else {
                throw ConfigError.invalidFormat(line: index + 1)
            }

            let path = (String(parts[1]) as NSString).expandingTildeInPath

            guard fileManager.fileExists(atPath: path) else {
                throw ConfigError.browserNotFound(path: path)
            }

            entries.append(BrowserEntry(key: String(key), path: path))
        }

        return entries.sorted { $0.key < $1.key }
    }
}
