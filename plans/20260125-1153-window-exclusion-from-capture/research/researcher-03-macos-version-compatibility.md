# macOS Version Compatibility: ScreenCaptureKit SCContentFilter API

## Executive Summary

`SCContentFilter` with `excludingApplications` parameter available since **macOS 12.3** - works on macOS 14, 15. No macOS 26 exists (likely typo for future versions). Key breaking change: macOS 15 ignores `NSWindow.sharingType = .none`.

## 1. SCContentFilter Initialization Methods by Version

### macOS 12.3+ (Foundation - Monterey)
**All core APIs introduced:**

```swift
// Available since macOS 12.3
@available(macOS 12.3, *)
init(desktopIndependentWindow: SCWindow)

@available(macOS 12.3, *)
init(display: SCDisplay,
     excludingApplications: [SCRunningApplication],
     exceptingWindows: [SCWindow])

@available(macOS 12.3, *)
init(display: SCDisplay,
     including: [SCWindow])
```

### macOS 13.0 (Ventura)
**Enhancements:**
- Audio capture support
- Synchronization clock

**No new SCContentFilter initializers** - uses same API from 12.3

### macOS 14.0 (Sonoma)
**New Screenshot API:**

```swift
@available(macOS 14.0, *)
class SCScreenshotManager {
    class func captureImage(
        contentFilter: SCContentFilter,
        configuration: SCStreamConfiguration,
        completionHandler: ((CGImage?, Error?) -> Void)?
    )
}
```

**Key changes:**
- `SCScreenshotManager` replaces deprecated `CGWindowListCreateImage`
- System-level `SCContentSharingPicker` UI (no screen recording permission required for picker)
- **No changes to SCContentFilter initialization methods**

### macOS 15.0 (Sequoia)
**Breaking behavior change:**

```swift
// THIS NO LONGER WORKS ON macOS 15+
window.sharingType = .none  // ❌ Ignored by ScreenCaptureKit
```

**New features:**
- Recording output capabilities
- HDR capture support
- Enhanced microphone support
- **No new SCContentFilter initializers**

**Critical:** macOS 15 fully composites all `NSWindow` contents into single framebuffer before ScreenCaptureKit capture - rendering previous protection flags ineffective. No known workaround.

### macOS 26
**Does not exist** - likely refers to future beta/unreleased version in error reports.

## 2. API Availability: excludingApplications

### Answer: Works on macOS 14 ✅

```swift
// Available since macOS 12.3 - works on macOS 14, 15+
@available(macOS 12.3, *)
let filter = SCContentFilter(
    display: mainDisplay,
    excludingApplications: [selfApp],  // ✅ Available macOS 12.3+
    exceptingWindows: []
)
```

**Verification:**
- Introduced: macOS 12.3 (March 2022)
- macOS 14.0: ✅ Fully supported
- macOS 15.0: ✅ Fully supported
- Requires: Screen Recording permission in System Preferences

## 3. Deprecated/Obsoleted APIs

### macOS 14.0 (Sonoma)
**Deprecated:**
- `CGWindowListCreateImage` → use `SCScreenshotManager.captureImage`

### macOS 15.0 (Sequoia)
**Obsoleted (compilation errors):**
- `CGDisplayCreateImage`
- `CGWindowListCreateImageFromArray`
- `CGDisplayStreamCreate`
- `CGDisplayCreateImageForRect`
- `CGWindowListCreateImage` (generates unlimited privacy popups)

**Migration path:** ScreenCaptureKit only - no legacy APIs available.

## 4. Version-Conditional Code Patterns

### Pattern 1: Basic Availability Check

```swift
import ScreenCaptureKit

@available(macOS 12.3, *)
class ScreenCaptureManager {
    func setupFilter() async throws {
        let content = try await SCShareableContent.current()

        guard let mainDisplay = content.displays.first else {
            throw CaptureError.noDisplay
        }

        // Get current app to exclude
        let currentApp = content.applications.first {
            $0.bundleIdentifier == Bundle.main.bundleIdentifier
        }

        let excludedApps = currentApp.map { [$0] } ?? []

        let filter = SCContentFilter(
            display: mainDisplay,
            excludingApplications: excludedApps,
            exceptingWindows: []
        )

        return filter
    }
}
```

### Pattern 2: Screenshot vs Stream (macOS 14+)

