import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: OverlayWindow?
    private var pendingURL: URL?
    private let config = Config()
    private let launcher = Launcher()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        if let url = pendingURL {
            handleURL(url)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        handleURL(url)
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }

        if NSApp.isRunning {
            handleURL(url)
        } else {
            pendingURL = url
        }
    }

    private func handleURL(_ url: URL) {
        do {
            let browsers = try config.load()

            window = OverlayWindow(browsers: browsers) { [weak self] browser in
                self?.openBrowser(browser, withURL: url)
            }

            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

        } catch ConfigError.fileNotFound {
            showAlert(
                title: "Конфигурация не найдена",
                message: "Создайте файл ~/.config/quickbrowser\nФормат: 1=/Applications/Safari.app"
            )
            NSApp.terminate(nil)

        } catch ConfigError.invalidFormat(let line) {
            showAlert(
                title: "Ошибка конфигурации",
                message: "Неверный формат в строке \(line)"
            )
            NSApp.terminate(nil)

        } catch ConfigError.browserNotFound(let path) {
            showAlert(
                title: "Браузер не найден",
                message: "Приложение не существует:\n\(path)"
            )
            NSApp.terminate(nil)

        } catch ConfigError.emptyConfig {
            showAlert(
                title: "Пустая конфигурация",
                message: "Файл ~/.config/quickbrowser пуст"
            )
            NSApp.terminate(nil)

        } catch {
            showAlert(
                title: "Ошибка",
                message: error.localizedDescription
            )
            NSApp.terminate(nil)
        }
    }

    private func openBrowser(_ browser: BrowserEntry, withURL url: URL) {
        do {
            try launcher.open(url: url, withBrowser: browser)
            NSApp.terminate(nil)
        } catch {
            showAlert(
                title: "Ошибка запуска",
                message: "Не удалось открыть браузер:\n\(error.localizedDescription)"
            )
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
