# Phase 3: SCShareableContent Cache

**Status:** Not Started
**Priority:** P1
**Estimated Impact:** -30ms to -6s (varies by system state)

## Context Links

- [Main Plan](./plan.md)
- [Phase 2: CALayer Crosshair](./phase-02-calayer-crosshair.md)
- [Phase 4: Rendering Optimization](./phase-04-rendering-optimization.md)

## Overview

Pre-fetch and cache `SCShareableContent` in background to eliminate blocking calls during capture. First call to `SCShareableContent.current` can take 30ms-6s depending on system state, number of windows, permission dialogs.

## Key Insights

1. **Current behavior** (ScreenCaptureManager line 71, 128, 188): Calls `SCShareableContent.current` synchronously
2. **First-call penalty**: System enumerates all windows/displays, can be very slow
3. **Permission check cost**: Permission verification adds latency
4. **Stale cache risk**: Display list can change, cache needs refresh triggers
5. **Main thread blocking**: Current async/await still blocks UI until complete

## Requirements

- Pre-fetch SCShareableContent on app launch
- Cache SCDisplay objects for quick access
- Refresh cache on screen configuration changes
- Never call SCShareableContent on main thread during capture
- Handle permission state changes gracefully

## Architecture

```
ShareableContentCache (new singleton)
├── cachedContent: SCShareableContent?
├── cachedDisplays: [CGDirectDisplayID: SCDisplay]
├── lastRefreshTime: Date
├── isRefreshing: Bool
├── refreshCache() - background fetch
├── getDisplay(for: CGDirectDisplayID) -> SCDisplay?
├── preWarm() - called on app launch
└── scheduleRefresh() - on screen changes
```

### Cache Lifecycle

```
[App Launch]
     │
     v
preWarm() ──> Background fetch ──> Cache populated
     │
     └──> App ready, cache warm

[User Triggers Capture]
     │
     v
getDisplay() ──> Return cached SCDisplay (instant)
     │
     └──> No SCShareableContent call!

[Screen Change Notification]
     │
     v
scheduleRefresh() ──> Background fetch ──> Cache updated
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Core/ScreenCaptureManager.swift` | Current SCShareableContent usage |
| `ClaudeShot/Core/ShareableContentCache.swift` | New file to create |
| `ClaudeShot/App/StatusBarController.swift` | App lifecycle hooks |

## Implementation Steps

### Step 1: Create ShareableContentCache.swift

```swift
//
//  ShareableContentCache.swift
//  ClaudeShot
//
//  Pre-fetches and caches SCShareableContent for instant access
//

import Foundation
import ScreenCaptureKit

/// Cache for SCShareableContent to avoid blocking calls during capture
@MainActor
final class ShareableContentCache {

    static let shared = ShareableContentCache()

    private var cachedContent: SCShareableContent?
    private var cachedDisplays: [CGDirectDisplayID: SCDisplay] = [:]
    private var lastRefreshTime: Date = .distantPast
    private var isRefreshing = false
    private var refreshTask: Task<Void, Never>?

    private init() {
        setupNotifications()
    }

    // MARK: - Public API

    /// Pre-warm the cache. Call on app launch.
    func preWarm() {
        guard cachedContent == nil else { return }
        refreshInBackground()
    }

    /// Get cached display by ID. Returns nil if not cached.
    func getDisplay(for displayID: CGDirectDisplayID) -> SCDisplay? {
        return cachedDisplays[displayID]
    }

    /// Get all cached displays
    var displays: [SCDisplay] {
        return Array(cachedDisplays.values)
    }

    /// Get cached content, or fetch if not available
    func getContent() async throws -> SCShareableContent {
        if let content = cachedContent {
            return content
        }
        return try await SCShareableContent.current
    }

    /// Force refresh the cache
    func forceRefresh() {
        refreshInBackground()
    }

    // MARK: - Private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func screenConfigurationDidChange() {
        // Debounce rapid changes
        refreshInBackground(delay: 0.5)
    }

    @objc private func appDidBecomeActive() {
        // Refresh if stale (older than 30 seconds)
        let staleDuration: TimeInterval = 30
        if Date().timeIntervalSince(lastRefreshTime) > staleDuration {
            refreshInBackground()
        }
    }

    private func refreshInBackground(delay: TimeInterval = 0) {
        refreshTask?.cancel()

        refreshTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }
            await self?.performRefresh()
        }
    }

    private func performRefresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let content = try await SCShareableContent.current

            // Update cache on main actor
            self.cachedContent = content
            self.cachedDisplays = Dictionary(
                uniqueKeysWithValues: content.displays.map {
                    (CGDirectDisplayID($0.displayID), $0)
                }
            )
            self.lastRefreshTime = Date()

        } catch {
            // Log but don't crash - permission may not be granted yet
            print("[ShareableContentCache] Refresh failed: \(error)")
        }
    }
}
```

