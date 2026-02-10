# Phase 2: Thumbnail Resilience

## Context

- **Parent plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 1 (eliminates root cause; this phase adds defense-in-depth)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-02-10 |
| Description | Make thumbnail generation and QuickAccess item creation resilient to temporary file unavailability |
| Priority | High |
| Implementation Status | pending |
| Review Status | pending |

## Key Insights

1. `ThumbnailGenerator.generateFromImage()` (L52) calls `NSImage(contentsOf: url)` with no file existence check. Returns `nil` silently on failure.
2. `QuickAccessManager.addScreenshot()` (L116) uses `guard let thumbnail = result.thumbnail else { return }` -- silently drops the entire screenshot item when thumbnail fails. No logging, no retry, no placeholder.
3. Even with Phase 1's write verification, edge cases (disk pressure, APFS copy-on-write delays) could still cause brief read failures. Defense-in-depth is warranted.

## Requirements

- `ThumbnailGenerator` retries file read with backoff before giving up
- `ThumbnailGenerator` logs failures via `os.Logger` (already imported)
- `QuickAccessManager` never silently drops a screenshot item
- If thumbnail fails after retries, item appears with a placeholder and thumbnail retries in background

## Architecture

- `ThumbnailGenerator` already uses `os.Logger` -- extend usage to image path
- `QuickAccessManager` remains `@MainActor` singleton
- Placeholder thumbnail: simple gray `NSImage` generated in-memory (no asset dependency)
- Background retry uses existing `Task` pattern consistent with `dismissTimers`

## Related Code Files

| File | Lines | What Changes |
|------|-------|-------------|
| `Snapzy/Features/QuickAccess/ThumbnailGenerator.swift` | L51-52 (`generateFromImage`) | Add file existence check + retry loop with backoff |
| `Snapzy/Features/QuickAccess/QuickAccessManager.swift` | L113-139 (`addScreenshot`) | Replace silent `return` with placeholder + background retry |
| `Snapzy/Features/QuickAccess/QuickAccessManager.swift` | L142-167 (`addVideo`) | Same pattern for video path |

## Implementation Steps

### Step 1: Add retry logic to `ThumbnailGenerator.generateFromImage()`

Replace L51-52 in `ThumbnailGenerator.swift`:

```swift
private static func generateFromImage(url: URL, maxSize: CGFloat) async -> NSImage? {
  // Retry with backoff: 0ms, 100ms, 300ms
  let delays: [UInt64] = [0, 100, 300]

  for (attempt, delayMs) in delays.enumerated() {
    if delayMs > 0 {
      try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
    }

    guard FileManager.default.fileExists(atPath: url.path) else {
      logger.warning("File not found on attempt \(attempt + 1): \(url.lastPathComponent)")
      continue
    }

    if let image = NSImage(contentsOf: url) {
      let originalSize = image.size
      guard originalSize.width > 0, originalSize.height > 0 else { return nil }

      let scale: CGFloat
      if originalSize.width > originalSize.height {
        scale = min(maxSize / originalSize.width, 1.0)
      } else {
        scale = min(maxSize / originalSize.height, 1.0)
      }

      if scale >= 1.0 { return image }

      let newSize = CGSize(
        width: originalSize.width * scale,
        height: originalSize.height * scale
      )

      let thumbnail = NSImage(size: newSize)
      thumbnail.lockFocus()
      NSGraphicsContext.current?.imageInterpolation = .high
      image.draw(
        in: NSRect(origin: .zero, size: newSize),
        from: NSRect(origin: .zero, size: originalSize),
        operation: .copy,
        fraction: 1.0
      )
      thumbnail.unlockFocus()
      return thumbnail
    }

    logger.warning("NSImage load failed on attempt \(attempt + 1): \(url.lastPathComponent)")
  }

  logger.error("Thumbnail generation failed after \(delays.count) attempts: \(url.lastPathComponent)")
  return nil
}
```

### Step 2: Add placeholder thumbnail generator to `ThumbnailGenerator`

Add a static method:

```swift
/// Generate a simple placeholder thumbnail for failed loads
static func placeholderThumbnail(size: CGFloat = 200) -> NSImage {
  let thumbSize = NSSize(width: size, height: size)
  let image = NSImage(size: thumbSize)
  image.lockFocus()
  NSColor.systemGray.withAlphaComponent(0.3).setFill()
  NSBezierPath(roundedRect: NSRect(origin: .zero, size: thumbSize), xRadius: 8, yRadius: 8).fill()

  // Draw a camera icon hint
  let iconRect = NSRect(x: size * 0.3, y: size * 0.3, width: size * 0.4, height: size * 0.4)
  NSColor.systemGray.withAlphaComponent(0.5).setFill()
  NSBezierPath(ovalIn: iconRect).fill()
  image.unlockFocus()
  return image
}
```

