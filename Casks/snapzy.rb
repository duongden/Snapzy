cask "snapzy" do
  version "1.0.5"
  sha256 "82b497b6985c59853825337b2b8e2c7b378fd1de7bbdc517328e6f2de03be3a7"

  url "https://github.com/duongductrong/Snapzy/releases/download/v#{version}/Snapzy-v#{version}.dmg"
  name "Snapzy"
  desc "Native macOS screenshots, recording, annotation, and editing from the menu bar"
  homepage "https://github.com/duongductrong/Snapzy"

  depends_on macos: ">= :ventura"

  app "Snapzy.app"

  zap trash: [
    "~/Library/Application Support/Snapzy",
    "~/Library/Preferences/Snapzy.plist",
    "~/Library/Caches/Snapzy",
  ]

  caveats <<~EOS
    Snapzy is not signed with an Apple Developer ID certificate.
    On first launch, macOS may block the app. To open it:
      Right-click Snapzy.app → Open → Open

    Or run:
      xattr -cr /Applications/Snapzy.app
  EOS
end
