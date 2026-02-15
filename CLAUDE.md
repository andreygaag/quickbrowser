# QuickBrowser — Инструкции для Claude

## Описание проекта

QuickBrowser — минималистичный менеджер браузеров для macOS. Перехватывает http/https ссылки и позволяет выбрать браузер для открытия или открывает автоматически по URL-паттернам.

## Архитектура

### Структура файлов

```
QuickBrowser/
├── App/
│   ├── main.swift           - Точка входа
│   ├── AppDelegate.swift    - Основная логика приложения
│   └── Info.plist          - Конфигурация приложения
├── Core/
│   ├── BrowserEntry.swift  - Модель браузера + URLPattern
│   ├── Config.swift        - Парсер конфигурации
│   └── Launcher.swift      - Запуск браузеров
└── UI/
    ├── OverlayWindow.swift     - Окно выбора браузера
    ├── BrowserListView.swift   - Список браузеров
    └── KeyboardHandler.swift   - Обработка клавиш
```

### Ключевые компоненты

**AppDelegate.swift:**
- `applicationDidFinishLaunching()` — инициализация menu bar и регистрация URL handler
- `handleURL()` — основная логика:
  1. Загружает конфиг (browsers + patterns)
  2. Проверяет паттерны через `URLPattern.matches()`
  3. Если совпадение → открывает браузер автоматически
  4. Если нет → показывает OverlayWindow

**Config.swift:**
- Парсит `~/.config/quickbrowser`
- Два формата строк:
  - `1=/Applications/Safari.app` — определение браузера
  - `github.com 1` — URL-паттерн
- Возвращает `ConfigData(browsers, patterns)`

**URLPattern:**
```swift
struct URLPattern {
    let pattern: String
    let browserKey: String
    
    func matches(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains(pattern) || url.absoluteString.contains(pattern)
    }
}
```

## Формат конфига

```
# Комментарии начинаются с #
# Пустые строки игнорируются

# Браузеры: номер=путь
1=/Applications/Safari.app
2=/Applications/Firefox.app

# Паттерны: текст номер_браузера
github.com 2
openai.com 1
```

## Важные детали реализации

### Парсинг конфига

1. Читает файл построчно
2. Фильтрует пустые строки и комментарии (`#`)
3. Определяет тип строки:
   - Содержит `=` → браузер
   - Содержит пробел → паттерн
4. Валидация:
   - Для браузера: ключ должен быть цифрой, путь должен существовать
   - Для паттерна: ключ браузера должен быть цифрой

### Автоматический выбор

```swift
if let matchedPattern = configData.patterns.first(where: { $0.matches(url: url) }),
   let browser = configData.browsers.first(where: { $0.key == matchedPattern.browserKey }) {
    openBrowser(browser, withURL: url)
    return
}
```

Берется **первый** совпавший паттерн из конфига (порядок важен).

### Обработка ошибок

`ConfigError`:
- `.fileNotFound` — конфиг не существует
- `.invalidFormat(line, content)` — неверный формат строки
- `.browserNotFound(path)` — браузер по пути не найден
- `.emptyConfig` — конфиг пустой или нет браузеров

При ошибке показывается alert с деталями и приложение завершается.

## Сборка и деплой

### Debug сборка
```bash
xcodebuild -project QuickBrowser.xcodeproj -scheme QuickBrowser -configuration Debug
```

### Release сборка
```bash
xcodebuild -project QuickBrowser.xcodeproj -scheme QuickBrowser -configuration Release
```

### Установка
```bash
cp -R Build/Products/Release/QuickBrowser.app /Applications/
```

### Регистрация как URL handler

После установки в `/Applications` система автоматически регистрирует приложение как обработчик http/https через `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>http</string>
            <string>https</string>
        </array>
    </dict>
</array>
```

## Версии

- **v1.0** — Базовый функционал (выбор браузера из списка)
- **v1.1** — Добавлена иконка в menu bar с меню
- **v1.2** — Автоматический выбор браузера по URL-паттернам

## Bundle ID

- v1.0-1.1: `com.user.quickbrowser`
- v1.2+: `com.user.quickbrowser.v2`

## Принципы разработки

1. **Минимализм** — никаких внешних зависимостей
2. **Простота** — один конфиг файл, понятный формат
3. **Производительность** — запуск < 100ms
4. **Надежность** — четкая обработка ошибок
5. **CLI-подобный UX** — keyboard-first интерфейс

## Известные особенности

1. После удаления из `/Applications` нужно переустановить для работы как URL handler
2. Паттерны проверяются в порядке следования в конфиге
3. Кириллица в комментариях конфига работает корректно (UTF-8)
4. macOS может кэшировать старые версии — при проблемах изменить Bundle ID
