cask "quickbrowser" do
  version "1.4.0"
  sha256 "582e0cf6a4bb958e49fceb91fb923ea8661b9c32d5dde1f504adf1ef00f91278"

  url "https://github.com/andreygaag/quickbrowser/releases/download/v#{version}/QuickBrowser-#{version}.zip"
  name "QuickBrowser"
  desc "Minimalist browser picker and URL router"
  homepage "https://github.com/andreygaag/quickbrowser"

  depends_on macos: ">= :ventura"

  app "QuickBrowser.app"

  zap trash: [
    "~/.config/quickbrowser",
    "~/.config/quickbrowser.learn",
    "~/.config/quickbrowser.stats",
    "~/Library/Caches/com.user.quickbrowser.v2",
    "~/Library/Preferences/com.user.quickbrowser.v2.plist",
  ]

  caveats <<~EOS
    QuickBrowser is not notarized yet. If macOS blocks the first launch,
    open System Settings > Privacy & Security and allow QuickBrowser there.
  EOS
end
