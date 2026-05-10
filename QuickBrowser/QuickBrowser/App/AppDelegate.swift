import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: OverlayWindow?
    private var editorWindow: NSWindow?
    private let config = Config()
    private let launcher = Launcher()
    private let learningTracker = LearningTracker()
    private let usageTracker = UsageTracker()

    private static let learningThreshold = 5
    private var statusItem: NSStatusItem?

    private func loadOrCreateConfig() -> ConfigData? {
        do {
            return try config.load()
        } catch ConfigError.fileNotFound {
            try? config.createDefault()
            return try? config.load()
        } catch {
            return nil
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        promptForDefaultBrowserOnFirstLaunch()
    }

    private func promptForDefaultBrowserOnFirstLaunch() {
        let key = "hasPromptedDefaultBrowser"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let currentDefault = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://")!)
        guard currentDefault?.lastPathComponent != "QuickBrowser.app" else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = NSAlert()
            alert.messageText = "Браузер по умолчанию"
            alert.informativeText = "QuickBrowser может перехватывать ссылки, если установлен браузером по умолчанию.\n\nВ настройках выберите QuickBrowser из списка."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Открыть настройки")
            alert.addButton(withTitle: "Позже")
            if alert.runModal() == .alertFirstButtonReturn {
                self.openDefaultBrowserSettings()
            }
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
            title: "Редактировать конфигурацию",
            action: #selector(openConfig),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem(
            title: "Сделать браузером по умолчанию",
            action: #selector(switchDefaultBrowser),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem(
            title: "Статистика",
            action: #selector(showStats),
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
        guard editorWindow == nil else {
            editorWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let configData = loadOrCreateConfig()
        let browsers = (configData?.browsers ?? []).map { EditableBrowser(key: $0.key, path: $0.path) }
        let patterns = (configData?.patterns ?? []).map { EditablePattern(pattern: $0.pattern, browserKey: $0.browserKey) }

        let view = ConfigEditorView(browsers: browsers, patterns: patterns) { [weak self] browsers, patterns in
            self?.saveConfig(browsers: browsers, patterns: patterns)
        }

        let controller = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: controller)
        win.title = "QuickBrowser — Конфигурация"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        editorWindow = win
    }

    private func saveConfig(browsers: [EditableBrowser], patterns: [EditablePattern]) {
        var lines = ["# QuickBrowser Configuration", ""]
        browsers.forEach { lines.append("\($0.key)=\($0.path)") }
        if !patterns.isEmpty {
            lines.append("")
            patterns.forEach { lines.append("\($0.pattern) \($0.browserKey)") }
        }
        let configPath = ("~/.config/quickbrowser" as NSString).expandingTildeInPath
        try? (lines.joined(separator: "\n") + "\n").write(toFile: configPath, atomically: true, encoding: .utf8)
        editorWindow?.close()
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

    @objc private func showStats() {
        let summary: String
        if let configData = loadOrCreateConfig() {
            summary = usageTracker.summary(browsers: configData.browsers)
        } else {
            summary = "Не удалось загрузить конфигурацию"
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Статистика использования"
        alert.informativeText = summary
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()

        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func switchDefaultBrowser() {
        openDefaultBrowserSettings()
    }

    private func openDefaultBrowserSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        handleURL(url)
    }

    private func handleURL(_ url: URL) {
        guard let configData = loadOrCreateConfig() else {
            showAlert(title: "Ошибка", message: "Не удалось загрузить конфигурацию")
            NSApp.terminate(nil)
            return
        }

        do {

            if let matchedPattern = configData.patterns.first(where: { $0.matches(url: url) }),
               let browser = configData.browsers.first(where: { $0.key == matchedPattern.browserKey }) {
                openBrowserAuto(browser, withURL: url)
                return
            }

            guard window == nil else {
                window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            window = OverlayWindow(browsers: configData.browsers) { [weak self] browser in
                self?.openBrowserManually(browser, withURL: url)
            }

            NSApp.setActivationPolicy(.regular)
            window?.delegate = self
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

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
        let closed = notification.object as? NSWindow
        if closed === window { window = nil }
        if closed === editorWindow { editorWindow = nil }
        if window == nil && editorWindow == nil {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func openBrowserManually(_ browser: BrowserEntry, withURL url: URL) {
        launch(browser, url: url)
        usageTracker.recordManual(browserKey: browser.key)
        if let domain = url.host {
            checkLearning(domain: domain, browser: browser)
        }
    }

    private func openBrowserAuto(_ browser: BrowserEntry, withURL url: URL) {
        launch(browser, url: url)
        usageTracker.recordAuto(browserKey: browser.key)
    }

    private func launch(_ browser: BrowserEntry, url: URL) {
        do {
            try launcher.open(url: url, withBrowser: browser)
            window?.close()
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
        if (try? config.load())?.autolearn == true {
            try? config.appendPattern(domain: domain, browserKey: browser.key)
            return
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Запомнить выбор?"
        alert.informativeText = "Вы \(Self.learningThreshold) раз открывали \(domain) в \(browser.name). Всегда открывать в нём?"
        alert.addButton(withTitle: "Запомнить")
        alert.addButton(withTitle: "Не сейчас")

        let alertWindow = alert.window
        alertWindow.level = .floating

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
