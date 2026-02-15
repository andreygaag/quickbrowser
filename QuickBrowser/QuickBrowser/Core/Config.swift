import Foundation

enum ConfigError: Error {
    case fileNotFound
    case invalidFormat(line: Int, content: String)
    case browserNotFound(path: String)
    case emptyConfig
}

struct ConfigData {
    let browsers: [BrowserEntry]
    let patterns: [URLPattern]
}

final class Config {
    private let fileManager = FileManager.default

    func load() throws -> ConfigData {
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

        var browsers: [BrowserEntry] = []
        var patterns: [URLPattern] = []

        for (index, line) in lines.enumerated() {
            if line.contains("=") {
                let parts = line.split(separator: "=", maxSplits: 1)

                guard parts.count == 2,
                      let key = parts[0].first,
                      key.isNumber else {
                    throw ConfigError.invalidFormat(line: index + 1, content: line)
                }

                let path = (String(parts[1]) as NSString).expandingTildeInPath

                guard fileManager.fileExists(atPath: path) else {
                    throw ConfigError.browserNotFound(path: path)
                }

                browsers.append(BrowserEntry(key: String(key), path: path))
            } else if line.contains(" ") {
                let parts = line.split(separator: " ")

                guard parts.count >= 2 else {
                    throw ConfigError.invalidFormat(line: index + 1, content: line)
                }

                let pattern = String(parts[0])
                let browserKey = String(parts[1])

                guard let firstChar = browserKey.first, firstChar.isNumber else {
                    throw ConfigError.invalidFormat(line: index + 1, content: line)
                }

                patterns.append(URLPattern(pattern: pattern, browserKey: browserKey))
            }
        }

        guard !browsers.isEmpty else {
            throw ConfigError.emptyConfig
        }

        return ConfigData(
            browsers: browsers.sorted { $0.key < $1.key },
            patterns: patterns
        )
    }
}
