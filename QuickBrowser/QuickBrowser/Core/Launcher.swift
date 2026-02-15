import Foundation

final class Launcher {
    func open(url: URL, withBrowser browser: BrowserEntry) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", browser.path, url.absoluteString]
        try process.run()
    }
}
