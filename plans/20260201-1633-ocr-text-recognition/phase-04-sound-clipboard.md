# Phase 04: Sound & Clipboard Integration

**Parent:** [plan.md](./plan.md)
**Dependencies:** [Phase 01](./phase-01-ocr-service.md), [Phase 03](./phase-03-menubar-integration.md)
**Date:** 2026-02-01
**Priority:** Medium
**Status:** Pending

## Overview

Integrate audio feedback using existing `QuickAccessSound` pattern and ensure clipboard operations follow `PostCaptureActionHandler` conventions.

## Key Insights

- `QuickAccessSound` uses pre-cached `NSSound` instances for instant playback
- `.complete` case uses "Glass" sound - appropriate for OCR success
- `.failed` case uses "Basso" sound - appropriate for OCR errors
- Clipboard: `pasteboard.clearContents()` then `pasteboard.setString()`

## Requirements

1. Play success sound when OCR completes
2. Play error sound when OCR fails (no text found)
3. Copy recognized text to system clipboard
4. Non-blocking async sound playback

## Architecture

```
OCR Flow
├── Capture Region
├── OCRService.recognizeText()
├── On Success:
│   ├── NSPasteboard.setString(text)
│   └── QuickAccessSound.complete.play()
└── On Failure:
    └── QuickAccessSound.failed.play()
```

## Related Files

- `/Snapzy/Features/QuickAccess/QuickAccessSound.swift` - Sound pattern
- `/Snapzy/Core/Services/PostCaptureActionHandler.swift` - Clipboard pattern

## Implementation Steps

### Step 1: Add OCR-Specific Sound Case (Optional)

If you want a distinct OCR sound, add to `QuickAccessSound`:

```swift
// In QuickAccessSound enum
case ocrComplete
case ocrFailed

// In soundName computed property
case .ocrComplete:
  return "Glass"
case .ocrFailed:
  return "Basso"

// In volume computed property
case .ocrComplete:
  return 0.4
case .ocrFailed:
  return 0.4
```

**Alternative:** Reuse existing `.complete` and `.failed` cases (recommended for simplicity).

### Step 2: Implement Clipboard Copy for Text

Create helper method or use inline:

```swift
/// Copy text to system clipboard
private func copyTextToClipboard(_ text: String) {
  let pasteboard = NSPasteboard.general
  pasteboard.clearContents()
  pasteboard.setString(text, forType: .string)
}
```

### Step 3: Complete OCR Capture Handler

Full implementation combining capture, OCR, clipboard, and sound:

```swift
/// Process OCR capture for a selected region
@MainActor
func processOCRCapture(image: CGImage) async {
  do {
    // Perform OCR
    let recognizedText = try await OCRService.shared.recognizeText(from: image)

    // Copy to clipboard
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(recognizedText, forType: .string)

    // Success feedback
    QuickAccessSound.complete.play()

    // Optional: Show notification
    // showOCRSuccessNotification(characterCount: recognizedText.count)

  } catch OCRError.noTextFound {
    // No text found - play subtle feedback
    QuickAccessSound.failed.play()

  } catch {
    // Other errors
    QuickAccessSound.failed.play()
    print("OCR error: \(error.localizedDescription)")
  }
}
```

### Step 4: Optional User Notification

For better UX, show brief notification on success:

```swift
private func showOCRNotification(text: String) {
  let notification = NSUserNotification()
  notification.title = "Text Copied"
  notification.informativeText = text.prefix(50) + (text.count > 50 ? "..." : "")
  NSUserNotificationCenter.default.deliver(notification)
}
```

**Note:** NSUserNotification deprecated in macOS 11+. For modern approach, use `UNUserNotificationCenter` or a transient overlay.

### Step 5: Handle Empty Results Gracefully

```swift
// In OCR processing
if recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
  QuickAccessSound.failed.play()
  return
}
```

## Todo List

- [ ] Implement clipboard copy for recognized text
- [ ] Add success sound feedback (`.complete`)
- [ ] Add failure sound feedback (`.failed`)
- [ ] Handle empty/whitespace-only results
- [ ] Test sound plays correctly
- [ ] Test clipboard contains correct text
- [ ] Optional: Add success notification

## Success Criteria

1. Recognized text appears in clipboard after Cmd+V
2. "Glass" sound plays on successful OCR
3. "Basso" sound plays when no text found
4. Sound is non-blocking (doesn't delay UI)
5. Works with Universal Clipboard (iOS devices)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sound not playing | Low | Low | Using proven QuickAccessSound pattern |
| Clipboard conflict | Low | Low | clearContents() before write |
| Large text performance | Low | Low | Clipboard handles large strings well |

## Security Considerations

- Clipboard data accessible to other apps (standard macOS behavior)
- User explicitly triggers OCR (no surprise clipboard changes)
- Sensitive text warning could be added (future enhancement)

## Testing Checklist

1. [ ] OCR image with clear text -> clipboard has text, Glass sound
2. [ ] OCR image with no text -> Basso sound, clipboard unchanged
3. [ ] OCR image with mixed text/graphics -> extracts text portions
4. [ ] Large text (1000+ chars) -> completes without delay
5. [ ] Sound respects system volume settings

## Next Steps

After all phases complete:
1. Integration testing of full flow
2. Add OCR shortcut row to ShortcutsSettingsView
3. Update user documentation
4. Consider future enhancements:
   - Language selection preference
   - Show recognized text preview before copying
   - History of OCR captures
