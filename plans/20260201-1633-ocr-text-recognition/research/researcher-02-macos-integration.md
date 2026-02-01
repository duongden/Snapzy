# macOS Integration Research: OCR Capture Feature

## 1. Screen Capture APIs for OCR

### SCScreenshotManager (macOS 14+, Recommended)
`CGWindowListCreateImage` deprecated on macOS 13+, replaced by `SCScreenshotManager` in ScreenCaptureKit.

**Key Points:**
- Part of ScreenCaptureKit framework (macOS 14 Sonoma+)
- Two static methods: capture as `CGImage` or `CMSampleBuffer`
- Requires screen recording authorization in System Settings
- `CGWindowListCreateImage` obsolete in macOS 15.0, triggers privacy warnings

**Performance Consideration:**
`CGWindowListCreateImage` (synchronous) vs `SCScreenshotManager.createImage` (async) introduces lag on frequent captures (e.g., mouse movements).

**Code Example:**
```swift
import ScreenCaptureKit

// Async capture
let image = try await SCScreenshotManager.captureImage(
    contentFilter: filter,
    configuration: config
)
```

**Permission Bypass:**
`SCContentSharingPicker` (macOS 14+) system-level picker sometimes bypasses explicit screen recording permissions.

### Legacy CGWindowListCreateImage
Still works on macOS 12 and earlier, synchronous, no authorization on older systems.

```swift
import CoreGraphics

let image = CGWindowListCreateImage(
    rect,
    .optionOnScreenOnly,
    kCGNullWindowID,
    [.bestResolution, .boundsIgnoreFraming]
)
```

## 2. Playing System Sounds

### NSSound (Simple, High-Level)
Recommended for straightforward sound playback with control.

```swift
import Cocoa

func playSystemSound() {
    if let sound = NSSound(named: "Ping") {
        sound.play()
    }
}

// Custom sound file
if let sound = NSSound(contentsOfFile: "/path/to/sound.wav", byReference: false) {
    sound.play()
}
```

### AudioServicesPlaySystemSound (Low-Level)
Part of AudioToolbox, for short sound effects (≤30s).

**Characteristics:**
- Asynchronous playback
- Plays at system volume (no programmatic control)
- No looping, stereo positioning, or simultaneous playback
- Format: linear PCM or IMA4 in `.caf`, `.aif`, `.wav`

```swift
import AudioToolbox

// System alert sound
AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)

// Custom sound
var soundID: SystemSoundID = 0
let soundURL = CFURLCreateWithFileSystemPath(
    kCFAllocatorDefault,
    "/System/Library/Sounds/Ping.aiff" as CFString,
    .cfurlposixPathStyle,
    false
)
AudioServicesCreateSystemSoundID(soundURL!, &soundID)
AudioServicesPlaySystemSound(soundID)
```

**Recommendation:** Use `NSSound` for simplicity unless you need minimal overhead.

## 3. Global Keyboard Shortcut Registration

### Carbon HotKey APIs (Still Required)
Carbon APIs for global shortcuts not deprecated despite other Carbon deprecations. No modern Cocoa replacement exists yet.

### Recommended Libraries

#### KeyboardShortcuts (by Sindre Sorhus)
Best for user-customizable shortcuts.

```swift
import KeyboardShortcuts

// Define shortcut name
extension KeyboardShortcuts.Name {
    static let captureOCR = Self("captureOCR")
}

// Register handler
KeyboardShortcuts.onKeyUp(for: .captureOCR) {
    // Trigger OCR capture
}

// SwiftUI view for user customization
import SwiftUI

struct SettingsView: View {
    var body: some View {
        KeyboardShortcuts.Recorder("OCR Capture:", name: .captureOCR)
    }
}
```

**Features:**
- Stores shortcuts in UserDefaults
- Warns about conflicts
- SwiftUI + Cocoa support
- SPM installation

#### HotKey (by soffes)
Simpler, for hard-coded shortcuts.

```swift
import HotKey

let hotKey = HotKey(key: .s, modifiers: [.command, .shift])
hotKey.keyDownHandler = {
    // Trigger OCR capture
}
```

**Best Practice:** Don't set default global hotkeys to avoid conflicts. Prompt user to configure on first launch.

## 4. Clipboard/Pasteboard Integration

### NSPasteboard Usage
```swift
import Cocoa

func copyToClipboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents() // CRITICAL: Must clear first (unlike iOS)
    pasteboard.setString(text, forType: .string)
}

// Example
let recognizedText = "OCR result here"
copyToClipboard(text: recognizedText)
```

**Key Differences from iOS:**
- Must explicitly call `clearContents()` before setting new data
- iOS `UIPasteboard` auto-replaces; macOS `NSPasteboard` requires manual clearing

**Advanced Usage:**
```swift
// Support multiple data types
pasteboard.clearContents()
pasteboard.writeObjects([text as NSString, imageData as NSData])

// Read from clipboard
if let string = pasteboard.string(forType: .string) {
    print("Clipboard: \(string)")
}
```

**Universal Clipboard:** Automatic integration with macOS 10.12+ and iOS 10.0+ (no additional API calls needed).

## 5. Menu Bar Integration Patterns

### Hybrid SwiftUI-AppKit Approach (Recommended)
70/30 split: SwiftUI for views, AppKit for system integration.

**AppDelegate Setup:**
```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.text.viewfinder", accessibilityDescription: "OCR Capture")
            button.action = #selector(statusBarButtonClicked)
        }

        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Capture OCR", action: #selector(captureOCR), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func captureOCR() {
        // Trigger capture
    }
}
```

### SwiftUI Menu with NSHostingView
Embed SwiftUI views in NSMenu for reactive UI:

```swift
import SwiftUI

let menuItem = NSMenuItem()
menuItem.view = NSHostingView(rootView: CaptureMenuView())
menu.addItem(menuItem)
```

### Best Practices
- **Use NSMenu over NSPopover:** Native behavior, instant response, click-away dismissal
- **Disable launcher icons:** For menu bar-only apps (LSUIElement in Info.plist)
- **Window positioning:** Display window at cursor click position for capture tools

```swift
// Position window at mouse cursor
let mouseLocation = NSEvent.mouseLocation
window.setFrameTopLeftPoint(mouseLocation)
```

## Unresolved Questions

1. **OCR Engine Choice:** Vision framework vs Tesseract vs Apple's Live Text API performance comparison?
2. **Screen Recording Permission UX:** Best pattern to request SCScreenshotManager permissions without disrupting user flow?
3. **Accessibility Concerns:** VoiceOver support for menu bar capture triggers?
4. **Performance:** Optimal approach for real-time OCR on large screen areas (chunking, downsampling)?
5. **Sandboxing:** App Store sandbox compatibility with global hotkeys and screen capture?

---

## Sources

- [Screen Capture API Migration](https://nonstrict.eu)
- [Apple ScreenCaptureKit Documentation](https://apple.com)
- [NSSound Documentation](https://apple.com)
- [AudioServicesPlaySystemSound Guide](https://stackoverflow.com)
- [KeyboardShortcuts Library](https://github.com)
- [HotKey Swift Library](https://github.com)
- [NSPasteboard Documentation](https://apple.com)
- [Clipboard Integration Guide](https://stackoverflow.com)
- [Menu Bar App Best Practices](https://medium.com)
- [SwiftUI-AppKit Hybrid Approach](https://medium.com)
- [Open-Source macOS Apps](https://github.com)
