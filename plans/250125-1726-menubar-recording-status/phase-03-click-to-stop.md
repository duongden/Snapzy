# Phase 03: Click-to-Stop Implementation

## Context Links
- Main plan: [plan.md](./plan.md)
- Previous phase: [phase-02-dynamic-icon.md](./phase-02-dynamic-icon.md)
- Technical analysis: [reports/01-technical-analysis.md](./reports/01-technical-analysis.md)

## Overview
Implement conditional click behavior: stop recording on click during active recording, show menu otherwise. Integrate with existing RecordingCoordinator stop flow.

## Key Insights
- RecordingCoordinator.shared handles stop flow with cleanup
- stopRecording() is private - need public method or direct manager call
- NSEvent allows distinguishing left/right click
- Menu must be manually displayed via popUpMenu

## Requirements
1. Left-click during recording -> stop recording immediately
2. Left-click when idle -> show dropdown menu
3. Right-click always shows menu (optional enhancement)
4. Maintain all existing menu functionality

## Architecture

```
User Click
    |
    v
handleClick(_:)
    |
    +-- isRecording? --YES--> stopRecording()
    |                              |
    |                              v
    |                    RecordingCoordinator.shared
    |                              |
    |                              v
    |                    ScreenRecordingManager.stopRecording()
    |                              |
    |                              v
    |                    cleanup() + QuickAccess
    |
    +-- isRecording? --NO--> showMenu()
                                   |
                                   v
                             NSMenu.popUp()
```

## Related Files
- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Recording/RecordingCoordinator.swift`
- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/ScreenRecordingManager.swift`
- NEW: `/Users/duongductrong/Developer/ZapShot/ClaudeShot/App/StatusBarController.swift`

## Implementation Steps

### Step 1: Add public stop method to RecordingCoordinator
```swift
// RecordingCoordinator.swift - Add public wrapper
/// Stop recording from external caller (e.g., menu bar)
func stop() {
  stopRecording()
}
```

### Step 2: Implement click handler
```swift
// StatusBarController.swift
@objc private func handleClick(_ sender: NSStatusBarButton) {
  guard let event = NSApp.currentEvent else { return }

  // Right-click always shows menu
  if event.type == .rightMouseUp {
    showMenu()
    return
  }

  // Left-click: stop if recording, else show menu
  if recorder.isRecording || recorder.isPaused {
    Task { @MainActor in
      RecordingCoordinator.shared.stop()
    }
  } else {
    showMenu()
  }
}
```

### Step 3: Build and show menu
```swift
private lazy var menu: NSMenu = {
  let menu = NSMenu()
  buildMenuItems(menu)
  return menu
}()

private func showMenu() {
  guard let button = statusItem?.button else { return }

  // Rebuild menu to reflect current state
  menu.removeAllItems()
  buildMenuItems(menu)

  // Show menu below status item
  statusItem?.menu = menu
  button.performClick(nil)
  statusItem?.menu = nil  // Remove to allow click handling next time
}

private func buildMenuItems(_ menu: NSMenu) {
  // Capture Area
  let captureArea = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "4")
  captureArea.keyEquivalentModifierMask = [.command, .shift]
  captureArea.target = self
  menu.addItem(captureArea)

  // Capture Fullscreen
  let captureFullscreen = NSMenuItem(title: "Capture Fullscreen", action: #selector(captureFullscreen), keyEquivalent: "3")
  captureFullscreen.keyEquivalentModifierMask = [.command, .shift]
  captureFullscreen.target = self
  menu.addItem(captureFullscreen)

  menu.addItem(NSMenuItem.separator())

  // Record Screen
  let recordScreen = NSMenuItem(title: "Record Screen", action: #selector(recordScreen), keyEquivalent: "5")
  recordScreen.keyEquivalentModifierMask = [.command, .shift]
  recordScreen.target = self
  menu.addItem(recordScreen)

  menu.addItem(NSMenuItem.separator())

  // Open Annotate
  let annotate = NSMenuItem(title: "Open Annotate", action: #selector(openAnnotate), keyEquivalent: "a")
  annotate.keyEquivalentModifierMask = [.command, .shift]
  annotate.target = self
  menu.addItem(annotate)

  // Edit Video
  let editVideo = NSMenuItem(title: "Edit Video...", action: #selector(openVideoEditor), keyEquivalent: "e")
  editVideo.keyEquivalentModifierMask = [.command, .shift]
  editVideo.target = self
  menu.addItem(editVideo)

  menu.addItem(NSMenuItem.separator())

  // Preferences
  let prefs = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
  prefs.keyEquivalentModifierMask = .command
  prefs.target = self
  menu.addItem(prefs)

  menu.addItem(NSMenuItem.separator())

  // Quit
  let quit = NSMenuItem(title: "Quit ClaudeShot", action: #selector(quitApp), keyEquivalent: "q")
  quit.keyEquivalentModifierMask = .command
  quit.target = self
  menu.addItem(quit)
}
```

### Step 4: Menu action handlers
```swift
@objc private func captureArea() {
  ScreenCaptureViewModel.shared.captureArea()
}

@objc private func captureFullscreen() {
  ScreenCaptureViewModel.shared.captureFullscreen()
}

@objc private func recordScreen() {
  ScreenCaptureViewModel.shared.startRecordingFlow()
}

@objc private func openAnnotate() {
  AnnotateManager.shared.openEmptyAnnotation()
}

@objc private func openVideoEditor() {
  VideoEditorManager.shared.openEmptyEditor()
}

@objc private func openPreferences() {
  NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
}

@objc private func quitApp() {
  NSApp.terminate(nil)
}
```

### Step 5: Handle ScreenCaptureViewModel access
```swift
// May need to make ScreenCaptureViewModel accessible
// Option A: Make it a singleton
// Option B: Pass reference during setup
// Option C: Use NotificationCenter for actions
```

## Todo List
- [ ] Add public `stop()` method to RecordingCoordinator
- [ ] Implement handleClick with recording state check
- [ ] Build NSMenu with all menu items from MenuBarContentView
- [ ] Implement showMenu() with proper positioning
- [ ] Add all @objc action handlers
- [ ] Wire up ScreenCaptureViewModel (singleton or notification)
- [ ] Test click-to-stop during recording
- [ ] Test menu appears when not recording
- [ ] Verify keyboard shortcuts work
- [ ] Test right-click always shows menu

## Success Criteria
- Single left-click stops recording when active
- Recording stops, file saves, QuickAccess updates
- Sound plays on stop (Glass)
- Left-click shows menu when not recording
- All menu items functional
- Keyboard shortcuts work

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Menu positioning wrong | Medium | Low | Use performClick pattern |
| Actions not firing | Medium | Medium | Verify target/action setup |
| Keyboard shortcuts broken | Low | Medium | Test each shortcut |
| State race condition | Low | High | Check state before action |

## Security Considerations
- Menu items respect permission state (hasPermission check)
- No sensitive data exposed in menu

## Next Steps
- Integration testing with full recording flow
- Update MenuBarContentView permission checks to StatusBarController
- Consider adding Sparkle updater menu item
