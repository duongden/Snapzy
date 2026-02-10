# Scout Report: Fast Screenshot Feature - Complete File Mapping

**Date:** 2026-02-10  
**Scope:** macOS screenshot app (Snapzy) - fast screenshot capture & file creation flow

---

## Executive Summary

Found complete flow: keyboard shortcut → capture → save to disk → QuickAccess display → post-capture actions.

**Critical Files (9 core):**
- Entry points: `KeyboardShortcutManager.swift`, `StatusBarController.swift`
- Capture engine: `ScreenCaptureManager.swift` (file writing happens here)
- Flow orchestration: `ScreenCaptureViewModel.swift`
- Post-capture: `PostCaptureActionHandler.swift`, `QuickAccessManager.swift`
- Settings: `PreferencesManager.swift`, `PreferencesKeys.swift`

**Key Finding:** File save happens in `ScreenCaptureManager.saveImage()` (lines 310-349) using `CGImageDestinationCreateWithURL` + `CGImageDestinationFinalize`. No async file I/O - synchronous write on main thread.

---

## 1. Entry Points - Keyboard Shortcuts & Menu Actions

### Primary Entry: `KeyboardShortcutManager.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/KeyboardShortcutManager.swift`

**Responsibility:** Global keyboard shortcut registration (Carbon EventHotKey API)

**Default Shortcuts:**
- Fullscreen: `Cmd+Shift+3` (line 23-26)
- Area: `Cmd+Shift+4` (line 29-32)
- OCR: `Cmd+Shift+2` (line 41-44)
- Recording: `Cmd+Shift+5` (line 35-38)

**Flow:**
1. User presses shortcut → Carbon event handler (line 365-385)
2. `handleHotkey(id:)` dispatches to delegate (line 397-414)
3. Delegate = `ScreenCaptureViewModel` → calls `captureFullscreen()` or `captureArea()` (line 134-141)

**Storage:** UserDefaults keys for custom shortcuts (line 204-210)

### Secondary Entry: `StatusBarController.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/App/StatusBarController.swift`

**Responsibility:** NSStatusItem menu bar integration

**Menu Actions:**
- "Capture Area" → `captureAreaAction()` → `viewModel.captureArea()` (line 326-328)
- "Capture Fullscreen" → `captureFullscreenAction()` → `viewModel.captureFullscreen()` (line 330-332)
- "Capture Text (OCR)" → `captureOCRAction()` → `viewModel.captureOCR()` (line 334-336)

**Note:** Menu items disabled if `!viewModel.hasPermission` (line 206, 218, 229)

---

## 2. Capture Flow Orchestration

### `ScreenCaptureViewModel.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/ScreenCaptureViewModel.swift`

**Responsibility:** Coordinates capture workflow, manages state

**Key Methods:**

#### `captureFullscreen()` (line 165-186)
```
Task {
  50ms delay for UI update
  → captureManager.captureFullscreen(saveDirectory, format, excludeDesktopIcons, excludeDesktopWidgets)
  → play "Glass" sound if success
}
```

#### `captureArea()` (line 188-244)
```
Hide app → 50ms delay
→ AreaSelectionController.startSelection { rect in
    100ms delay (ensure overlay hidden from screen buffer)
    → captureManager.captureArea(rect, saveDirectory, format, excludeDesktopIcons, excludeDesktopWidgets)
    → play "Glass" sound if success
}
```

**Save Directory:** (line 62-64)
- Default: `Desktop/Snapzy`
- Stored in `@Published var saveDirectory: URL`
- Can be changed via `chooseSaveDirectory()` (line 246-257) using NSOpenPanel

**Post-Capture Hook:** (line 74-83)
- Subscribes to `captureManager.captureCompletedPublisher`
- On success → `postCaptureHandler.handleScreenshotCapture(url:)`

---

## 3. Screenshot Capture & File Writing (CRITICAL)

### `ScreenCaptureManager.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/ScreenCaptureManager.swift`

**Responsibility:** ScreenCaptureKit integration, file I/O

#### `captureFullscreen()` (line 110-161)
**Parameters:**
- `saveDirectory: URL` - where to save
- `fileName: String?` - optional custom name (default: timestamp)
- `displayID: CGDirectDisplayID?` - which display (default: main)
- `format: ImageFormat` - png/jpeg/tiff (default: png)
- `excludeDesktopIcons/excludeDesktopWidgets: Bool` - filter settings

