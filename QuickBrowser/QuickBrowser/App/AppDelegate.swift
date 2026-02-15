import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: OverlayWindow?
    private var pendingURL: URL?
    private let config = Config()
    private let launcher = Launcher()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

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

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "QuickBrowser")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()

        menu.addItem(NSMenuItem(
            title: "Открыть конфигурацию",
            action: #selector(openConfig),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "О программе",
            action: #selector(showAbout),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Выход",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    @objc private func openConfig() {
        let configPath = ("~/.config/quickbrowser" as NSString).expandingTildeInPath

        if !FileManager.default.fileExists(atPath: configPath) {
            let alert = NSAlert()
            alert.messageText = "Конфигурация не найдена"
            alert.informativeText = "Создать файл ~/.config/quickbrowser?"
            alert.addButton(withTitle: "Создать")
            alert.addButton(withTitle: "Отмена")

            if alert.runModal() == .alertFirstButtonReturn {
                let defaultConfig = """
                # QuickBrowser Configuration
                # Браузеры (формат: номер=путь)
                1=/Applications/Safari.app
                2=/Applications/Firefox.app

                # Автоматический выбор (формат: паттерн номер)
                # github.com 1
                # huggingface.co 2

                """
                try? defaultConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
            } else {
                return
            }
        }

        NSWorkspace.shared.openFile(configPath, withApplication: "TextEdit")
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "QuickBrowser v1.2"
        alert.informativeText = """
        Минималистичное macOS приложение для быстрого выбора браузера.

        Возможности:
        • Перехват http/https ссылок
        • CLI-подобный overlay интерфейс
        • Выбор браузера клавишами 1-9
        • Автоматический выбор по URL-паттернам
        • Нет внешних зависимостей

        Конфигурация: ~/.config/quickbrowser
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
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
            let configData = try config.load()

            if let matchedPattern = configData.patterns.first(where: { $0.matches(url: url) }),
               let browser = configData.browsers.first(where: { $0.key == matchedPattern.browserKey }) {
                openBrowser(browser, withURL: url)
                return
            }

            window = OverlayWindow(browsers: configData.browsers) { [weak self] browser in
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

        } catch ConfigError.invalidFormat(let line, let content) {
            showAlert(
                title: "Ошибка конфигурации [v1.2.0]",
                message: "Неверный формат в строке \(line):\n\"\(content)\""
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
            window?.close()
            window = nil
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
