# Research Report: Fast Screenshot File Creation Issue

## Executive Summary
Analyzed screenshot capture flow in Snapzy. Found potential race condition in async publish-subscribe pattern between file save and post-capture handlers. No explicit "fast screenshot" mode exists - all captures use same code path.

## Capture Flow Architecture

### Trigger Chain
1. **KeyboardShortcutManager** (Carbon event handler)
   - Hotkey press → Task{@MainActor} → delegate.shortcutTriggered()
   - Async dispatch to main actor

2. **ScreenCaptureViewModel** (delegate receiver)
   - captureFullscreen() creates Task with 50ms delay
   - captureArea() uses DispatchQueue.main.asyncAfter(0.05s) + 100ms capture delay
   - Both call ScreenCaptureManager async methods

3. **ScreenCaptureManager** (capture execution)
   - captureFullscreen/captureArea → SCScreenshotManager.captureImage (async)
   - Immediately calls saveImage() (synchronous)
   - Returns CaptureResult enum

### File Save Implementation

**Location:** ScreenCaptureManager.swift:310-349

```swift
private func saveImage(...) -> CaptureResult {
  // 1. Create directory (synchronous)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

  // 2. Generate filename (synchronous)
  let name = fileName ?? generateFileName()
  let fileURL = directory.appendingPathComponent("\(name).\(format.fileExtension)")

  // 3. Create CGImageDestination (synchronous)
  guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, format.utType, 1, nil)

  // 4. Write to disk (synchronous)
  CGImageDestinationAddImage(destination, image, nil)

  // 5. Finalize write
  if CGImageDestinationFinalize(destination) {
    captureCompletedSubject.send(fileURL)  // ⚠️ ASYNC PUBLISH
    return .success(fileURL)
  } else {
    return .failure(.saveFailed("Failed to write image to disk"))
  }
}
```

## Critical Issues Identified

### 1. Race Condition in Publish-Subscribe Pattern
**File:** ScreenCaptureManager.swift:343-344

- `CGImageDestinationFinalize()` returns immediately after queuing I/O
- `captureCompletedSubject.send(fileURL)` fires BEFORE disk write completes
- PostCaptureActionHandler receives URL while file may still be writing

**Evidence:**
```swift
// ScreenCaptureViewModel.swift:75-82
captureManager.captureCompletedPublisher
  .receive(on: DispatchQueue.main)
  .sink { [weak self] url in
    Task {
      await self.postCaptureHandler.handleScreenshotCapture(url: url)
    }
  }
```

PostCaptureActionHandler.handleScreenshotCapture() attempts to:
- Read image for clipboard: `NSImage(contentsOf: url)` (line 66)
- Add to QuickAccess: file may not exist yet

### 2. No Error Handling for File Write Completion
**Issue:** `CGImageDestinationFinalize()` returns bool, but doesn't guarantee write completion. File system I/O is buffered - actual write happens async in kernel.

**Gap:** No fsync(), no explicit flush, no verification file exists after write.

### 3. Synchronous I/O on Main Actor
**File:** ScreenCaptureManager.swift:310 (marked @MainActor via class)

All file I/O blocks main thread:
- FileManager.createDirectory
- CGImageDestinationCreateWithURL
- CGImageDestinationFinalize

Fast successive captures could queue operations, increasing race window.

### 4. Filename Collision Risk
**File:** ScreenCaptureManager.swift:352-356

```swift
private func generateFileName() -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
  return "Snapzy_\(formatter.string(from: Date()))"
}
```

Second-precision timestamp - rapid captures (< 1s apart) overwrite same file.
No atomic write, no temp file pattern.

## Flow Comparison: Fast vs Normal

**Finding:** NO SEPARATE "FAST" MODE EXISTS

All screenshots use identical code path:
- Fullscreen: 50ms UI delay → capture → save
- Area: 50ms hide + 100ms overlay delay → capture → save
- OCR: same as area

"Fast screenshot" likely refers to keyboard shortcut captures vs manual UI clicks.

## Potential Failure Scenarios

### Scenario A: Race Condition
1. User presses Cmd+Shift+3 twice rapidly (< 1s apart)
2. First capture: CGImageDestinationFinalize() returns, sends publish event
3. Second capture: starts before first write completes
4. PostCaptureHandler tries to read first file → may not exist yet
5. Filename collision: both use same timestamp → second overwrites first

### Scenario B: Buffered I/O Delay
1. Capture completes, saveImage() returns .success
2. Publisher fires immediately
3. QuickAccessManager attempts to load image
4. File exists in directory but data not flushed from kernel buffers
5. NSImage(contentsOf:) returns nil or corrupted data

### Scenario C: Directory Creation Race
1. Multiple captures triggered simultaneously
2. Both call createDirectory() concurrently
3. First succeeds, second may fail if directory creation in progress
4. File write fails silently (no error propagation)

## Error Handling Gaps

1. **No validation** after CGImageDestinationFinalize()
2. **No retry logic** for I/O failures
3. **Silent failures** in PostCaptureActionHandler (NSImage load fails, no alert)
4. **No file existence check** before publish event
5. **No logging** for save failures

## Recommendations

1. Add explicit fsync() or verify file exists before publishing
2. Use async file I/O (FileHandle, DispatchIO)
3. Implement microsecond-precision filenames or UUID
4. Add atomic write pattern (temp file + rename)
5. Verify file size > 0 before success return
6. Add error logging/telemetry for save failures
7. Debounce rapid captures or queue them serially

## Unresolved Questions

1. Does CGImageDestinationFinalize() guarantee file creation or just buffer write?
2. Is there telemetry showing which step fails (capture vs save vs post-process)?
3. What's the actual failure rate - every fast capture or intermittent?
4. Are missing files due to overwrites or failed writes?
