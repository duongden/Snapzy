# ScreenCaptureKit Window Exclusion Research

## 1. SCContentFilter excludingWindows Parameter

### How It Works
- `SCContentFilter` provides fine-grained control over captured content
- Can specify display to capture, then explicitly exclude windows of specific applications
- Exception rules supported: windows normally included can be excluded, excluded windows can be specifically included
- Filter by bundle identifiers (apps) and window IDs (individual windows)

### Initialization Methods
```swift
// Display capture with excluded windows
init(display: SCDisplay,
     excludingApplications: [SCRunningApplication],
     exceptingWindows: [SCWindow])

// Display capture with included apps and excluded windows
init(display: SCDisplay,
     includingApplications: [SCRunningApplication],
     exceptingWindows: [SCWindow])

// Single window capture (desktop-independent)
init(desktopIndependentWindow: SCWindow)
```

### Common Pattern for Excluding Own App
```swift
let filter = SCContentFilter(
    display: selectedDisplay,
    excludingApplications: [myApp],
    exceptingWindows: []
)
```

### macOS 15.2+ Improvements
- New `includedDisplays` and `includedWindows` properties simplify filtering
- Older versions required manual filtering by size/position matching using `SCContentFilter.contentRect`

### Critical Limitation (macOS 15+)
- Traditional methods `NSWindow.sharingType = .none` or `setContentProtection(true)` NO LONGER WORK
- ScreenCaptureKit captures framebuffer regardless of these flags on macOS 15+
- Must use `exceptingWindows` parameter for exclusion

## 2. Querying SCShareableContent for SCWindow by windowNumber

### Best Practice Pattern
```swift
// Get shareable content
let content = try await SCShareableContent.current

// Find window by NSWindow.windowNumber
let nsWindowNumber = myNSWindow.windowNumber
let scWindow = content.windows.first {
    $0.windowID == CGWindowID(nsWindowNumber)
}
```

### Key Properties
- `SCWindow.windowID` = Core Graphics window identifier (matches NSWindow.windowNumber)
- `SCWindow.title` = window title bar string
- `SCWindow.owningApplication` = app that owns window
- `SCWindow.windowLayer`, `frame`, `isOnScreen`, `isActive`

### Important Notes
- First invocation requires Screen Recording permission
- Permission dialog triggers on initial `SCShareableContent` call
- Filter retrieved windows before creating `SCContentFilter`

### Workaround for Unfiltered Calls
- Bug exists where unfiltered calls may not process correctly
- Solution: use `includingApplications` and pass all applications
- Apple's sample code demonstrates this pattern

## 3. Async Handling of SCShareableContent Queries

### Recommended Async Pattern
```swift
Task {
    do {
        // Fetch off main thread
        let content = try await SCShareableContent.current

        // Process windows
        let targetWindow = content.windows.first { $0.windowID == targetID }

        // Update UI on MainActor
        await MainActor.run {
            self.availableWindows = content.windows
        }
    } catch {
        await MainActor.run {
            self.handleError(error)
        }
    }
}
```

### MainActor Best Practices
- **Fetch content OFF main actor** - prevents UI freezing
- **Update UI ON MainActor** - use `@MainActor` attribute or `Task { @MainActor in ... }`
- Avoid mixing `DispatchQueue.main.async` with Swift concurrency
- Use structured concurrency (`TaskGroup`) for multiple concurrent operations

### Alternative: Completion Handler Pattern
```swift
SCShareableContent.getShareableContent { content, error in
    guard let content = content else { return }
    DispatchQueue.main.async {
        // Update UI
    }
}
```

## 4. Edge Cases and Limitations

### Known Issues

#### Hanging Queries
- `SCShareableContent.current` may hang and never return
- More likely after multiple capture sessions or with SwiftUI Previews active
- Multiple app instances in Activity Monitor can cause hangs
- **Workarounds**:
  - Restart macOS
  - Log out/log in
  - `killall -9 replayd` (DO NOT kill WindowServer)

