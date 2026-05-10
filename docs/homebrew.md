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

### Automated

After updating the app code, version, and README, run:

```bash
scripts/release-homebrew.sh
```

The script reads `CFBundleShortVersionString`, creates/pushes `v<version>` if needed, runs the GitHub release workflow, waits for it to finish, downloads the published `.sha256`, updates `Casks/quickbrowser.rb`, copies it into the Homebrew tap, and validates the tap cask.

By default it leaves commits for review. To commit and push both repositories automatically:

```bash
COMMIT_AND_PUSH=1 scripts/release-homebrew.sh
```

### Manual

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

The release workflow publishes to a tag named `v<CFBundleShortVersionString>`. On tag pushes, the pushed tag must match the app version. On manual runs, pass the existing release tag explicitly:

```bash
gh workflow run release.yml -f release_tag=v1.3.0
```

Manual runs fail before uploading assets if `release_tag` does not match `CFBundleShortVersionString`.

The workflow builds a universal macOS app (`arm64` and `x86_64`) on the pinned `macos-15` runner.

Update the tap cask with the published checksum:

```bash
shasum -a 256 QuickBrowser-1.3.0.zip
```

Then validate the cask from inside the tap repository:

```bash
brew style --cask Casks/quickbrowser.rb
brew audit --cask quickbrowser
brew install --cask quickbrowser
```

`brew audit --cask --new` is intended for casks proposed to the official Homebrew cask repository. For this personal tap it will fail until the app is notarized and the GitHub repository meets Homebrew's notability thresholds. If you still want the extra `--new` checks locally, skip those two official-repository policy checks:

```bash
brew audit --cask --new --no-signing --except=github_repository quickbrowser
```

## Notarization

The first Homebrew release is intentionally unsigned and not notarized. The cask and README both warn users about the macOS Gatekeeper prompt. Add Developer ID signing and notarization to the release workflow before removing that warning.