**Process:**
1. Permission check (line 119-124)
2. Get `SCShareableContent.current` (line 130)
3. Find target display (line 133-139)
4. Build filter + config (line 142-147) - Retina resolution (width*2, height*2)
5. **Capture:** `SCScreenshotManager.captureImage(contentFilter, configuration)` (line 150-153)
6. **Save:** `saveImage(image, saveDirectory, fileName, format)` (line 156) ← FILE WRITE HAPPENS HERE

#### `captureArea()` (line 172-305)
Similar flow, but with:
- Coordinate conversion (Cocoa bottom-left → CG top-left, line 199-204)
- Display intersection detection (line 209-230)
- `config.sourceRect` for cropping (line 287)
- Retina scaling (line 239-249)

#### `saveImage()` - FILE CREATION (line 310-349) ⭐
**This is where screenshot files are written to disk**

```swift
private func saveImage(
  _ image: CGImage,
  to directory: URL,
  fileName: String?,
  format: ImageFormat
) -> CaptureResult {
  
  // 1. Create directory if needed
  FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) // line 319
  
  // 2. Generate filename (timestamp if nil)
  let name = fileName ?? generateFileName() // line 325
  let fileURL = directory.appendingPathComponent("\(name).\(format.fileExtension)") // line 326
  
  // 3. Create CGImageDestination
  guard let destination = CGImageDestinationCreateWithURL(
    fileURL as CFURL,
    format.utType, // "public.png", "public.jpeg", "public.tiff"
    1,
    nil
  ) else { return .failure(.saveFailed("Could not create image destination")) }
  
  // 4. Add image and finalize (SYNCHRONOUS WRITE)
  CGImageDestinationAddImage(destination, image, nil) // line 341
  
  if CGImageDestinationFinalize(destination) { // line 343 - BLOCKS UNTIL FILE WRITTEN
    captureCompletedSubject.send(fileURL) // line 344 - triggers post-capture actions
    return .success(fileURL)
  } else {
    return .failure(.saveFailed("Failed to write image to disk"))
  }
}
```

**File Naming:** `generateFileName()` (line 352-356)
- Pattern: `"Snapzy_yyyy-MM-dd_HH-mm-ss"`
- Example: `Snapzy_2026-02-10_14-23-45.png`

**Image Formats:** `ImageFormat` enum (line 489-509)
- `.png` → "public.png" → `.png`
- `.jpeg(quality: CGFloat)` → "public.jpeg" → `.jpg`
- `.tiff` → "public.tiff" → `.tiff`

**Performance Issue:** Synchronous file I/O on main thread - no async/await for file writing. `CGImageDestinationFinalize()` blocks until complete.

---

## 4. QuickAccess Panel (Recent Screenshots Display)

### `QuickAccessManager.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessManager.swift`

**Responsibility:** Manages floating screenshot preview stack (max 5 items)

#### `addScreenshot(url:)` (line 113-139) - called after file save
```
Generate thumbnail from file URL
→ Create QuickAccessItem(url, thumbnail)
→ Insert at top of items array (animated)
→ Show panel if first item
→ Start auto-dismiss timer (default: 10s)
```

**Related Files:**
- `QuickAccessPanelController.swift` - NSPanel window management
- `QuickAccessStackView.swift` - SwiftUI stack view (git modified)
- `QuickAccessCardView.swift` - individual card UI (git modified)
- `QuickAccessItem.swift` - data model (id, url, thumbnail, duration?)
- `QuickAccessPosition.swift` - bottomRight/bottomLeft/topRight/topLeft

**Settings (UserDefaults):**
- `floatingScreenshot.enabled` - show/hide panel (default: true)
- `floatingScreenshot.position` - screen corner placement
- `floatingScreenshot.autoDismissEnabled` - auto-hide (default: true)
- `floatingScreenshot.autoDismissDelay` - timeout (default: 10s)
- `floatingScreenshot.overlayScale` - UI scale (default: 1.0)
- `floatingScreenshot.dragDropEnabled` - drag file out (default: true)

**Actions:**
- Copy to clipboard → `copyToClipboard(id:)` (line 197-220)
- Delete file → `deleteItem(id:)` (line 223-236) - uses `FileManager.trashItem`
- Show in Finder → `openInFinder(id:)` (line 239-254)

---

## 5. Post-Capture Actions

### `PostCaptureActionHandler.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/Services/PostCaptureActionHandler.swift`

**Responsibility:** Execute user-configured actions after screenshot saved

#### `handleScreenshotCapture(url:)` (line 25-27) - called from ScreenCaptureManager publisher
```
executeActions(for: .screenshot, url:) {
  if showQuickAccess enabled → quickAccessManager.addScreenshot(url)
  if copyFile enabled → copyToClipboard(url, isVideo: false)
}
```

