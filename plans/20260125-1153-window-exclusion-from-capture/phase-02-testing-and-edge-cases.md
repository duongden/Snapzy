# Phase 02: Testing and Edge Case Handling

## Context Links
- [Main Plan](./plan.md)
- [Phase 01: Modify ScreenRecordingManager](./phase-01-modify-screen-recording-manager.md)
- [Research: ScreenCaptureKit Exclusion](./research/researcher-01-screencapturekit-exclusion.md)

## Overview
Validate the window exclusion implementation works correctly across different scenarios and handle edge cases gracefully.

## Key Insights
1. SCShareableContent queries can hang in rare cases - need timeout consideration
2. Bundle identifier matching should handle nil cases
3. macOS 14 vs 15 behavior differences exist but SCContentFilter exclusion works on both
4. Multiple displays require testing - filter applies per-display

## Requirements
- Verify toolbar/status bar excluded from recordings
- Handle edge cases without crashing
- Maintain backward compatibility with macOS 14
- Test multi-display scenarios

## Architecture

### Edge Case Handling Flow
```
prepareRecording()
    └── Query SCShareableContent
    └── Filter for own app
            ├── Found: Pass to setupStream with exclusion
            └── Not Found: Log warning, pass empty array (graceful degradation)
```

## Related Code Files

| File | Path | Purpose |
|------|------|---------|
| ScreenRecordingManager.swift | `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/ScreenRecordingManager.swift` | Edge case handling |

## Implementation Steps

### Step 1: Add defensive handling for missing bundle identifier

```swift
// In prepareRecording(), after SCShareableContent query
let ownBundleID = Bundle.main.bundleIdentifier
let excludedApps: [SCRunningApplication]

if let bundleID = ownBundleID {
  excludedApps = content.applications.filter { $0.bundleIdentifier == bundleID }
  if excludedApps.isEmpty {
    // App not in list - unusual but handle gracefully
    print("[ScreenRecordingManager] Warning: Own app not found in shareable content")
  }
} else {
  // No bundle ID available (very rare - development builds)
  excludedApps = []
  print("[ScreenRecordingManager] Warning: No bundle identifier available")
}
```

### Step 2: Add import if needed
Ensure `ScreenCaptureKit` import exists (already present at line 13).

## Test Cases

### Manual Testing Checklist

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Basic recording | Start recording, check output | No toolbar/status bar visible |
| Recording with pause | Pause, resume, stop | Status bar excluded throughout |
| Multi-display | Record on secondary display | Toolbar excluded on any display |
| Region resize during prepare | Resize region before starting | New overlay position excluded |
| Quick start/stop | Rapid start then stop | No crashes, clean output |
| Long recording (5+ min) | Extended recording session | Consistent exclusion |

### Automated Test Considerations
```swift
// Unit test pseudo-code for future implementation
func testExcludedAppsContainsOwnApp() async throws {
  let content = try await SCShareableContent.current
  let ownBundleID = Bundle.main.bundleIdentifier
  let excludedApps = content.applications.filter { $0.bundleIdentifier == ownBundleID }
  XCTAssertFalse(excludedApps.isEmpty, "Own app should be in shareable content")
}
```

## Todo List
- [ ] Add nil-safe bundle identifier handling
- [ ] Add warning logs for edge cases (missing app, missing bundle ID)
- [ ] Test on macOS 14 (if available)
- [ ] Test on macOS 15+
- [ ] Test single display recording
- [ ] Test multi-display recording
- [ ] Test with toolbar in different positions
- [ ] Verify pause/resume still works
- [ ] Verify audio capture still works
- [ ] Verify microphone capture still works
- [ ] Check output video quality unchanged

## Success Criteria
1. All manual test cases pass
2. No crashes or exceptions in edge cases
3. Warning logs appear for unusual conditions
4. Recording quality and performance unchanged
5. Works identically on macOS 14 and 15

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SCShareableContent hangs | Very Low | High | Existing permission flow handles this |
| Own app missing from list | Very Low | Low | Graceful degradation to current behavior |
| Performance regression | Very Low | Medium | SCContentFilter is lightweight |
| Multi-display edge cases | Low | Low | Per-display filter handles correctly |

## Security Considerations
- No new attack vectors introduced
- Exclusion only affects own app - cannot exclude other apps maliciously
- No sensitive data logging

## Known Limitations
1. Cannot selectively exclude specific windows while including others from same app
2. If app bundle ID changes (dev vs release), exclusion still works via runtime Bundle.main
3. Sandboxed apps may have different bundle ID resolution - verify in release builds

## Debugging Tips
```swift
// Add temporary logging to verify exclusion
print("[Debug] Excluding apps: \(excludedApps.map { $0.bundleIdentifier ?? "nil" })")
print("[Debug] Own bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
```

## Next Steps
After testing passes:
1. Remove debug logging if added
2. Consider adding user preference to toggle self-exclusion (future enhancement)
3. Document behavior in code comments
