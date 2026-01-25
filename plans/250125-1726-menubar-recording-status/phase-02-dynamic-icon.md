# Phase 02: Dynamic Icon Implementation

## Context Links
- Main plan: [plan.md](./plan.md)
- Previous phase: [phase-01-state-observation.md](./phase-01-state-observation.md)

## Overview
Replace SwiftUI MenuBarExtra with NSStatusItem for full click control. Implement dynamic icon switching based on recording state.

## Key Insights
- NSStatusItem provides direct button access
- SF Symbols work via `NSImage(systemSymbolName:)`
- Template images required for proper menu bar appearance

## Requirements
1. Status bar icon visible at all times
2. Icon: `camera.aperture` (idle) / `record.circle.fill` (recording)
3. Icon renders correctly in light/dark mode
4. Smooth transition between icons

## Architecture

```
StatusBarController
  |
  +-- statusItem: NSStatusItem
  |     |
  |     +-- button: NSStatusBarButton
  |           +-- image: NSImage (SF Symbol)
  |           +-- target/action: handleClick
  |
  +-- menu: NSMenu (lazy, shown when not recording)
```

## Related Files
- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/App/ClaudeShotApp.swift`
- NEW: `/Users/duongductrong/Developer/ZapShot/ClaudeShot/App/StatusBarController.swift`

## Implementation Steps

### Step 1: Remove MenuBarExtra from ClaudeShotApp
```swift
// ClaudeShotApp.swift - REMOVE lines 37-40
// MenuBarExtra("ClaudeShot", systemImage: "camera.aperture") {
//   MenuBarContentView(viewModel: viewModel, updater: updaterController.updater)
//     .preferredColorScheme(themeManager.systemAppearance)
// }
```

### Step 2: Setup NSStatusItem in StatusBarController
```swift
private func setupStatusItem() {
  statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

  guard let button = statusItem?.button else { return }

  // Initial icon
  let image = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "ClaudeShot")
  image?.isTemplate = true  // Adapts to menu bar appearance
  button.image = image

  // Click handling
  button.target = self
  button.action = #selector(handleClick(_:))
  button.sendAction(on: [.leftMouseUp, .rightMouseUp])
}
```

### Step 3: Dynamic icon update
```swift
private func updateStatusIcon(for state: RecordingState) {
  let iconName: String
  let tintColor: NSColor?

  switch state {
  case .recording:
    iconName = "record.circle.fill"
    tintColor = .systemRed
  case .paused:
    iconName = "record.circle.fill"
    tintColor = .systemOrange
  default:
    iconName = "camera.aperture"
    tintColor = nil
  }

  var image = NSImage(systemSymbolName: iconName, accessibilityDescription: "ClaudeShot")

  if let color = tintColor {
    // Create colored version for recording state
    image = image?.withSymbolConfiguration(.init(paletteColors: [color]))
  } else {
    image?.isTemplate = true
  }

  statusItem?.button?.image = image
}
```

### Step 4: Initialize in AppDelegate
```swift
// AppDelegate.swift
func applicationDidFinishLaunching(_ notification: Notification) {
  StatusBarController.shared.setup()
  // ... existing code
}
```

## Todo List
- [ ] Create StatusBarController.swift with NSStatusItem setup
- [ ] Remove MenuBarExtra from ClaudeShotApp.swift body
- [ ] Implement setupStatusItem() with initial icon
- [ ] Implement updateStatusIcon(for:) with state-based icons
- [ ] Add StatusBarController.shared.setup() call in AppDelegate
- [ ] Test icon appears in menu bar
- [ ] Test icon changes color during recording
- [ ] Verify template mode works in light/dark

## Success Criteria
- Menu bar shows camera.aperture icon on launch
- Icon changes to red record.circle.fill during recording
- Icon changes to orange during paused state
- Icon adapts to system appearance (light/dark menu bar)

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Icon not visible | Low | High | Verify NSStatusItem creation succeeds |
| Color not showing | Medium | Low | Test isTemplate = false for colored icons |
| Memory leak | Low | Medium | Weak self in closures |

## Security Considerations
None - UI rendering only.

## Next Steps
Proceed to Phase 03: Click-to-Stop Implementation