```swift
@available(macOS 12.3, *)
func captureScreen(filter: SCContentFilter) async throws -> CGImage {
    if #available(macOS 14.0, *) {
        // Use new screenshot API
        return try await withCheckedThrowingContinuation { continuation in
            let config = SCStreamConfiguration()
            SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            ) { image, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: CaptureError.noImage)
                }
            }
        }
    } else {
        // Fallback: Use SCStream for single frame
        return try await captureWithStream(filter: filter)
    }
}
```

### Pattern 3: Window Protection (macOS 14 vs 15)

```swift
@available(macOS 12.3, *)
class OverlayWindowController {
    func configureWindowProtection(window: NSWindow) {
        if #available(macOS 15.0, *) {
            // ⚠️ sharingType.none is IGNORED on macOS 15+
            // Must use SCContentFilter exclusion instead
            window.sharingType = .none  // No effect
            print("Warning: Window protection requires SCContentFilter exclusion on macOS 15+")
        } else {
            // Works on macOS 14 and earlier
            window.sharingType = .none  // ✅ Effective
        }

        // Always set window level to keep above captured content
        window.level = .floating
    }
}
```

### Pattern 4: Runtime Version Detection

```swift
@available(macOS 12.3, *)
class CaptureConfiguration {
    static var supportsWindowProtection: Bool {
        if #available(macOS 15.0, *) {
            return false  // sharingType.none ignored
        } else {
            return true   // sharingType.none works
        }
    }

    static var requiresExplicitExclusion: Bool {
        if #available(macOS 15.0, *) {
            return true   // Must use excludingApplications
        } else {
            return false  // Can use sharingType.none
        }
    }

    static var hasScreenshotAPI: Bool {
        if #available(macOS 14.0, *) {
            return true
        } else {
            return false
        }
    }
}
```

### Pattern 5: Three-Stage Filtering

```swift
@available(macOS 12.3, *)
func createAdvancedFilter(
    display: SCDisplay,
    excludeApps: [SCRunningApplication],
    includeWindows: [SCWindow],
    excludeWindows: [SCWindow]
) -> SCContentFilter {
    // Stage 1: Define display to capture
    // Stage 2: Exclude apps → excludingApplications
    // Stage 3: Fine-tune with exceptingWindows

    // exceptingWindows behavior:
    // - Window from excludedApp + in exceptingWindows → INCLUDED
    // - Window NOT from excludedApp + in exceptingWindows → EXCLUDED

    var exceptingWindows = includeWindows  // Include specific windows
    exceptingWindows.append(contentsOf: excludeWindows)  // Exclude others

    return SCContentFilter(
        display: display,
        excludingApplications: excludeApps,
        exceptingWindows: exceptingWindows
    )
}
```

## 5. Best Practices for ClaudeShot (macOS 14.0+)

### Recommended Approach

```swift
import ScreenCaptureKit

@available(macOS 14.0, *)
class ClaudeShotCaptureManager {
    private var currentApp: SCRunningApplication?

    func initializeCapture() async throws -> SCContentFilter {
        // 1. Get shareable content
        let content = try await SCShareableContent.current()

        // 2. Find main display
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }

        // 3. Find ClaudeShot app to exclude
        currentApp = content.applications.first {
            $0.bundleIdentifier == "com.yourcompany.claudeshot"
        }

        // 4. Create filter excluding self
        let excludedApps = currentApp.map { [$0] } ?? []

        return SCContentFilter(
            display: display,
            excludingApplications: excludedApps,
            exceptingWindows: []
        )
    }

    func captureScreenshot(filter: SCContentFilter) async throws -> CGImage {
        let config = SCStreamConfiguration()

        // Use macOS 14+ screenshot API
        return try await withCheckedThrowingContinuation { continuation in
            SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            ) { image, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: CaptureError.noImage)
                }
            }
        }
    }
}
```

### Key Recommendations

1. **Target macOS 14.0+ minimum** - ClaudeShot README already specifies macOS 14.0+
2. **Use SCContentFilter exclusion** - Don't rely on `NSWindow.sharingType = .none`
3. **Refresh content regularly** - Running apps change, re-fetch `SCShareableContent`
4. **Handle permissions** - Screen Recording permission required
5. **Use SCScreenshotManager** - Available on target macOS 14.0+

### Permission Handling

