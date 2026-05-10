cask "quickbrowser" do
  version "1.3.0"
  sha256 "601064f6e838a4d59bed167442141e6579cc770c274bc5ca792dd64a0332d54b"

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
