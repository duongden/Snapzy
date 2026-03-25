cask "snapzy" do
  version "1.4.6"
  sha256 "5db17d77475718472eec5187091a2414dc3768d3b3ebffbe8db1e5d53b1cb763"

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
