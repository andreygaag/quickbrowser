import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: OverlayWindow?
    private let config = Config()
    private let launcher = Launcher()
    private let learningTracker = LearningTracker()

    private static let learningThreshold = 5
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
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

    private func handleURL(_ url: URL) {
        do {
            let configData = try config.load()

            if let matchedPattern = configData.patterns.first(where: { $0.matches(url: url) }),
               let browser = configData.browsers.first(where: { $0.key == matchedPattern.browserKey }) {
                openBrowser(browser, withURL: url)
                return
            }

            guard window == nil else {
                window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            window = OverlayWindow(browsers: configData.browsers) { [weak self] browser in
                self?.openBrowser(browser, withURL: url)
            }

            NSApp.setActivationPolicy(.regular)
            window?.delegate = self
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

    func windowWillClose(_ notification: Notification) {
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }

    private func openBrowser(_ browser: BrowserEntry, withURL url: URL) {
        do {
            try launcher.open(url: url, withBrowser: browser)
            window?.close()
            if let domain = url.host {
                checkLearning(domain: domain, browser: browser)
            }
        } catch {
            showAlert(
                title: "Ошибка запуска",
                message: "Не удалось открыть браузер:\n\(error.localizedDescription)"
            )
        }
    }

    private func checkLearning(domain: String, browser: BrowserEntry) {
        guard !config.hasPattern(for: domain) else { return }
        let count = learningTracker.record(domain: domain, browserKey: browser.key)
        guard count >= Self.learningThreshold else { return }
        learningTracker.reset(domain: domain, browserKey: browser.key)
        suggestPattern(domain: domain, browser: browser)
    }

    private func suggestPattern(domain: String, browser: BrowserEntry) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Запомнить выбор?"
        alert.informativeText = "Вы \(Self.learningThreshold) раз открывали \(domain) в \(browser.name). Всегда открывать в нём?"
        alert.addButton(withTitle: "Запомнить")
        alert.addButton(withTitle: "Не сейчас")

        if alert.runModal() == .alertFirstButtonReturn {
            try? config.appendPattern(domain: domain, browserKey: browser.key)
        }

        NSApp.setActivationPolicy(.accessory)
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
