# Plan: Fix Fast Screenshot Missing File Creation

## Problem Statement

Rapid screenshots silently fail to appear in QuickAccess overlay. `CGImageDestinationFinalize()` returns before the file is fully flushed to disk, causing `ThumbnailGenerator` to fail reading the file. Failures are silently swallowed with no logging.

## Root Cause

Race condition: `captureCompletedSubject.send(fileURL)` fires immediately after `CGImageDestinationFinalize()` returns `true` (L343-344 in `ScreenCaptureManager.swift`). Downstream `NSImage(contentsOf: url)` in `ThumbnailGenerator` (L52) reads an incomplete/missing file, returns `nil`, and `QuickAccessManager.addScreenshot()` silently drops the item at L116.

Secondary: `generateFileName()` uses second-precision timestamps (L354), causing filename collisions on rapid captures.

## Implementation Phases

| # | Phase | File | Status | Progress |
|---|-------|------|--------|----------|
| 1 | [File Write Guarantee](./phase-01-file-write-guarantee.md) | `ScreenCaptureManager.swift` | pending | 0% |
| 2 | [Thumbnail Resilience](./phase-02-thumbnail-resilience.md) | `ThumbnailGenerator.swift`, `QuickAccessManager.swift` | pending | 0% |
| 3 | [Defensive Improvements](./phase-03-defensive-improvements.md) | `PostCaptureActionHandler.swift`, pipeline-wide | pending | 0% |

## Architecture Notes

- Maintain `@MainActor` on all managers/coordinators
- Maintain `static let shared` singleton pattern
- Keep Combine `PassthroughSubject` publisher pattern for `captureCompletedSubject`
- Use `os.Logger` (already imported in `ThumbnailGenerator`) for observability
- Move file I/O off main thread using `Task.detached` where appropriate
- Do NOT create new files; update existing files directly per dev rules

## Execution Order

Phase 1 first (eliminates root cause). Phase 2 adds defense-in-depth. Phase 3 adds observability and the optional in-memory optimization. Each phase is independently shippable.