#### Session Reliability Issues
- **Failure to establish session**: `getWithCompletionHandler` may not invoke handler or takes 3-10s
- System logs show delays in `fetchShareableContentWithOption` (normal: 30-40ms, problematic: 6s)
- **Stream interruption**: streams stop receiving frames minutes/hours into recording
- More likely with low disk space (<8GB free) - `replayd` silently drops session
- Can occur even with ample free space

#### Desktop Capture Bug
- Cannot reliably capture entire desktop
- Setting `isAppExcluded = false` can stop stream or prevent start
- Workaround: set `isAppExcluded = true` (exclude capturing app)

#### Audio Capture
- Unreliable long-duration audio capture
- System may incorrectly indicate screen sharing when nothing shared
- Inability to stop sharing properly

#### Presenter Overlay
- Only appears when capturing entire screen
- NOT available for single window or region capture
- No documented way to enable for focused captures

#### macOS Sequoia Permissions
- New permission dialog: "requesting to bypass system private window picker and directly access screen/audio"
- Additional user consent required

### SCContentSharingPickerConfiguration
- Allows explicit declaration of excluded window IDs
- Prevents specific windows from being picked by system picker
- Bundle IDs can also be excluded

## 5. Performance Considerations

### Query Performance
- `SCShareableContent.current` can take 30-40ms (normal)
- Problematic scenarios: 3-10 seconds or hang indefinitely
- Run queries off main thread to avoid UI blocking

### Memory & Disk Space
- Low disk space (<8GB) significantly impacts reliability
- `replayd` process manages screen capture sessions
- Silent failures possible when resources constrained

### Filtering Efficiency
- Use specific filters (window/app) rather than unfiltered capture
- Exception windows processed after base filter rules
- More specific filters = better performance

### Best Practices
```swift
// Cache shareable content, refresh only when needed
private var cachedContent: SCShareableContent?
private var lastRefresh: Date?

func refreshContentIfNeeded() async throws {
    let shouldRefresh = lastRefresh == nil ||
                       Date().timeIntervalSince(lastRefresh!) > 5.0

    if shouldRefresh {
        cachedContent = try await SCShareableContent.current
        lastRefresh = Date()
    }
}

// Use specific filters
let filter = SCContentFilter(
    display: display,
    excludingApplications: [myApp],
    exceptingWindows: [] // Add specific exception windows
)
```

### Exception Window Pattern
```swift
// Get own window to exclude
let content = try await SCShareableContent.current
let ownWindow = content.windows.first {
    $0.windowID == CGWindowID(myNSWindow.windowNumber)
}

let filter = SCContentFilter(
    display: selectedDisplay,
    excludingApplications: [],
    exceptingWindows: ownWindow.map { [$0] } ?? []
)
```

## Sources

- [Apple ScreenCaptureKit Documentation](https://developer.apple.com/documentation/screencapturekit)
- [Apple SCContentFilter Reference](https://developer.apple.com/documentation/screencapturekit/sccontentfilter)
- [Apple SCShareableContent Reference](https://developer.apple.com/documentation/screencapturekit/scshareablecontent)
- [Apple SCWindow Reference](https://developer.apple.com/documentation/screencapturekit/scwindow)
- [StackOverflow: ScreenCaptureKit Issues](https://stackoverflow.com/questions/tagged/screencapturekit)
- [GitHub: ScreenCaptureKit Samples](https://github.com/search?q=screencapturekit)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

## Summary

**Core Pattern**:
1. Query `SCShareableContent.current` asynchronously off main thread
2. Find target window by matching `windowID` to `NSWindow.windowNumber`
3. Create `SCContentFilter` with `exceptingWindows` parameter
4. Handle edge cases: hanging queries, permission dialogs, low disk space
5. Update UI on MainActor

**Critical Gotchas**:
- Queries can hang - implement timeouts and error handling
- macOS 15+ ignores traditional window protection flags
- Low disk space causes silent failures
- Desktop capture requires excluding own app
- Always run queries off main thread