**Available Actions:** (from `PreferencesManager.swift`)
- `showQuickAccess` - display in QuickAccess panel (default: ON)
- `copyFile` - copy to clipboard (default: ON)
- `save` - save to disk (default: ON, always executed by ScreenCaptureManager)

**Configuration:** `AfterCaptureAction` × `CaptureType` matrix (screenshot vs recording)

### `PreferencesManager.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Preferences/PreferencesManager.swift`

**Responsibility:** Complex preferences state management

**Storage:** UserDefaults key `"afterCaptureActions"` (line 44)
- JSON encoded: `[String: [String: Bool]]` (line 77-90)
- Example: `{"showQuickAccess": {"screenshot": true, "recording": true}}`

---

## 6. Settings & Configuration Files

### `PreferencesKeys.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Preferences/PreferencesKeys.swift`

**All UserDefaults Keys:**
```swift
// General
exportLocation - save directory path
hideDesktopIcons - exclude Finder windows (default: false)
hideDesktopWidgets - exclude widgets (default: false)
playSounds - "Glass" sound on capture (default: true)

// Shortcuts
shortcutsEnabled - enable global hotkeys
fullscreenShortcut, areaShortcut, recordingShortcut - custom bindings

// QuickAccess (floating screenshot panel)
floatingScreenshot.enabled
floatingScreenshot.position
floatingScreenshot.autoDismissEnabled
floatingScreenshot.autoDismissDelay
floatingScreenshot.overlayScale
floatingScreenshot.dragDropEnabled
floatingScreenshot.showCloudUpload
```

**Note:** No `exportLocation` key currently used in ScreenCaptureViewModel - it defaults to Desktop/Snapzy without persistence.

---

## 7. Supporting Services

### `DesktopIconManager.swift`
**Path:** `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/Services/DesktopIconManager.swift`

**Responsibility:** Build SCContentFilter to exclude Finder/Widgets from screenshots

**Used by:** ScreenCaptureManager.buildFilter() (line 461-484)
- `getFinderApps(from:)` - finds Finder in SCRunningApplication list
- `getVisibleFinderWindows(from:)` - preserves open Finder windows via exceptingWindows
- `getWidgetApps(from:)` - finds widget processes

**Pattern:** Exclude Finder app → hides desktop icons, but preserve regular Finder windows. Wallpaper rendered by Dock, not affected.

### `ThumbnailGenerator` (referenced but not found in grep)
**Responsibility:** Generate NSImage thumbnails for QuickAccess cards

**Used by:** QuickAccessManager.addScreenshot() (line 115)
- `ThumbnailGenerator.generate(from: url)` → returns thumbnail + duration (for videos)

---

## Complete Flow Diagram

```
USER PRESSES CMD+SHIFT+4
↓
KeyboardShortcutManager (Carbon EventHotKey)
  → handleHotkey(id: 2) // areaHotkeyID
  → delegate.shortcutTriggered(.captureArea)
↓
ScreenCaptureViewModel.captureArea()
  → NSApp.hide(nil) // hide app window
  → 50ms delay
  → AreaSelectionController.startSelection { rect in
      → 100ms delay (overlay fade out)
      ↓
      ScreenCaptureManager.captureArea(rect, saveDirectory, format, ...)
        → SCShareableContent.current
        → Find display, convert coordinates
        → Build SCContentFilter (exclude desktop icons/widgets if enabled)
        → SCScreenshotManager.captureImage() // ScreenCaptureKit API
        ↓
        ⭐ saveImage(cgImage, saveDirectory, fileName, format)
          → FileManager.createDirectory(saveDirectory)
          → fileName = "Snapzy_2026-02-10_14-23-45"
          → fileURL = saveDirectory/"Snapzy_2026-02-10_14-23-45.png"
          → CGImageDestinationCreateWithURL(fileURL, "public.png", 1)
          → CGImageDestinationAddImage(destination, cgImage)
          → CGImageDestinationFinalize(destination) // SYNCHRONOUS FILE WRITE
          → captureCompletedSubject.send(fileURL) // publish success
          → return .success(fileURL)
    }
  → playScreenshotSound() // "Glass"
↓
ScreenCaptureViewModel (Combine subscriber)
  → receives fileURL from captureCompletedPublisher
  → PostCaptureActionHandler.handleScreenshotCapture(url: fileURL)
    → if showQuickAccess enabled:
        QuickAccessManager.addScreenshot(url: fileURL)
          → ThumbnailGenerator.generate(from: fileURL)
          → items.insert(QuickAccessItem(url, thumbnail), at: 0)
          → panelController.show(QuickAccessStackView)
          → startDismissTimer(10s)
    → if copyFile enabled:
        NSPasteboard.general.writeObjects([NSImage(contentsOf: fileURL)])
        NSSound("Pop").play()
```

