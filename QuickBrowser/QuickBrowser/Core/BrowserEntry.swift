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
