# MenuBar Recording Status Implementation Plan

**Created**: 2025-01-25
**Status**: Planning Complete
**Estimate**: ~2-3 hours implementation

## Summary

Replace SwiftUI MenuBarExtra with NSStatusItem to enable:
1. Dynamic icon based on recording state
2. Click-to-stop during active recording
3. Normal menu behavior when idle

## Approach Selected

**NSStatusItem with manual menu management** (Approach B from analysis)

Reason: Only approach enabling click-without-menu behavior required for click-to-stop.

## Phases

| Phase | Description | Status | Link |
|-------|-------------|--------|------|
| 01 | State Observation Setup | Pending | [phase-01-state-observation.md](./phase-01-state-observation.md) |
| 02 | Dynamic Icon Implementation | Pending | [phase-02-dynamic-icon.md](./phase-02-dynamic-icon.md) |
| 03 | Click-to-Stop Implementation | Pending | [phase-03-click-to-stop.md](./phase-03-click-to-stop.md) |

## Files to Create

- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/App/StatusBarController.swift`

## Files to Modify

| File | Changes |
|------|---------|
| `ClaudeShotApp.swift` | Remove MenuBarExtra (lines 37-40) |
| `AppDelegate` | Add StatusBarController.shared.setup() |
| `RecordingCoordinator.swift` | Add public stop() method |

## Technical Reports

- [01-technical-analysis.md](./reports/01-technical-analysis.md) - Approach evaluation

## Key Dependencies

```
StatusBarController
    |
    +-- ScreenRecordingManager.shared (state observation)
    +-- RecordingCoordinator.shared (stop action)
    +-- ScreenCaptureViewModel (menu actions)
    +-- AnnotateManager.shared
    +-- VideoEditorManager.shared
```

## Icon States

| State | Icon | Color |
|-------|------|-------|
| Idle | camera.aperture | Template (auto) |
| Preparing | camera.aperture | Template |
| Recording | record.circle.fill | Red |
| Paused | record.circle.fill | Orange |
| Stopping | record.circle.fill | Red |

## Click Behavior

| Recording? | Left Click | Right Click |
|------------|------------|-------------|
| No | Show menu | Show menu |
| Yes | Stop recording | Show menu |

## Success Criteria

- [ ] Icon updates reactively with recording state
- [ ] Click stops recording when active
- [ ] Menu shows all original items when idle
- [ ] Keyboard shortcuts functional
- [ ] No memory leaks
- [ ] Works in light/dark mode

## Risks

1. **Menu item parity** - Must replicate all MenuBarContentView functionality
2. **ScreenCaptureViewModel access** - May need singleton pattern
3. **Sparkle updater integration** - Needs updater reference

## Unresolved Questions

1. Should right-click always show menu during recording?
2. Add visual feedback (animation) during recording?
3. Include "Stop Recording" in menu during recording state?
