# Phase 02: Shortcut Integration

**Parent:** [plan.md](./plan.md)
**Dependencies:** [Phase 01: OCR Service](./phase-01-ocr-service.md)
**Date:** 2026-02-01
**Priority:** High
**Status:** Pending

## Overview

Integrate OCR capture into `KeyboardShortcutManager` with default shortcut Cmd+Shift+2. Follows existing pattern for fullscreen/area/recording shortcuts.

## Key Insights

- Existing pattern uses Carbon HotKey APIs via `RegisterEventHotKey`
- Each shortcut needs: `ShortcutConfig`, property, `EventHotKeyRef`, `EventHotKeyID`
- `ShortcutAction` enum dispatches to delegate
- UserDefaults persistence via JSON encoding

## Requirements

1. Add `.defaultOCR` static config (Cmd+Shift+2)
2. Add `captureOCR` case to `ShortcutAction` enum
3. Add OCR shortcut properties and registration
4. Update `handleHotkey()` to dispatch OCR action
5. Add `setOCRShortcut()` method for customization

## Architecture

```
KeyboardShortcutManager
├── ocrShortcut: ShortcutConfig
├── ocrHotkeyRef: EventHotKeyRef?
├── ocrHotkeyID: EventHotKeyID
├── setOCRShortcut(_:)
└── handleHotkey() -> .captureOCR
```

## Related Files

- `/Snapzy/Core/KeyboardShortcutManager.swift` - Main file to modify
- `/Snapzy/Features/Settings/Views/ShortcutsSettingsView.swift` - UI for customization

## Implementation Steps

### Step 1: Add ShortcutConfig.defaultOCR

**File:** `/Snapzy/Core/KeyboardShortcutManager.swift`

```swift
// Add after existing defaults (around line 38)

/// Cmd + Shift + 2
static let defaultOCR = ShortcutConfig(
  keyCode: UInt32(kVK_ANSI_2),
  modifiers: UInt32(cmdKey | shiftKey)
)
```

### Step 2: Add ShortcutAction.captureOCR

```swift
// Update ShortcutAction enum (around line 150)

enum ShortcutAction {
  case captureFullscreen
  case captureArea
  case captureOCR        // <-- Add this
  case recordVideo
  case openAnnotate
  case openVideoEditor
}
```

### Step 3: Add OCR Properties to KeyboardShortcutManager

```swift
// Add properties (after line 175)

private(set) var ocrShortcut: ShortcutConfig

// Add hotkey ref (after line 182)
private var ocrHotkeyRef: EventHotKeyRef?

// Add hotkey ID (after line 189)
private let ocrHotkeyID = EventHotKeyID(signature: OSType(0x5A53_4636), id: 6)  // "ZSF6"

// Add UserDefaults key (after line 199)
private let ocrShortcutKey = "ocrShortcut"
```

### Step 4: Initialize in init()

```swift
// In init() (after line 206)
ocrShortcut = .defaultOCR

// In loadShortcuts() add:
if let ocrData = UserDefaults.standard.data(forKey: ocrShortcutKey),
   let config = try? decoder.decode(ShortcutConfig.self, from: ocrData) {
  ocrShortcut = config
}
```

### Step 5: Add setOCRShortcut Method

```swift
// Add after setRecordingShortcut (around line 260)

/// Update OCR shortcut
func setOCRShortcut(_ config: ShortcutConfig) {
  let wasEnabled = isEnabled
  if wasEnabled { disable() }
  ocrShortcut = config
  saveShortcuts()
  if wasEnabled { enable() }
}
```

### Step 6: Update saveShortcuts()

```swift
// Add to saveShortcuts() (after line 279)

if let ocrData = try? encoder.encode(ocrShortcut) {
  UserDefaults.standard.set(ocrData, forKey: ocrShortcutKey)
}
```

### Step 7: Update handleHotkey()

```swift
// Add case in handleHotkey() switch (after line 358)

case ocrHotkeyID.id:
  delegate?.shortcutTriggered(.captureOCR)
```

### Step 8: Update registerShortcuts()

```swift
// Add to registerShortcuts() (after line 421)

// Register OCR shortcut
let ocrID = ocrHotkeyID
RegisterEventHotKey(
  ocrShortcut.keyCode,
  ocrShortcut.modifiers,
  ocrID,
  GetApplicationEventTarget(),
  0,
  &ocrHotkeyRef
)
```

### Step 9: Update unregisterAllShortcuts()

```swift
// Add to unregisterAllShortcuts() (after line 444)

if let ref = ocrHotkeyRef {
  UnregisterEventHotKey(ref)
  ocrHotkeyRef = nil
}
```

### Step 10: Handle Delegate Action

Update the delegate implementation (likely in `AppDelegate` or `ScreenCaptureViewModel`) to handle `.captureOCR`:

```swift
func shortcutTriggered(_ action: ShortcutAction) {
  switch action {
  // ... existing cases ...
  case .captureOCR:
    captureOCR()
  }
}

func captureOCR() {
  // Trigger area selection, then OCR
  // Implementation connects to AreaSelectionController
}
```

## Todo List

- [ ] Add `ShortcutConfig.defaultOCR`
- [ ] Add `ShortcutAction.captureOCR`
- [ ] Add OCR shortcut properties
- [ ] Update `init()` and `loadShortcuts()`
- [ ] Add `setOCRShortcut()` method
- [ ] Update `saveShortcuts()`
- [ ] Update `handleHotkey()`
- [ ] Update `registerShortcuts()`
- [ ] Update `unregisterAllShortcuts()`
- [ ] Handle `.captureOCR` in delegate
- [ ] Add OCR shortcut to ShortcutsSettingsView

## Success Criteria

1. Cmd+Shift+2 triggers OCR capture flow
2. Shortcut customizable via `setOCRShortcut()`
3. Shortcut persists across app restarts
4. No conflicts with existing shortcuts

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Shortcut conflict with system | Low | Medium | Cmd+Shift+2 not commonly used |
| User has custom keybind on 2 | Low | Low | Shortcut is customizable |

## Security Considerations

- No additional permissions required beyond existing screen recording
- Shortcut config stored in UserDefaults (standard macOS security)

## Next Steps

After completion, proceed to [Phase 03: MenuBar Integration](./phase-03-menubar-integration.md)