```swift
@available(macOS 12.3, *)
func checkScreenRecordingPermission() async -> Bool {
    do {
        // Attempting to get content will trigger permission request
        _ = try await SCShareableContent.current()
        return true
    } catch {
        // Permission denied or not granted
        return false
    }
}
```

## 6. Migration Path from Legacy APIs

### ❌ Don't Use (Obsoleted on macOS 15)

```swift
// OBSOLETE - Compilation error on macOS 15+
let image = CGDisplayCreateImage(displayID)
let image = CGWindowListCreateImage(rect, .optionAll, windowID, [])
```

### ✅ Use Instead

```swift
@available(macOS 14.0, *)
let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
let config = SCStreamConfiguration()
SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
    // Handle result
}
```

## 7. Summary Table

| Feature | macOS 12.3 | macOS 13.0 | macOS 14.0 | macOS 15.0 |
|---------|-----------|-----------|-----------|-----------|
| `SCContentFilter.init(display:excludingApplications:)` | ✅ | ✅ | ✅ | ✅ |
| `excludingApplications` parameter | ✅ | ✅ | ✅ | ✅ |
| `SCScreenshotManager` | ❌ | ❌ | ✅ | ✅ |
| `NSWindow.sharingType = .none` protection | ✅ | ✅ | ✅ | ❌ |
| `CGWindowListCreateImage` | Deprecated | Deprecated | Deprecated | Obsolete |
| Audio capture | ❌ | ✅ | ✅ | ✅ |
| HDR capture | ❌ | ❌ | ❌ | ✅ |

## 8. Unresolved Questions

1. **macOS 15 window protection alternative?** - No known workaround for `sharingType = .none` being ignored. Only SCContentFilter exclusion works.

2. **Performance impact of frequent SCShareableContent refresh?** - Unknown if polling for updated app/window list impacts performance. Testing recommended.

3. **ExceptingWindows edge cases?** - Limited documentation on complex scenarios with multiple excluded apps and exception windows.

---

## Sources

- [Apple Developer: SCContentFilter](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHn54uSll1mn0I2sCFPIddjN1xfOydlJLpdginun1F9YTM75qawbWTnvsRhWv42BIrf_JeumTiuKYx3vvTk_D2yqZ-rk9m2h6rDTqNTiCZs1sXk2YTd-oLVpv-Ib75yA9hYCxQwJ7LTgw7y-yqDxQHLBF-p0XIfyNdeQfWWc5T1HKtVumo=)
- [Apple Developer: SCScreenshotManager](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFP0mFoXTDhK9q9Lt9qA0gYko7bUnsv5rF3-1wORFWOCiUbIol1m8l6yU2Djx1M8HphvocXFzHsff9wox9_vqOdTq3JZkMVjWtWYNGaRshOHJ7cJdB6vCgseBO2itwPwBc1xlDH-_kJjqHvq7-i4OFdHpWur1yurJrlD4zEmlrOOrPcSLeONBo4AA==)
- [Nonstrict: ScreenCaptureKit on macOS Sonoma](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGzQyn7Ayx_HQKAKwS9JitpxSwhX7zZD_E14Pwru4x9uNGkf_u8ikzO8uLcpP85YADfWXpyQmqHCmnYTu5tqeuBWBLJpzxjHSSYiKfyNWQ7r-ZiL2V6TfdBPxJkZeKm9NoLGCK57OSR-l45DmzMlbQ838pb5TRGB1xa5BOG6hwJvqEJ)
- [GitHub: NSWindow.sharingType ignored on macOS 15](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFr8ccWxIr5TqipZb0-Nwcz8ebmA2e_rYtG_20q_4IKUZTyj5F8obkL2I5cwqGMr9Mkn1pRtTXDQnqrwPFFyL1BsXhTKMt_-NZKana3KE83ekcCnfvTArO7DPgMahNfoj2vn3kBIqRddJMc)
- [9to5Mac: ScreenCaptureKit Improvements](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHjFS7SRQxKI7aiaapvOCsd-XqJJLynAILOOin1SmZX0tXNbQ0pFwiyDfVpDirAa4Lwe5v90h_D5ZUL-Lcvlf6QUWIQKBAW0nSpxaiyElUm4QwEIDPIFJ73dMVrLeL14jPa1iK3Ju_UXQhyIe7FPyQeyw6uisuBD1aOyO8nMviJ025sNEi7dBu1garwojUeI0SHtda7LQjGc2ZG_j_ffpL42Ui-bynLh-L12huTnGk8)
