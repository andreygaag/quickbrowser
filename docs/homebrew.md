# Homebrew Cask Release Notes

QuickBrowser is distributed through a separate Homebrew tap:

```bash
brew tap andreygaag/quickbrowser
brew install --cask quickbrowser
```

Homebrew maps that tap to the GitHub repository `andreygaag/homebrew-quickbrowser`.

## First tap setup

Create the tap repository and copy the cask file:

```bash
brew tap-new andreygaag/quickbrowser
cp Casks/quickbrowser.rb "$(brew --repository andreygaag/quickbrowser)/Casks/quickbrowser.rb"
```

Commit and push the tap repository:

```bash
cd "$(brew --repository andreygaag/quickbrowser)"
git add Casks/quickbrowser.rb
git commit -m "Add QuickBrowser cask"
git push origin main
```

## Release flow

1. Update `CFBundleShortVersionString` in `QuickBrowser/QuickBrowser/App/Info.plist`.
2. Update the README version text.
3. Tag the app repository:

```bash
git tag "v1.3.0"
git push origin "v1.3.0"
```

The release workflow uploads:

- `QuickBrowser-1.3.0.zip`
- `QuickBrowser-1.3.0.zip.sha256`

The release workflow only publishes from a tag named `v<CFBundleShortVersionString>`. A manual `workflow_dispatch` run from a branch will fail before uploading assets, so it cannot overwrite an existing release with a branch build.

The workflow builds a universal macOS app (`arm64` and `x86_64`) on the pinned `macos-15` runner.

Update the tap cask with the published checksum:

```bash
shasum -a 256 QuickBrowser-1.3.0.zip
```

Then validate the cask from inside the tap repository:

```bash
brew style --cask Casks/quickbrowser.rb
brew audit --cask --new quickbrowser
brew install --cask quickbrowser
```

## Notarization

The first Homebrew release is intentionally unsigned and not notarized. The cask and README both warn users about the macOS Gatekeeper prompt. Add Developer ID signing and notarization to the release workflow before removing that warning.