### Step 3: Refactor `QuickAccessManager.addScreenshot()` to handle thumbnail failure

Replace L113-139:

```swift
func addScreenshot(url: URL) async {
  guard isEnabled else { return }
  let result = await ThumbnailGenerator.generate(from: url)

  // Use placeholder if thumbnail generation failed
  let thumbnail: NSImage
  let needsRetry: Bool
  if let generated = result.thumbnail {
    thumbnail = generated
    needsRetry = false
  } else {
    logger.warning("Thumbnail failed for \(url.lastPathComponent), using placeholder")
    thumbnail = ThumbnailGenerator.placeholderThumbnail()
    needsRetry = true
  }

  let item = QuickAccessItem(url: url, thumbnail: thumbnail)

  let wasEmpty = items.isEmpty
  withAnimation(QuickAccessAnimations.cardInsert) {
    if items.count >= maxVisibleItems, let oldestId = items.last?.id {
      cancelDismissTimer(for: oldestId)
      items.removeLast()
    }
    items.insert(item, at: 0)
  }

  if wasEmpty {
    showPanel()
  }

  if autoDismissEnabled {
    startDismissTimer(for: item.id)
  }

  // Schedule background thumbnail retry if needed
  if needsRetry {
    scheduleThumbnailRetry(for: item.id, url: url)
  }
}
```

### Step 4: Add logger and thumbnail retry method to `QuickAccessManager`

Add at top of file:
```swift
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "QuickAccessManager")
```

Add private method:
```swift
/// Retry thumbnail generation in background and update item if successful
private func scheduleThumbnailRetry(for id: UUID, url: URL) {
  Task {
    // Wait 500ms then retry
    try? await Task.sleep(nanoseconds: 500_000_000)
    guard items.contains(where: { $0.id == id }) else { return } // Item may have been dismissed

    let result = await ThumbnailGenerator.generate(from: url)
    guard let newThumbnail = result.thumbnail else {
      logger.error("Thumbnail retry also failed for \(url.lastPathComponent)")
      return
    }

    if let index = items.firstIndex(where: { $0.id == id }) {
      items[index] = QuickAccessItem(
        id: items[index].id,
        url: items[index].url,
        thumbnail: newThumbnail,
        duration: items[index].duration
      )
      logger.info("Thumbnail retry succeeded for \(url.lastPathComponent)")
    }
  }
}
```

### Step 5: Apply same pattern to `addVideo()`

Same changes as Step 3 but for L142-167, using `result.duration` for the video item.

### Step 6: Verify `QuickAccessItem` supports `id` in initializer

Check that `QuickAccessItem` has an `init` that accepts an explicit `id` parameter for the retry update. If not, the `id` property must be settable or a new `init(id:url:thumbnail:duration:)` added.

## Todo List

- [ ] Add retry loop with backoff to `ThumbnailGenerator.generateFromImage()`
- [ ] Add `placeholderThumbnail()` static method to `ThumbnailGenerator`
- [ ] Add `import os.log` and logger to `QuickAccessManager.swift`
- [ ] Refactor `addScreenshot()` to use placeholder on failure + schedule retry
- [ ] Apply same pattern to `addVideo()`
- [ ] Add `scheduleThumbnailRetry()` private method
- [ ] Verify `QuickAccessItem` supports explicit `id` in init (update if needed)
- [ ] Compile and verify no build errors

## Success Criteria

1. Thumbnail failures logged via `os.Logger` with attempt count and filename
2. Screenshot items always appear in QuickAccess overlay, even with placeholder thumbnail
3. Placeholder thumbnails get replaced by real thumbnails when background retry succeeds
4. No silent `return` on thumbnail failure -- every path either succeeds or logs
5. Video thumbnails follow same resilience pattern

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Retry delays add up to 400ms worst case in `ThumbnailGenerator` | Low | Low | Runs async, doesn't block UI; placeholder shows immediately |
| Placeholder thumbnail looks poor | Medium | Low | Simple gray circle is recognizable; replaced by real thumbnail within 500ms in retry |
| `QuickAccessItem` may not have `id` parameter in init | Medium | Medium | Step 6 checks this; simple struct modification if needed |
| Background retry fires after item dismissed | Low | None | Guard check `items.contains(where:)` prevents stale updates |

## Security Considerations

- No new external inputs or network calls
- Placeholder image generated entirely in-memory with standard AppKit APIs
- No user-controlled data influences retry behavior

## Next Steps

After this phase, proceed to [Phase 3: Defensive Improvements](./phase-03-defensive-improvements.md) for pipeline-wide observability and optional in-memory image passing optimization.
