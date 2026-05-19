# QuickBrowser

A minimalist browser picker for macOS. Intercepts http/https links and either opens them in a chosen browser or routes them automatically based on URL patterns.

<p align="center">
  <img src="screenshots/picker.png" alt="Browser picker overlay" width="380"><br>
  <sub>Browser picker overlay</sub>
</p>

## Features

- **Browser picker overlay** — keyboard-first, pick a browser with keys `1`–`9`
- **Pattern-based routing** — URLs matching a pattern open in the assigned browser without prompting
- **Auto-learning** — after picking the same browser for a domain 5 times, QuickBrowser offers to remember the choice (or saves it silently if `autolearn=true`)
- **Usage statistics** — see how often each browser is used (manual vs. automatic)
- **SwiftUI config editor** — manage browsers and patterns from the menu bar
- **Zero dependencies** — single small Swift binary

## System Requirements

- **macOS 13.0 (Ventura)** or later
- **Apple Silicon or Intel** — universal binary
- **~2 MB** disk space
- **No external dependencies**

## Comparison

QuickBrowser is intentionally narrow: it focuses on fast http/https link routing with a tiny native app, editable config, and automation that reduces repeated choices over time.

- **Small and native** — a Swift app with no Electron runtime or bundled dependencies
- **Config you own** — plain text rules that are easy to diff, grep, back up, or version-control
- **Learns your habits** — repeated domain choices can become routing rules automatically
- **Transparent usage** — built-in stats show which browsers are used manually vs. automatically
- **Free and open source** — MIT-licensed and easy to inspect or modify

| | QuickBrowser | [Browserosaurus](https://github.com/will-stone/browserosaurus) | [OpenIn](https://loshadki.app/openin4/) | [Choosy](https://choosy.app/) |
|---|---|---|---|---|
| **License** | **MIT** | MIT (archived) | Proprietary | Proprietary |
| **Price** | **Free** | Free | $9.99 / Setapp | $10 one-time |
| **Maintained** | **Yes** | No (archived 2025) | Yes | Yes |
| **Tech** | **Native Swift** | Electron | Native | Native |
| **App size** | **~2 MB** | ~150 MB | — | — |
| **Notarized** | No | Yes | Yes | Yes |
| **Config** | **Plain text + GUI** | GUI | GUI | GUI |
| **URL pattern rules** | Yes | Yes | Yes | Yes (advanced) |
| **Auto-learning** | **Yes** | No | No | No |
| **Source-app rules** | No | No | Yes | Yes |
| **Browser profiles** | No | No | Yes | Yes |
| **Time-of-day rules** | No | No | No | Yes |
| **mailto / files** | No | No | Yes | No |
| **Usage statistics** | **Yes** | No | No | No |
| **Keyboard picker (1-9)** | Yes | Yes | Yes | Yes |

QuickBrowser is the best fit when you want a lightweight, auditable default-browser router that gets out of the way after it learns your common domains. If you need source-app rules, browser profiles, or mailto/file routing, OpenIn or Choosy will fit better.

## Installation

### Option A — Homebrew

QuickBrowser can be installed from the Homebrew tap:

```bash
brew tap andreygaag/quickbrowser
brew install --cask quickbrowser
```

QuickBrowser is not notarized yet. If macOS blocks the first launch with "Apple could not verify QuickBrowser.app is free of malware", allow it once:

```bash
xattr -dr com.apple.quarantine /Applications/QuickBrowser.app
open /Applications/QuickBrowser.app
```

You can also allow it from **System Settings** → **Privacy & Security** → **Open Anyway**.

Then set QuickBrowser as the default browser:

1. Open **System Settings** → **Desktop & Dock**
2. Scroll to **Default web browser**
3. Choose **QuickBrowser**

To uninstall:

```bash
brew uninstall --cask quickbrowser
```

### Option B — Build manually

#### 1. Build

Open the project in Xcode:

```bash
open QuickBrowser/QuickBrowser.xcodeproj
```

Select the **QuickBrowser** scheme with **My Mac** as target, then `Product` → `Build` (⌘B), or build a Release artifact from the terminal:

```bash
cd QuickBrowser
xcodebuild -project QuickBrowser.xcodeproj \
           -scheme QuickBrowser \
           -configuration Release \
           clean build
```

The Release build lands in:

```
~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Release/QuickBrowser.app
```

#### 2. Copy to Applications

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/QuickBrowser-*/Build/Products/Release/QuickBrowser.app \
      /Applications/
```

Or drag `QuickBrowser.app` into `/Applications` manually. Installation in `/Applications` is required — macOS only registers URL handlers for apps placed there.

#### 3. Set as default browser

**Option A — System Settings (recommended)**

1. Open **System Settings** → **Desktop & Dock**
2. Scroll to **Default web browser**
3. Choose **QuickBrowser**

**Option B — Launch once**

```bash
open /Applications/QuickBrowser.app
```

macOS will register it as a URL handler. Then set it as default in System Settings.

#### 4. Verify

```bash
open -a /Applications/QuickBrowser.app "https://github.com"
```

The configured browser should open (or the picker overlay if no pattern matches).

## Configuration

Create `~/.config/quickbrowser`:

```
# Settings
autolearn=true

# Browsers — format: key=path
1=/Applications/Safari.app
2=/Applications/Firefox.app
3=/Applications/Google Chrome.app

# Patterns — format: pattern browser_key
github.com 2
openai.com 1
stackoverflow 2
```

You can also edit the config from the menu bar: click the globe icon → **Edit configuration**.

### Config rules

- Lines starting with `#` are comments
- Empty lines are ignored
- `autolearn=true` saves learned patterns silently; otherwise QuickBrowser asks for confirmation
- Browser keys must be digits (`1`–`9`)
- Browser paths must exist
- Patterns are evaluated in file order — the **first** match wins

## Usage

After installation, QuickBrowser intercepts every http/https click:

- **URL matches a pattern** → opens automatically in the assigned browser
- **No match** → overlay appears; press `1`–`9` to pick, `Esc` to cancel
- **Same domain picked 5 times in a row** → QuickBrowser offers to add a pattern (or auto-adds it with `autolearn=true`)

## Pattern matching

Patterns are matched against both the URL host and the full URL string:

| Pattern | Matches |
|---------|---------|
| `github.com` | `https://github.com/...`, `https://api.github.com/...` |
| `api.example.com` | only the `api` subdomain |
| `stackoverflow` | any URL containing `stackoverflow` |

## Menu bar

Click the globe icon in the menu bar:

- **Edit configuration** — open the SwiftUI editor for browsers and patterns
- **Statistics** — show usage counts (manual vs. automatic) per browser
- **About** — version and feature summary
- **Quit** — exit QuickBrowser

## Troubleshooting

**Links don't open in QuickBrowser**
- Confirm `QuickBrowser.app` is in `/Applications` (not Downloads or Desktop)
- Re-select QuickBrowser as the default browser in System Settings
- If macOS caches an old version, change the Bundle ID and rebuild

**"Configuration not found"**
- Create `~/.config/quickbrowser` with at least one browser line, e.g. `1=/Applications/Safari.app`

**"Browser not found"**
- Verify the path in the config is correct and the `.app` exists

## Version

**v1.5.0** — Pattern-based routing, auto-learning, usage statistics, SwiftUI config editor
