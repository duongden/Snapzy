# UI Overlay Exclusion Patterns for macOS Screen Recording Apps

## Executive Summary

Modern macOS screen recording apps use **SCContentFilter with bundle identifier exclusion** as the primary method to hide UI overlays. Legacy approaches (`NSWindow.sharingType`, `CGShieldingWindowLevel`) are **ineffective on macOS 15+** due to compositor changes.

## Key Finding: macOS 15+ Breaking Changes

**Critical**: On macOS 15 and later, the compositor merges ALL visible content into a single framebuffer before sending to display. ScreenCaptureKit captures this framebuffer, rendering legacy window-level exclusion techniques obsolete.

## Approach Comparison

### 1. SCContentFilter Exclusion (RECOMMENDED)

**How it works**: Exclude entire application by bundle identifier during capture setup.

```swift
// Retrieve shareable content
let content = try await SCShareableContent.excludingDesktopWindows(
    false,
    onScreenWindowsOnly: true
)

// Filter to find own app
let excludedApps = content.applications.filter { app in
    Bundle.main.bundleIdentifier == app.bundleIdentifier
}

// Create filter excluding own app
let filter = SCContentFilter(
    display: display,
    excludingApplications: excludedApps,
    exceptingWindows: []
)
```

**Pros**:
- Works reliably on all macOS versions supporting ScreenCaptureKit
- Apple's recommended approach
- Excludes all windows from the app (toolbar, overlays, status bars)
- Can dynamically update filter without restarting stream via `updateContentFilter()`

**Cons**:
- Requires ScreenCaptureKit framework (macOS 12.3+)
- Excludes entire app, not selective windows
- User must grant "Screen Recording" permission in System Settings

### 2. NSWindow.sharingType = .none (LEGACY - BROKEN)

**How it works**: Set window property to prevent sharing.

```swift
window.sharingType = .none
```

**Status**: **Ineffective on macOS 15+**

**Why it fails**:
- ScreenCaptureKit ignores this property on macOS 15+
- Compositor merges visible content before ScreenCaptureKit access
- All visible windows captured regardless of sharingType

**Historical context**:
- Worked on macOS 14 and earlier
- Also restricted window participation in other system services
- Default is `.readOnly` (allows capture)

### 3. CGShieldingWindowLevel (LEGACY - BROKEN)

**Status**: **Ineffective on macOS 15+**

Same compositor issue as sharingType approach. Window level has no impact on capture exclusion.

### 4. Window-Specific Exclusion via exceptingWindows

**How it works**: Fine-grained control over specific windows within excluded apps.

```swift
// Exclude app but include specific windows back
let filter = SCContentFilter(
    display: display,
    excludingApplications: excludedApps,
    exceptingWindows: [specificWindow]
)
```

**Use case**: Exclude app by default, then whitelist specific windows to still capture.

**Limitation**: Cannot selectively exclude individual windows from an otherwise-included app. Must exclude entire app first, then add exceptions.

## Which Windows Need Exclusion

Typical screen recording app UI elements requiring exclusion:

1. **Recording toolbar** - Start/stop/pause controls
2. **Overlay controls** - On-screen annotation tools, drawing overlays
3. **Status indicators** - Recording timer, audio level meters
4. **Floating panels** - Settings, preview windows
5. **Menu bar extras** - Status bar icons/menus

**Best practice**: Exclude entire recording app via bundle identifier to catch all UI elements.

## Alternative UX Patterns

Apps like CleanShot X use complementary techniques:

1. **Hide desktop icons** - Toggle via hotkey or auto-hide during capture
2. **Auto-enable Do Not Disturb** - Prevent notification popups in recording
3. **Cursor control** - Show/hide cursor programmatically
4. **Hotkey-driven workflow** - Minimize toolbar, control via keyboard shortcuts
5. **Second monitor** - Place controls on non-recorded display

## Implementation Recommendations

### Primary Strategy
```swift
// 1. Get shareable content
let content = try await SCShareableContent.excludingDesktopWindows(
    false,
    onScreenWindowsOnly: true
)

// 2. Exclude own app
let selfApp = content.applications.filter {
    $0.bundleIdentifier == Bundle.main.bundleIdentifier
}

// 3. Create filter
let filter = SCContentFilter(
    display: selectedDisplay,
    excludingApplications: selfApp,
    exceptingWindows: []
)

// 4. Apply to stream
let config = SCStreamConfiguration()
try await stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: queue)
try await stream.updateContentFilter(filter)
```

### Fallback for macOS 14 and Earlier
```swift
if #available(macOS 15, *) {
    // Use SCContentFilter only
} else {
    // Can combine SCContentFilter + sharingType
    window.sharingType = .none
}
```

### Dynamic Updates
```swift
// Update filter without restarting stream
try await stream.updateContentFilter(newFilter)
```

## Edge Cases & Limitations

1. **User can still record via external device** (phone camera) - no technical prevention
2. **Requires Screen Recording permission** - Must request in System Settings
3. **Cannot exclude individual windows selectively** - All-or-nothing per app
4. **System picker vs programmatic API** - Both available, programmatic gives more control

## Unresolved Questions

1. Does exceptingWindows support excluding specific windows from an included app, or only including windows from an excluded app?
2. Performance impact of frequently updating content filters during active recording?
3. Can window exclusion work with non-display-based capture (window/application capture modes)?

---

## Sources

- [GitHub Discussion: NSWindow.sharingType on macOS 15](https://github.com)
- [Stack Overflow: Screen capture prevention techniques](https://stackoverflow.com)
- [Apple Developer: SCContentFilter](https://apple.com)
- [Apple Developer: ScreenCaptureKit Sample Code](https://apple.com)
- [Nonstrict.eu: ScreenCaptureKit Guide](https://nonstrict.eu)
- [Setapp: CleanShot X Features](https://setapp.com)
- [VidGrid: Screen Recording Best Practices](https://vidgrid.com)
