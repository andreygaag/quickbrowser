# История изменений QuickBrowser

## 2026-02-15 - v1.1 - Menu Bar

### Добавлено
- ✅ Иконка глобуса в menu bar (системный трей)
- ✅ Меню управления с опциями:
  - Открыть конфигурацию (открывает в TextEdit)
  - О программе (показывает информацию)
  - Выход (⌘Q)
- ✅ Автоматическое создание конфига при первом открытии
- ✅ Приложение остаётся в фоне после выбора браузера

### Изменено
- Приложение больше не завершается после открытия браузера
- ESC закрывает overlay вместо выхода из приложения
- Overlay автоматически закрывается при выборе браузера

### Технические детали
- Добавлен NSStatusItem в AppDelegate
- Убран NSApp.terminate() из openBrowser()
- KeyboardHandler закрывает окно через self.window?.close()

## 2026-02-15 - Релиз v1.0

### Реализовано
- ✅ Перехват http/https URL как браузер по умолчанию
- ✅ CLI-подобный overlay интерфейс
- ✅ Выбор браузера через клавиатуру (1-9, ESC)
- ✅ Background режим (LSUIElement)
- ✅ Парсинг конфигурации из ~/.config/quickbrowser
- ✅ Валидация существования браузеров
- ✅ Обработка ошибок через NSAlert
- ✅ Автозакрытие после выбора

### Архитектура
- AppKit на чистом Swift
- 7 файлов, ~300 строк кода
- Нет внешних зависимостей
- SOLID принципы

### Исправленные проблемы при разработке

#### 1. AppDelegate не вызывался
**Проблема**: `@main` не работал без Main.storyboard
**Решение**: Создан явный `main.swift` с инициализацией NSApplication

#### 2. URL события не доходили
**Проблема**: При использовании `open -a QuickBrowser URL` система не отправляла URL события
**Решение**:
- Добавлен `CFBundleDocumentTypes` в Info.plist для регистрации как HTML обработчик
- Приложение должно быть установлено как браузер по умолчанию

#### 3. Клавиши не обрабатывались
**Проблема**: `.nonactivatingPanel` не позволял окну принимать keyboard events
**Решение**:
- Убран `.nonactivatingPanel` из styleMask
- Добавлено `override var canBecomeKey: Bool { true }`

#### 4. Safari не находился
**Проблема**: Путь `/System/Applications/Safari.app` не существовал
**Решение**: Использовать `/Applications/Safari.app` (символическая ссылка)

### Файловая структура
```
QuickBrowser/
├── QuickBrowser/
│   ├── App/
│   │   ├── main.swift              # НОВОЕ: явная точка входа
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   └── QuickBrowser.entitlements
│   ├── Core/
│   │   ├── BrowserEntry.swift
│   │   ├── Config.swift
│   │   └── Launcher.swift
│   └── UI/
│       ├── BrowserListView.swift
│       ├── KeyboardHandler.swift
│       └── OverlayWindow.swift     # ИСПРАВЛЕНО: canBecomeKey
└── QuickBrowser.xcodeproj/

Документация:
├── README.md
├── INSTALL.md
├── IMPLEMENTATION.md
└── CHANGELOG.md
```

### Конфигурация

**Info.plist** ключевые настройки:
```xml
<key>LSUIElement</key><true/>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>http</string><string>https</string></array>
  </dict>
</array>
<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>LSItemContentTypes</key>
    <array><string>public.html</string></array>
  </dict>
</array>
```

**Entitlements**:
```xml
<key>com.apple.security.app-sandbox</key><false/>
```

### Тестирование

Проверено на:
- macOS Sequoia 26.2
- Xcode 17C52
- Apple Silicon (arm64)

Тестовые браузеры:
- Safari
- Firefox
- Firefox Nightly

### Известные ограничения

1. Требует отключения App Sandbox для доступа к:
   - `~/.config/quickbrowser`
   - `/usr/bin/open` для запуска браузеров

2. Overlay показывается только на главном экране

3. Максимум 9 браузеров (клавиши 1-9)

### Будущие улучшения (опционально)

- [ ] Таймер автозакрытия (30 секунд)
- [ ] Поддержка нескольких мониторов
- [ ] Кеширование конфигурации
- [ ] Логирование через os.log
- [ ] Release сборка с code signing
- [ ] Homebrew формула для установки

## Метрики

- Время разработки: ~2 часа
- Количество итераций: 15+
- Строк кода: 289 (Swift)
- Файлов проекта: 12
- Зависимостей: 0
