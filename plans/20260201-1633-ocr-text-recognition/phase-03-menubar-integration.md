# Phase 03: MenuBar Integration

**Parent:** [plan.md](./plan.md)
**Dependencies:** [Phase 01: OCR Service](./phase-01-ocr-service.md)
**Date:** 2026-02-01
**Priority:** Medium
**Status:** Pending

## Overview

Add "Capture Text (OCR)" menu item to StatusBar dropdown. Follows existing NSMenuItem pattern with SF Symbol icon.

## Key Insights

- `StatusBarController.buildMenu()` constructs menu dynamically
- Each item has: title, action, keyEquivalent, target, image
- Actions are `@objc` methods calling into `viewModel`
- Items grouped with separators

## Requirements

1. Add "Capture Text (OCR)" menu item
2. Use SF Symbol icon (`text.viewfinder`)
3. Show shortcut equivalent (Cmd+Shift+2)
4. Disable when no permission
5. Trigger OCR capture flow on click

## Architecture

```
StatusBarController.buildMenu()
├── Capture Area (Cmd+Shift+4)
├── Capture Fullscreen (Cmd+Shift+3)
├── Capture Text (OCR) (Cmd+Shift+2)  <-- New
├── ---
├── Record Screen
└── ...
```

## Related Files

- `/Snapzy/App/StatusBarController.swift` - Main file to modify

## Implementation Steps

### Step 1: Add Menu Item in buildMenu()

**File:** `/Snapzy/App/StatusBarController.swift`

Insert after fullscreen item, before separator (around line 216):

```swift
// Add after captureFullscreenItem block

let captureOCRItem = NSMenuItem(
  title: "Capture Text (OCR)",
  action: #selector(captureOCRAction),
  keyEquivalent: "2"
)
captureOCRItem.keyEquivalentModifierMask = [.command, .shift]
captureOCRItem.target = self
captureOCRItem.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)
captureOCRItem.isEnabled = viewModel.hasPermission
menu?.addItem(captureOCRItem)
```

### Step 2: Add Action Method

Add to Menu Actions section (after line 318):

```swift
@objc private func captureOCRAction() {
  viewModel?.captureOCR()
}
```

### Step 3: Add captureOCR() to ScreenCaptureViewModel

**File:** `/Snapzy/Features/ScreenCapture/ViewModels/ScreenCaptureViewModel.swift`

```swift
/// Trigger OCR text capture flow
func captureOCR() {
  // Hide any visible UI first
  NSApp.hide(nil)

  // Small delay to let UI hide
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    Task { @MainActor in
      // Use area selection, then process with OCR
      await AreaSelectionController.shared.startSelection(mode: .ocr)
    }
  }
}
```

### Step 4: Add OCR Mode to AreaSelectionController

Add `.ocr` case to selection mode enum and handle completion:

```swift
enum SelectionMode {
  case screenshot
  case recording
  case ocr  // <-- Add this
}

// In completion handler, check mode and route to OCR processing
if mode == .ocr {
  await processOCRCapture(region: selectedRegion)
}
```

### Step 5: Implement OCR Capture Processing

```swift
private func processOCRCapture(region: CGRect) async {
  do {
    // Capture the screen region
    guard let image = try await captureRegion(region) else { return }

    // Perform OCR
    let text = try await OCRService.shared.recognizeText(from: image)

    // Copy to clipboard
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    // Success feedback
    QuickAccessSound.complete.play()

  } catch {
    // Error feedback
    QuickAccessSound.failed.play()
    print("OCR failed: \(error.localizedDescription)")
  }
}
```

## Todo List

- [ ] Add OCR menu item in `buildMenu()`
- [ ] Add `captureOCRAction()` method
- [ ] Add `captureOCR()` to ScreenCaptureViewModel
- [ ] Add `.ocr` mode to AreaSelectionController
- [ ] Implement OCR capture processing
- [ ] Test menu item enable/disable state

## Success Criteria

1. Menu shows "Capture Text (OCR)" with icon
2. Shortcut Cmd+Shift+2 displayed
3. Item disabled when no permission
4. Clicking triggers OCR capture flow

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Menu gets too crowded | Low | Low | Grouped logically with captures |
| Icon not clear enough | Low | Low | "text.viewfinder" is descriptive |

## Security Considerations

- Uses existing screen recording permission
- No new permissions required

## Next Steps

After completion, proceed to [Phase 04: Sound & Clipboard](./phase-04-sound-clipboard.md)
