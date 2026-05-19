cask "quickbrowser" do
  version "1.5.0"
  sha256 "fa4a1aaeb1d30025c63f77542f6e136b3a35ef72690f4817da7da0fa561c9ebc"

  url "https://github.com/andreygaag/quickbrowser/releases/download/v#{version}/QuickBrowser-#{version}.zip"
  name "QuickBrowser"
  desc "Minimalist browser picker and URL router"
  homepage "https://github.com/andreygaag/quickbrowser"

  depends_on macos: :ventura

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
