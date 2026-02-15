import Foundation

struct BrowserEntry {
    let key: String
    let path: String
    let name: String

    init(key: String, path: String) {
        self.key = key
        self.path = path
        self.name = URL(fileURLWithPath: path)
            .deletingPathExtension()
            .lastPathComponent
    }
}

struct URLPattern {
    let pattern: String
    let browserKey: String

    func matches(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains(pattern) || url.absoluteString.contains(pattern)
    }
}
