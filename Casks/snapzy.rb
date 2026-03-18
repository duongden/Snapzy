cask "snapzy" do
  version "1.2.5"
  sha256 "1c93560240f6f026a2671bb6d2e06d208ce6b77a9e7896c5c302d1d7e59d88b1"

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
