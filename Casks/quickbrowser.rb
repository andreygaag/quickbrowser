cask "quickbrowser" do
  version "1.3.0"
  sha256 "64ad7b0250b1c8e289c1917e18fd2e5445136a7f4e19727f98e3544f67d3c0d5"

  url "https://github.com/andreygaag/quickbrowser/releases/download/v#{version}/QuickBrowser-#{version}.zip"
  name "QuickBrowser"
  desc "Minimalist browser picker and URL router for macOS"
  homepage "https://github.com/andreygaag/quickbrowser"

  depends_on macos: ">= :ventura"

  app "QuickBrowser.app"

  caveats <<~EOS
    QuickBrowser is not notarized yet. If macOS blocks the first launch,
    open System Settings > Privacy & Security and allow QuickBrowser there.
  EOS

  zap trash: [
    "~/.config/quickbrowser",
    "~/.config/quickbrowser.learn",
    "~/.config/quickbrowser.stats",
    "~/Library/Preferences/com.user.quickbrowser.v2.plist",
    "~/Library/Caches/com.user.quickbrowser.v2",
  ]
end
