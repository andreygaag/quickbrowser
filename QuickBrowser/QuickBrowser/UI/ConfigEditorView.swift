import SwiftUI
import UniformTypeIdentifiers

struct EditableBrowser: Identifiable {
    let id = UUID()
    var key: String
    var path: String
    var name: String { URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent }
}

struct EditablePattern: Identifiable {
    let id = UUID()
    var pattern: String
    var browserKey: String
}

struct ConfigEditorView: View {
    @State var browsers: [EditableBrowser]
    @State var patterns: [EditablePattern]
    @State private var newDomain = ""
    @State private var selectedBrowserKey = ""
    let onSave: ([EditableBrowser], [EditablePattern]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            browsersSection
            patternsSection
            HStack {
                Spacer()
                Button("Сохранить") { onSave(browsers, patterns) }
                    .buttonStyle(.borderedProminent)
                    .disabled(browsers.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 520)
        .onAppear { selectedBrowserKey = browsers.first?.key ?? "" }
    }

    private var browsersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Браузеры").font(.headline)

            List {
                ForEach(browsers) { browser in
                    HStack(spacing: 8) {
                        Text(browser.key)
                            .foregroundColor(.secondary)
                            .frame(width: 16, alignment: .trailing)
                        Image(nsImage: NSWorkspace.shared.icon(forFile: browser.path))
                            .resizable().frame(width: 18, height: 18)
                        Text(browser.name)
                        Spacer()
                        Text(browser.path)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .onDelete { browsers.remove(atOffsets: $0) }
            }
            .frame(height: 130)

            Button(action: pickBrowser) {
                Label("Добавить браузер", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Автоматический выбор").font(.headline)

            List {
                ForEach(patterns) { p in
                    HStack {
                        Text(p.pattern)
                        Spacer()
                        Text("→ \(browsers.first { $0.key == p.browserKey }?.name ?? p.browserKey)")
                            .foregroundColor(.secondary)
                        Button(action: { patterns.removeAll { $0.id == p.id } }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { patterns.remove(atOffsets: $0) }
            }
            .frame(height: 110)

            HStack(spacing: 8) {
                TextField("github.com", text: $newDomain)
                    .textFieldStyle(.roundedBorder)

                Picker("", selection: $selectedBrowserKey) {
                    ForEach(browsers) { b in
                        Text(b.name).tag(b.key)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
                .disabled(browsers.isEmpty)

                Button("Добавить") { addPattern() }
                    .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty || browsers.isEmpty)
            }
        }
    }

    private func pickBrowser() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.title = "Выберите браузер"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let nextKey = String((browsers.compactMap { Int($0.key) }.max() ?? 0) + 1)
        let browser = EditableBrowser(key: nextKey, path: url.path)
        browsers.append(browser)
        if selectedBrowserKey.isEmpty { selectedBrowserKey = nextKey }
    }

    private func addPattern() {
        let domain = newDomain.trimmingCharacters(in: .whitespaces)
        guard !domain.isEmpty, !selectedBrowserKey.isEmpty else { return }
        patterns.append(EditablePattern(pattern: domain, browserKey: selectedBrowserKey))
        newDomain = ""
    }
}
