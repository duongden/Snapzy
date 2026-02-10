# Phase 3: Defensive Improvements

## Context

- **Parent plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 1 and Phase 2 (this phase adds observability and optional optimization)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-02-10 |
| Description | Add pipeline-wide observability, file validation in PostCaptureActionHandler, and optional in-memory image passing to eliminate file reads entirely |
| Priority | Medium |
| Implementation Status | pending |
| Review Status | pending |

## Key Insights

1. `PostCaptureActionHandler.handleScreenshotCapture()` (L25) blindly passes the URL to `QuickAccessManager` and `copyToClipboard()` with no file existence check. If the file is missing, `copyToClipboard()` silently fails at L66 (`NSImage(contentsOf: url)` returns nil).
2. The entire pipeline reads the file from disk multiple times: once for thumbnail, once for clipboard copy. The `CGImage` is already in memory after capture but gets discarded.
3. Passing the `CGImage` through the publisher alongside the URL would eliminate all file-read race conditions entirely, making Phases 1 and 2 unnecessary for thumbnail generation (though still valuable for file integrity).

## Requirements

- `PostCaptureActionHandler` validates file exists before processing
- `PostCaptureActionHandler` logs each action execution for debugging
- Consider expanding `captureCompletedSubject` to carry `CGImage` alongside URL (optional optimization)
- All pipeline stages have `os.Logger` entries for traceability

## Architecture

Two approaches evaluated:

**Approach A (Recommended - Minimal change):** Add file validation + logging to `PostCaptureActionHandler`. Keep `PassthroughSubject<URL, Never>` unchanged.

**Approach B (Optional optimization):** Change publisher to `PassthroughSubject<CaptureCompletion, Never>` where `CaptureCompletion` carries both `URL` and `CGImage`. Downstream generates thumbnail from in-memory `CGImage` instead of reading file. More invasive but eliminates race condition class entirely.

Recommendation: Implement Approach A now. Approach B can be a follow-up if performance profiling shows file reads are a bottleneck.

## Related Code Files

| File | Lines | What Changes |
|------|-------|-------------|
| `Snapzy/Core/Services/PostCaptureActionHandler.swift` | L25-48 (`executeActions`) | Add file validation + logging |
| `Snapzy/Core/Services/PostCaptureActionHandler.swift` | L57-73 (`copyToClipboard`) | Add logging for clipboard copy failures |
| `Snapzy/Core/ScreenCaptureManager.swift` | L54-57 (publisher) | (Approach B only) Change publisher type |

## Implementation Steps

### Step 1: Add logger to `PostCaptureActionHandler`

At top of file:
```swift
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "PostCaptureActionHandler")
```

### Step 2: Add file validation to `executeActions()`

Replace L36-54:

```swift
private func executeActions(for captureType: CaptureType, url: URL) async {
  // Validate file exists before processing
  guard FileManager.default.fileExists(atPath: url.path) else {
    logger.error("Capture file missing at \(url.lastPathComponent), skipping post-capture actions")
    return
  }

  logger.info("Executing post-capture actions for \(captureType == .screenshot ? "screenshot" : "recording"): \(url.lastPathComponent)")

  // Show Quick Access Overlay
  if preferencesManager.isActionEnabled(.showQuickAccess, for: captureType) {
    switch captureType {
    case .screenshot:
      await quickAccessManager.addScreenshot(url: url)
    case .recording:
      await quickAccessManager.addVideo(url: url)
    }
    logger.debug("Quick access overlay shown for \(url.lastPathComponent)")
  }

  // Copy file to clipboard
  if preferencesManager.isActionEnabled(.copyFile, for: captureType) {
    copyToClipboard(url: url, isVideo: captureType == .recording)
    logger.debug("Clipboard copy executed for \(url.lastPathComponent)")
  }
}
```

### Step 3: Add failure logging to `copyToClipboard()`

Replace L57-73:

```swift
private func copyToClipboard(url: URL, isVideo: Bool) {
  let pasteboard = NSPasteboard.general
  pasteboard.clearContents()

  if isVideo {
    pasteboard.writeObjects([url as NSURL])
  } else {
    if let image = NSImage(contentsOf: url) {
      pasteboard.writeObjects([image])
    } else {
      logger.error("Failed to load image for clipboard: \(url.lastPathComponent)")
    }
  }

  NSSound(named: "Pop")?.play()
}
```

### Step 4: Add pipeline stage logging to `ScreenCaptureManager`

In `saveImage()` (already modified in Phase 1), add at entry:

```swift
logger.info("Saving capture to \(directory.lastPathComponent)/\(name).\(format.fileExtension)")
```

### Step 5 (Optional - Approach B): In-memory image passing

If Approach B is desired, define a completion struct:

```swift
struct CaptureCompletion {
  let url: URL
  let image: CGImage
}
```

Change publisher:
```swift
private let captureCompletedSubject = PassthroughSubject<CaptureCompletion, Never>()
var captureCompletedPublisher: AnyPublisher<CaptureCompletion, Never> {
  captureCompletedSubject.eraseToAnyPublisher()
}
```

Update `saveImage()` to send both:
```swift
captureCompletedSubject.send(CaptureCompletion(url: fileURL, image: image))
```

Update all subscribers to extract `.url` or use `.image` for thumbnail generation.

**Note:** This is a larger change that touches all publisher subscribers. Defer to a separate ticket unless performance data justifies it.

## Todo List

- [ ] Add `import os.log` and logger to `PostCaptureActionHandler.swift`
- [ ] Add file existence validation at start of `executeActions()`
- [ ] Add logging at each action execution point in `executeActions()`
- [ ] Add failure logging to `copyToClipboard()` for nil image case
- [ ] Add entry logging to `saveImage()` in `ScreenCaptureManager`
- [ ] (Optional) Evaluate and implement Approach B in-memory image passing
- [ ] Compile and verify no build errors
- [ ] Manual test: rapid captures, verify Console.app logs show full pipeline trace

## Success Criteria

1. `PostCaptureActionHandler` rejects missing files with error log instead of silent failure
2. Every pipeline stage (save -> post-capture -> quick access -> thumbnail) emits at least one log entry
3. `copyToClipboard()` logs error when `NSImage(contentsOf:)` fails instead of silently dropping
4. Console.app filter `Snapzy` shows complete capture-to-display trace
5. No new compilation errors or warnings

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| File existence check in `executeActions()` is redundant with Phase 1 verification | Expected | None | Defense-in-depth is intentional; negligible cost |
| Approach B publisher type change breaks subscribers | Medium | High | Deferred to separate ticket; Approach A sufficient |
| Excessive logging in production | Low | Low | Uses `os.Logger` levels (debug/info/error); debug suppressed in release by default |

## Security Considerations

- No new external inputs or network calls
- Logging uses `os.Logger` which respects system privacy levels; filenames (not full paths) logged
- No sensitive data (user content, credentials) included in log messages

## Next Steps

After all three phases are implemented:
1. Run full compile check
2. Manual test: capture 5+ screenshots in rapid succession (<500ms apart)
3. Verify all items appear in QuickAccess overlay
4. Check Console.app for complete pipeline traces
5. If Approach B is desired, create separate ticket for publisher type migration