### Step 2: Update ScreenCaptureManager - checkPermission

```swift
func checkPermission() async {
    do {
        // Use cached content if available, otherwise this will cache it
        _ = try await ShareableContentCache.shared.getContent()
        hasPermission = true
    } catch {
        hasPermission = false
    }
}
```

### Step 3: Update captureFullscreen()

```swift
func captureFullscreen(
    saveDirectory: URL,
    fileName: String? = nil,
    displayID: CGDirectDisplayID? = nil,
    format: ImageFormat = .png
) async -> CaptureResult {

    // ... permission check ...

    do {
        // Use cached content
        let content = try await ShareableContentCache.shared.getContent()

        // Get display from cache first
        let targetDisplayID = displayID ?? CGMainDisplayID()
        let display: SCDisplay

        if let cachedDisplay = ShareableContentCache.shared.getDisplay(for: targetDisplayID) {
            display = cachedDisplay
        } else if let foundDisplay = content.displays.first(where: { $0.displayID == Int(targetDisplayID) }) {
            display = foundDisplay
        } else if let firstDisplay = content.displays.first {
            display = firstDisplay
        } else {
            return .failure(.noDisplayFound)
        }

        // ... rest of capture logic ...
    }
}
```

### Step 4: Update captureArea()

```swift
func captureArea(
    rect: CGRect,
    saveDirectory: URL,
    fileName: String? = nil,
    format: ImageFormat = .png
) async -> CaptureResult {

    // ... permission check ...

    do {
        // Use cached content
        let content = try await ShareableContentCache.shared.getContent()

        // ... rest of capture logic, use content.displays ...
    }
}
```

### Step 5: Hook into App Launch

In `StatusBarController` or app delegate initialization:

```swift
// Early in app initialization
Task {
    ShareableContentCache.shared.preWarm()
}
```

### Step 6: Add Convenience Extension

```swift
extension NSScreen {
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
```

## Todo List

- [ ] Create `ShareableContentCache.swift` file
- [ ] Implement `preWarm()` method
- [ ] Implement `getDisplay(for:)` method
- [ ] Add screen change notification observer
- [ ] Add app foreground refresh logic
- [ ] Update `ScreenCaptureManager.checkPermission()`
- [ ] Update `ScreenCaptureManager.captureFullscreen()`
- [ ] Update `ScreenCaptureManager.captureArea()`
- [ ] Hook `preWarm()` to app launch
- [ ] Add `NSScreen.displayID` extension
- [ ] Test cold start performance
- [ ] Test cache refresh on screen change
- [ ] Measure capture latency improvement

## Success Criteria

- [ ] No SCShareableContent.current call during actual capture
- [ ] Cache populated within 1s of app launch
- [ ] Cache refreshes within 500ms of screen change
- [ ] Permission denied handled gracefully
- [ ] No main thread blocking from cache operations

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Stale display info | Medium | High | Refresh on screen change notification |
| Cache miss during capture | Low | Medium | Fallback to live fetch |
| Permission race condition | Low | Low | Re-check permission on capture |
| Memory overhead | Low | Low | SCShareableContent is lightweight |

## Security Considerations

- SCShareableContent contains window info - not persisted, cleared on app quit
- No sensitive data exposed through caching
- Permission state properly respected

## Next Steps

After completing Phase 3:
1. Measure cumulative improvement from Phases 1-3
2. If <150ms achieved, Phase 4 is optimization polish
3. Document final performance metrics
