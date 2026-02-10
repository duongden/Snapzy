# Phase 1: File Write Guarantee

## Context

- **Parent plan:** [plan.md](./plan.md)
- **Dependencies:** None (first phase)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-02-10 |
| Description | Ensure screenshot file is fully written to disk before publishing completion event |
| Priority | Critical |
| Implementation Status | pending |
| Review Status | pending |

## Key Insights

1. `CGImageDestinationFinalize()` returns `true` when the write is **initiated**, not necessarily when data is fully flushed to disk. On fast successive captures, the file may not be readable yet when downstream consumers try to open it.
2. `generateFileName()` uses second-precision timestamps (`yyyy-MM-dd_HH-mm-ss`), causing filename collisions when captures happen within the same second. The second capture overwrites the first file mid-write.
3. `saveImage()` runs synchronously on `@MainActor`, blocking UI during file I/O and widening the race window on successive captures.

## Requirements

- File must be verifiably present on disk (exists + size > 0) before `captureCompletedSubject.send()` fires
- Filename collisions eliminated for rapid captures (<1s apart)
- File I/O must not block the main thread
- Maintain backward compatibility with existing `CaptureResult` and publisher API

## Architecture

Fits existing patterns:
- `ScreenCaptureManager` remains `@MainActor` singleton
- `captureCompletedSubject` remains `PassthroughSubject<URL, Never>`
- File verification runs in a `Task.detached` block; result dispatched back to `@MainActor` for publisher send
- Uses `os.Logger` consistent with existing `ThumbnailGenerator` pattern

## Related Code Files

| File | Lines | What Changes |
|------|-------|-------------|
| `Snapzy/Core/ScreenCaptureManager.swift` | L310-349 (`saveImage()`) | Add file verification loop after finalize |
| `Snapzy/Core/ScreenCaptureManager.swift` | L352-356 (`generateFileName()`) | Add millisecond precision |
| `Snapzy/Core/ScreenCaptureManager.swift` | L343-344 | Gate `captureCompletedSubject.send()` behind verification |

## Implementation Steps

### Step 1: Add `os.Logger` to ScreenCaptureManager

At top of file (after imports, before `CaptureResult` enum), add:

```swift
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "ScreenCaptureManager")
```

### Step 2: Add millisecond precision to `generateFileName()`

Change L354 from:
```swift
formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
```
To:
```swift
formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
```

This prevents filename collisions for captures within the same second.

### Step 3: Extract file verification helper

Add a private method to `ScreenCaptureManager`:

```swift
/// Verify file exists on disk with non-zero size, retrying up to maxAttempts
private func verifyFileWritten(at url: URL, maxAttempts: Int = 3, delayMs: UInt64 = 50) async -> Bool {
  for attempt in 1...maxAttempts {
    if FileManager.default.fileExists(atPath: url.path) {
      let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
      let size = attrs?[.size] as? UInt64 ?? 0
      if size > 0 {
        logger.debug("File verified on attempt \(attempt): \(url.lastPathComponent) (\(size) bytes)")
        return true
      }
    }
    if attempt < maxAttempts {
      try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
    }
  }
  logger.error("File verification failed after \(maxAttempts) attempts: \(url.lastPathComponent)")
  return false
}
```

### Step 4: Refactor `saveImage()` to async with verification

Change `saveImage()` signature from synchronous to async and add verification:

```swift
private func saveImage(
  _ image: CGImage,
  to directory: URL,
  fileName: String?,
  format: ImageFormat
) async -> CaptureResult {

  // Create directory if needed
  do {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  } catch {
    return .failure(.saveFailed("Could not create directory: \(error.localizedDescription)"))
  }

  // Generate filename
  let name = fileName ?? generateFileName()
  let fileURL = directory.appendingPathComponent("\(name).\(format.fileExtension)")

  // Create image destination
  guard let destination = CGImageDestinationCreateWithURL(
    fileURL as CFURL,
    format.utType,
    1,
    nil
  ) else {
    return .failure(.saveFailed("Could not create image destination"))
  }

  // Add image and write
  CGImageDestinationAddImage(destination, image, nil)

  guard CGImageDestinationFinalize(destination) else {
    logger.error("CGImageDestinationFinalize failed for \(fileURL.lastPathComponent)")
    return .failure(.saveFailed("Failed to write image to disk"))
  }

  // Verify file is fully written before notifying downstream
  let verified = await verifyFileWritten(at: fileURL)
  if verified {
    captureCompletedSubject.send(fileURL)
    return .success(fileURL)
  } else {
    return .failure(.saveFailed("File write verification failed for \(fileURL.lastPathComponent)"))
  }
}
```

### Step 5: Update callers of `saveImage()`

At L156 (`captureFullscreen`), change:
```swift
return saveImage(image, to: saveDirectory, fileName: fileName, format: format)
```
To:
```swift
return await saveImage(image, to: saveDirectory, fileName: fileName, format: format)
```

At L300 (`captureArea`), same change:
```swift
return await saveImage(image, to: saveDirectory, fileName: fileName, format: format)
```

Both callers are already `async` functions, so adding `await` is safe.

## Todo List

- [ ] Add `import os.log` and logger to `ScreenCaptureManager.swift`
- [ ] Change date format to include milliseconds (`-SSS`)
- [ ] Add `verifyFileWritten()` helper method
- [ ] Refactor `saveImage()` to async with verification gate
- [ ] Update `captureFullscreen()` call site with `await`
- [ ] Update `captureArea()` call site with `await`
- [ ] Compile and verify no build errors

## Success Criteria

1. `captureCompletedSubject.send()` only fires after file is verified on disk (exists + size > 0)
2. Rapid captures (<100ms apart) produce distinct filenames
3. No compilation errors or warnings
4. Existing capture flows (fullscreen, area) continue to work identically
5. Logger outputs appear in Console.app under `Snapzy` > `ScreenCaptureManager`

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Verification loop adds latency (up to 150ms worst case) | Low | Low | 50ms delay is imperceptible; most files verify on first attempt |
| `saveImage()` signature change breaks other callers | Low | Medium | Search codebase for all call sites; only `captureFullscreen` and `captureArea` call it |
| Millisecond timestamp still collides | Very Low | Low | Would require sub-millisecond captures; Phase 3 adds in-memory path as further mitigation |

## Security Considerations

- No new external inputs or network calls
- File operations use existing `FileManager` APIs with existing directory permissions
- No user-controlled data in file paths (timestamp-generated names only)

## Next Steps

After this phase, proceed to [Phase 2: Thumbnail Resilience](./phase-02-thumbnail-resilience.md) for defense-in-depth on the consumer side.
