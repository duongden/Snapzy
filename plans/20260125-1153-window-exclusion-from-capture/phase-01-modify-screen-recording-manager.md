# Phase 01: Modify ScreenRecordingManager SCContentFilter

## Context Links
- [Main Plan](./plan.md)
- [Research: ScreenCaptureKit Exclusion](./research/researcher-01-screencapturekit-exclusion.md)
- [Research: UI Overlay Patterns](./research/researcher-02-ui-overlay-exclusion-patterns.md)

## Overview
Modify `setupStream()` method to exclude own app from capture using bundle identifier filtering instead of empty window exclusion.

## Key Insights
1. Current implementation uses `SCContentFilter(display:excludingWindows:[])` which captures ALL windows
2. macOS 15+ ignores `NSWindow.sharingType = .none` - must use SCContentFilter exclusion
3. Excluding by app (not individual windows) ensures all UI elements are excluded automatically
4. SCShareableContent query already happens in `prepareRecording()` - can reuse or pass to setupStream

## Requirements
- Exclude ClaudeShot app from screen capture output
- Maintain all existing recording functionality
- Handle edge case where own app not found in applications list
- No changes to public API

## Architecture

### Data Flow
```
prepareRecording()
    └── Query SCShareableContent.current (already done for permission check)
    └── Find own SCRunningApplication by bundleIdentifier
    └── Pass to setupStream()
            └── Create SCContentFilter with excludingApplications
```

### Method Signature Change
```swift
// Before
private func setupStream(display: SCDisplay, rect: CGRect, scaleFactor: CGFloat,
                         captureSystemAudio: Bool, captureMicrophone: Bool) async throws

// After
private func setupStream(display: SCDisplay, rect: CGRect, scaleFactor: CGFloat,
                         captureSystemAudio: Bool, captureMicrophone: Bool,
                         excludedApps: [SCRunningApplication]) async throws
```

## Related Code Files

| File | Path | Purpose |
|------|------|---------|
| ScreenRecordingManager.swift | `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/ScreenRecordingManager.swift` | Main modification target |

## Implementation Steps

### Step 1: Modify prepareRecording() to extract own app
Location: Lines 172-179

```swift
// Current code
let content: SCShareableContent
do {
  content = try await SCShareableContent.current
} catch {
  state = .idle
  self.error = .permissionDenied
  throw RecordingError.permissionDenied
}

// After permission check, add:
let excludedApps = content.applications.filter {
  $0.bundleIdentifier == Bundle.main.bundleIdentifier
}
```

### Step 2: Update setupStream() call
Location: Line 234

```swift
// Before
try await setupStream(display: display, rect: rect, scaleFactor: scaleFactor,
                      captureSystemAudio: captureSystemAudio,
                      captureMicrophone: captureMicrophone)

// After
try await setupStream(display: display, rect: rect, scaleFactor: scaleFactor,
                      captureSystemAudio: captureSystemAudio,
                      captureMicrophone: captureMicrophone,
                      excludedApps: excludedApps)
```

### Step 3: Modify setupStream() signature and filter creation
Location: Lines 422-423

```swift
// Before
private func setupStream(display: SCDisplay, rect: CGRect, scaleFactor: CGFloat,
                         captureSystemAudio: Bool, captureMicrophone: Bool) async throws {
  let filter = SCContentFilter(display: display, excludingWindows: [])

// After
private func setupStream(display: SCDisplay, rect: CGRect, scaleFactor: CGFloat,
                         captureSystemAudio: Bool, captureMicrophone: Bool,
                         excludedApps: [SCRunningApplication]) async throws {
  let filter = SCContentFilter(display: display,
                               excludingApplications: excludedApps,
                               exceptingWindows: [])
```

## Todo List
- [ ] Add `excludedApps` extraction in `prepareRecording()` after SCShareableContent query
- [ ] Update `setupStream()` method signature to accept `excludedApps` parameter
- [ ] Replace `SCContentFilter(display:excludingWindows:)` with `SCContentFilter(display:excludingApplications:exceptingWindows:)`
- [ ] Update the `setupStream()` call in `prepareRecording()` to pass excluded apps
- [ ] Build and verify no compilation errors
- [ ] Test recording to confirm toolbar/status bar excluded from output

## Success Criteria
1. Recording output does not contain RecordingToolbarWindow
2. Recording output does not contain RecordingRegionOverlayWindow borders
3. All existing recording features work (video, audio, microphone, pause/resume)
4. No performance degradation
5. Works on macOS 14 and 15+

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Own app not found in applications list | Low | Medium | Fallback to empty exclusion list (current behavior) |
| SCShareableContent query fails | Low | High | Already handled - throws permissionDenied |
| Filter creation fails | Very Low | High | Wrapped in existing try-catch |

## Security Considerations
- No security implications - using public Apple APIs as intended
- No new permissions required
- No data exposure risks

## Next Steps
After completing this phase, proceed to [Phase 02: Testing and Edge Cases](./phase-02-testing-and-edge-cases.md)
