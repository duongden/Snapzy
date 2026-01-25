# Window Exclusion from Capture - Implementation Plan

## Status: Ready for Implementation

## Problem Statement
Recording toolbar and status bar appear in screen capture output. On macOS 15+, legacy exclusion methods (`NSWindow.sharingType = .none`) are broken.

## Solution
Exclude entire app by bundle identifier using `SCContentFilter(display:excludingApplications:exceptingWindows:)` - available since macOS 12.3, works on macOS 14, 15, and future versions.

## macOS Version Compatibility

| Feature | macOS 14 | macOS 15 | macOS 16+ |
|---------|----------|----------|-----------|
| `excludingApplications` parameter | ✅ | ✅ | ✅ |
| `NSWindow.sharingType = .none` | ✅ Works | ❌ Ignored | ❌ Ignored |
| `SCScreenshotManager` | ✅ | ✅ | ✅ |

**Key insight:** No version branching needed for exclusion - same API works across all supported versions.

## Current Code (Line 423 in ScreenRecordingManager.swift)
```swift
let filter = SCContentFilter(display: display, excludingWindows: [])
```

## Target Code
```swift
let excludedApps = content.applications.filter {
    $0.bundleIdentifier == Bundle.main.bundleIdentifier
}
let filter = SCContentFilter(
    display: display,
    excludingApplications: excludedApps,
    exceptingWindows: []
)
```

## Windows Automatically Excluded
1. RecordingToolbarWindow (pre-record toolbar + recording status bar)
2. RecordingRegionOverlayWindow instances (region highlight borders)
3. Any other app windows (settings, preferences, etc.)

## Implementation Phases

| Phase | Description | File |
|-------|-------------|------|
| 01 | Modify SCContentFilter in setupStream() | [phase-01-modify-screen-recording-manager.md](./phase-01-modify-screen-recording-manager.md) |
| 02 | Testing and edge case handling | [phase-02-testing-and-edge-cases.md](./phase-02-testing-and-edge-cases.md) |

## Key Files
- `ClaudeShot/Core/ScreenRecordingManager.swift` (main change)

## Research Reports
- [ScreenCaptureKit Exclusion](./research/researcher-01-screencapturekit-exclusion.md)
- [UI Overlay Patterns](./research/researcher-02-ui-overlay-exclusion-patterns.md)
- [macOS Version Compatibility](./research/researcher-03-macos-version-compatibility.md)

## Risk Level: Low
- Single file modification
- API stable since macOS 12.3
- No version-specific branching required
- Graceful degradation if own app not found
