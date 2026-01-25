# Technical Analysis: MenuBar Recording Status

## Current Implementation

### ClaudeShotApp.swift (Lines 37-40)
```swift
MenuBarExtra("ClaudeShot", systemImage: "camera.aperture") {
  MenuBarContentView(viewModel: viewModel, updater: updaterController.updater)
    .preferredColorScheme(themeManager.systemAppearance)
}
```
- Static icon: `camera.aperture`
- Always shows menu on click
- No awareness of recording state

### ScreenRecordingManager State
```swift
@Published private(set) var state: RecordingState = .idle
var isRecording: Bool { state == .recording }
var isActive: Bool { state != .idle }
```
- States: `idle`, `preparing`, `recording`, `paused`, `stopping`
- Singleton: `ScreenRecordingManager.shared`

### RecordingCoordinator Stop Flow
```swift
private func stopRecording() {
  Task {
    let url = await recorder.stopRecording()
    if let url = url {
      NSSound(named: "Glass")?.play()
      await QuickAccessManager.shared.addVideo(url: url)
    }
    cleanup()
  }
}
```

## Technical Approaches Evaluation

### Approach A: Two MenuBarExtra with isInserted Binding
**Concept**: Swap between two MenuBarExtra instances based on recording state.

```swift
MenuBarExtra("ClaudeShot", systemImage: "camera.aperture", isInserted: $notRecording) {
  MenuBarContentView(...)
}
MenuBarExtra("Recording", systemImage: "record.circle.fill", isInserted: $isRecording) {
  // Minimal or empty content
}
```

**Pros**:
- Pure SwiftUI approach
- Clean separation of concerns

**Cons**:
- Two status items may flicker during swap
- No native click-without-menu support in MenuBarExtra
- Potential timing issues between state change and UI update

**Verdict**: NOT RECOMMENDED - MenuBarExtra always shows menu on click

### Approach B: Custom NSStatusItem
**Concept**: Replace MenuBarExtra with manual NSStatusItem for full control.

```swift
class StatusBarController: ObservableObject {
  private var statusItem: NSStatusItem?

  func setup() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem?.button?.action = #selector(handleClick)
  }

  @objc func handleClick() {
    if ScreenRecordingManager.shared.isRecording {
      RecordingCoordinator.shared.stopRecording()
    } else {
      showMenu()
    }
  }
}
```

**Pros**:
- Full control over click behavior
- Can distinguish left-click vs right-click
- Native macOS pattern

**Cons**:
- Must manually manage menu lifecycle
- More boilerplate code
- Loses SwiftUI declarative benefits for menu content

**Verdict**: RECOMMENDED - Only approach that enables click-to-stop

### Approach C: MenuBarExtra with Dynamic Label + Conditional Content
**Concept**: Use MenuBarExtra with Label view for dynamic icon.

```swift
MenuBarExtra {
  if viewModel.isRecording {
    Button("Stop Recording") { ... }
  } else {
    MenuBarContentView(...)
  }
} label: {
  Image(systemName: viewModel.isRecording ? "record.circle.fill" : "camera.aperture")
}
```

**Pros**:
- Stays within SwiftUI
- Dynamic icon works

**Cons**:
- Still shows menu on click (cannot skip menu during recording)
- User must click menu item to stop (two clicks)

**Verdict**: PARTIAL - Good for dynamic icon, but fails click-to-stop requirement

## Recommended Architecture

**Hybrid Approach**: Use NSStatusItem with SwiftUI menu content via NSHostingView.

1. Create `StatusBarController` class managing NSStatusItem
2. Observe `ScreenRecordingManager.shared.state` via Combine
3. Update icon based on state
4. Handle click: if recording -> stop, else -> show NSMenu with SwiftUI content
5. Integrate in AppDelegate during app launch

## Key Files to Modify

| File | Changes |
|------|---------|
| `ClaudeShotApp.swift` | Remove MenuBarExtra, init StatusBarController |
| NEW: `StatusBarController.swift` | NSStatusItem management, click handling |
| `AppDelegate` | Setup status bar controller |

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Menu positioning | Use `popUpMenu(positioning:at:in:)` for proper placement |
| State sync issues | Use Combine publisher subscription |
| Memory leaks | Weak references in closures, proper cleanup |

## Unresolved Questions

1. Should right-click always show menu even during recording?
2. Should icon animate/pulse during recording?
3. Keep keyboard shortcuts working when using NSMenu?
