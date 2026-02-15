# Установка и использование QuickBrowser

## Текущее состояние

Проект успешно собран. Приложение находится в:
```
~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Debug/QuickBrowser.app
```

## Быстрый тест

Приложение уже протестировано командой:
```bash
open -a ~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Debug/QuickBrowser.app "https://example.com"
```

Конфигурация создана в `~/.config/quickbrowser`:
```
1=/Applications/Safari.app
2=/System/Applications/Safari.app
```

## Следующие шаги

### 1. Открыть проект в Xcode

```bash
cd ~/quickbrowser/QuickBrowser
open QuickBrowser.xcodeproj
```

### 2. Запустить и протестировать

В Xcode:
- Product → Run (Cmd+R)
- Приложение запустится как background процесс (LSUIElement)
- В терминале выполните: `open "https://example.com"`
- Должен появиться черный overlay с выбором браузера

### 3. Управление

- Нажмите `1` или `2` для выбора браузера
- Нажмите `ESC` для отмены
- После выбора приложение автоматически закроется

### 4. Тестирование обработки ошибок

**Несуществующий браузер:**
```bash
echo "1=/Applications/FakeBrowser.app" > ~/.config/quickbrowser
open "https://example.com"
```
Ожидается alert "Браузер не найден"

**Неверный формат:**
```bash
echo "invalid" > ~/.config/quickbrowser
open "https://example.com"
```
Ожидается alert "Ошибка конфигурации"

**Восстановить конфигурацию:**
```bash
cat > ~/.config/quickbrowser << 'EOF'
1=/Applications/Safari.app
2=/System/Applications/Safari.app
3=/Applications/Firefox.app
4=/Applications/Google Chrome.app
EOF
```

### 5. Установка как браузер по умолчанию

Для использования как браузер по умолчанию:

1. Скопируйте приложение в /Applications:
```bash
cp -r ~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Debug/QuickBrowser.app /Applications/
```

2. Откройте System Settings:
   - Desktop & Dock → Default web browser
   - Выберите QuickBrowser

3. Теперь все ссылки из Mail, Messages и других приложений будут открываться через QuickBrowser

### 6. Release сборка

Для создания release версии:

1. В Xcode: Product → Archive
2. Distribute App → Copy App
3. Скопировать в /Applications

## Отладка

### Просмотр логов

```bash
log stream --predicate 'processImagePath contains "QuickBrowser"' --level debug
```

### Проверка регистрации

```bash
defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist LSHandlers
```

### Переустановка

```bash
rm -rf /Applications/QuickBrowser.app
cp -r ~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Debug/QuickBrowser.app /Applications/
```

## Настройка конфигурации

Формат файла `~/.config/quickbrowser`:
```
# Комментарии начинаются с #
1=/Applications/Safari.app
2=/Applications/Firefox.app
3=/Applications/Google Chrome.app
4=/Applications/Brave Browser.app
5=/Applications/Microsoft Edge.app
```

Каждая строка: `число=/полный/путь/к/браузеру.app`

Приложение автоматически извлекает имя браузера из пути.
