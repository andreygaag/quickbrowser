# QuickBrowser

Минималистичное macOS приложение для быстрого выбора браузера при открытии ссылок.

## Возможности

- Перехватывает http/https ссылки как браузер по умолчанию
- Показывает CLI-подобный overlay для выбора браузера
- Выбор через клавиатуру (1, 2, 3...)
- Работает как background приложение (без иконки в Dock)
- Нет внешних зависимостей

## Установка

QuickBrowser уже установлен и настроен как браузер по умолчанию!

### Расположение
```
/Applications/QuickBrowser.app
```

### Конфигурация
```
~/.config/quickbrowser
```

Текущие браузеры:
```
1=/Applications/Safari.app
2=/Applications/Firefox.app
3=/Applications/Firefox Nightly.app
```

## Использование

### Открытие ссылок

Просто кликните на любую ссылку в Mail, Messages или других приложениях:

1. Появится черный overlay по центру экрана
2. Зеленый текст покажет доступные браузеры:
   ```
   [1] Safari
   [2] Firefox
   [3] Firefox Nightly
   ```
3. Нажмите нужную цифру для выбора
4. Или ESC для отмены

### Из терминала

```bash
open "https://example.com"
```

### Управление

- **1-9** - выбрать браузер
- **ESC** - отмена и выход

## Настройка браузеров

Отредактируйте `~/.config/quickbrowser`:

```bash
nano ~/.config/quickbrowser
```

Формат:
```
# Комментарии начинаются с #
1=/Applications/Safari.app
2=/Applications/Firefox.app
3=/Applications/Google Chrome.app
4=/Applications/Brave Browser.app
```

Каждая строка: `число=/полный/путь/к/браузеру.app`

QuickBrowser автоматически извлекает имя браузера из пути.

## Разработка

### Открыть проект

```bash
cd ~/quickbrowser/QuickBrowser
open QuickBrowser.xcodeproj
```

### Сборка

В Xcode:
- **Cmd+B** - Build
- **Cmd+R** - Run (для отладки)

Из терминала:
```bash
cd ~/quickbrowser/QuickBrowser
xcodebuild -project QuickBrowser.xcodeproj -scheme QuickBrowser -configuration Debug build
```

### Установка после изменений

```bash
cp -r ~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Debug/QuickBrowser.app /Applications/
```

## Архитектура

```
QuickBrowser/
├── App/
│   ├── main.swift                 # Точка входа
│   ├── AppDelegate.swift          # Координатор
│   ├── Info.plist                 # Конфигурация (LSUIElement, URL схемы)
│   └── QuickBrowser.entitlements  # Отключение sandbox
├── Core/
│   ├── BrowserEntry.swift         # Модель браузера
│   ├── Config.swift               # Парсинг конфигурации
│   └── Launcher.swift             # Запуск браузера через Process
└── UI/
    ├── OverlayWindow.swift        # NSPanel с настройками
    ├── BrowserListView.swift      # Отрисовка списка
    └── KeyboardHandler.swift      # Перехват клавиш
```

## Технические детали

- **Язык**: Swift 5.0
- **Framework**: AppKit (macOS 13.0+)
- **Размер кода**: ~300 строк
- **Зависимости**: Нет (только Foundation и Cocoa)

### Ключевые компоненты

**main.swift** - явная точка входа:
```swift
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

**Info.plist**:
- `LSUIElement = true` - background приложение
- `CFBundleURLTypes` - регистрация http/https схем
- `CFBundleDocumentTypes` - регистрация HTML документов

**OverlayWindow**:
- `canBecomeKey = true` - принимает события клавиатуры
- `level = .floating` - всегда поверх других окон
- `styleMask = .borderless` - без рамки

## Удаление

1. Смените браузер по умолчанию в System Settings
2. Удалите приложение:
   ```bash
   rm -rf /Applications/QuickBrowser.app
   rm ~/.config/quickbrowser
   ```

## Решение проблем

### QuickBrowser не появляется в списке браузеров

Перерегистрируйте:
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/QuickBrowser.app
```

Затем перезапустите System Settings.

### Overlay не появляется

Проверьте, что QuickBrowser установлен как браузер по умолчанию:
```
System Settings → Desktop & Dock → Default web browser → QuickBrowser
```

### Клавиши не работают

Убедитесь, что используете последнюю версию с `canBecomeKey = true` в OverlayWindow.

### Ошибка "Браузер не найден"

Проверьте пути в `~/.config/quickbrowser`:
```bash
cat ~/.config/quickbrowser
```

Убедитесь, что все пути существуют:
```bash
ls /Applications/Safari.app
ls /Applications/Firefox.app
```

## Лицензия

Свободное использование и модификация.