---

## Files by Category

### Core Capture (4 files)
1. `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/ScreenCaptureManager.swift` ⭐ FILE WRITE
2. `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/ScreenCaptureViewModel.swift` - orchestration
3. `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/KeyboardShortcutManager.swift` - entry point
4. `/Users/duongductrong/Developer/ZapShot/Snapzy/App/StatusBarController.swift` - menu entry

### Post-Capture (2 files)
5. `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/Services/PostCaptureActionHandler.swift`
6. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessManager.swift`

### Settings (2 files)
7. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Preferences/PreferencesManager.swift`
8. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Preferences/PreferencesKeys.swift`

### QuickAccess UI (5 files)
9. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessPanelController.swift`
10. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessStackView.swift` ⚠️ git modified
11. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessCardView.swift` ⚠️ git modified
12. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessItem.swift`
13. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessPosition.swift`

### Supporting (3 files)
14. `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/Services/DesktopIconManager.swift`
15. `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/AreaSelectionWindow.swift`
16. `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/QuickAccess/QuickAccessSound.swift`

---

## Key Code Snippets

### File Save Location Logic (ScreenCaptureViewModel.swift:62-64)
```swift
init() {
  let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
  saveDirectory = desktop.appendingPathComponent("Snapzy")
  // No UserDefaults persistence - resets to Desktop/Snapzy on app restart
}
```

### File Write (ScreenCaptureManager.swift:310-349)
```swift
private func saveImage(
  _ image: CGImage,
  to directory: URL,
  fileName: String?,
  format: ImageFormat
) -> CaptureResult {
  // Create directory
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  
  // Generate filename
  let name = fileName ?? generateFileName() // "Snapzy_yyyy-MM-dd_HH-mm-ss"
  let fileURL = directory.appendingPathComponent("\(name).\(format.fileExtension)")
  
  // Write image (SYNCHRONOUS)
  guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, format.utType, 1, nil) else {
    return .failure(.saveFailed("Could not create image destination"))
  }
  
  CGImageDestinationAddImage(destination, image, nil)
  
  if CGImageDestinationFinalize(destination) { // BLOCKS HERE
    captureCompletedSubject.send(fileURL) // trigger post-capture
    return .success(fileURL)
  } else {
    return .failure(.saveFailed("Failed to write image to disk"))
  }
}
```

### Filename Generation (ScreenCaptureManager.swift:352-356)
```swift
private func generateFileName() -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
  return "Snapzy_\(formatter.string(from: Date()))"
}
```

---

## Unresolved Questions

1. **ThumbnailGenerator location?** Referenced in QuickAccessManager.swift:115, 144 but not found in grep. Possibly in a separate file not matched by search terms.

2. **Save directory persistence?** PreferencesKeys.swift defines `exportLocation` key (line 18), but ScreenCaptureViewModel doesn't persist `saveDirectory` to UserDefaults. Is this intentional? Does it reset to Desktop/Snapzy on every app launch?

3. **File write performance?** `CGImageDestinationFinalize()` is synchronous and blocks main thread. For large screenshots (Retina 2x resolution), this could cause UI jank. Should this be moved to background queue?

4. **QuickAccessStackView/CardView modifications?** Git status shows these files modified. Are there uncommitted changes related to fast screenshot file creation?

5. **AreaSelectionController?** Referenced extensively but not in scout files. Where is area selection UI managed?

---

## Search Keywords Used
- fastScreenshot, fast_screenshot, quickScreenshot, instantCapture ❌ (no matches)
- captureScreen, saveScreenshot, screenshot, capture ✅ (48 files)
- QuickAccess ✅ (26 files)
- savePath, saveURL, fileManager, write, pngData, tiffRepresentation ✅ (18 files)

## Recommendations for Next Steps

1. Read `AreaSelectionController.swift` to understand selection UI lifecycle
2. Find `ThumbnailGenerator.swift` location
3. Check git diff for QuickAccessStackView.swift + QuickAccessCardView.swift changes
4. Review file write performance - consider async I/O for large screenshots
5. Add UserDefaults persistence for `saveDirectory` if needed
