# NSWindow Traffic Light Extension Plan

**Created:** 2026-01-26
**Status:** Draft
**Priority:** Medium

## Summary

Extract traffic light button positioning logic from `AnnotateWindow.swift` into a reusable NSWindow extension for consistent window styling across the app.

## Context

- `AnnotateWindow.swift` contains `layoutIfNeeded()` override that repositions traffic light buttons
- `VideoEditorWindow.swift` will need same functionality
- Existing pattern: `NSWindow+CornerRadius.swift` in Core folder

## Phases

| Phase | Name | Status | File |
|-------|------|--------|------|
| 01 | Create Traffic Light Extension | Pending | [phase-01-create-extension.md](./phase-01-create-extension.md) |
| 02 | Update AnnotateWindow | Pending | [phase-02-update-annotate-window.md](./phase-02-update-annotate-window.md) |

## Files Affected

- **New:** `ClaudeShot/Core/NSWindow+TrafficLights.swift`
- **Modified:** `ClaudeShot/Features/Annotate/Window/AnnotateWindow.swift`
- **Future:** `ClaudeShot/Features/VideoEditor/VideoEditorWindow.swift` (can adopt when needed)

## Key Decisions

1. **Separate file** vs extending existing `NSWindow+CornerRadius.swift`
   - Decision: Create new file `NSWindow+TrafficLights.swift` for single responsibility
2. **Configurable parameters** for different toolbar dimensions
   - Decision: Use struct for configuration with sensible defaults

## Success Criteria

- [ ] Extension created with configurable parameters
- [ ] AnnotateWindow uses new extension
- [ ] No visual regression in traffic light positioning
- [ ] VideoEditorWindow can easily adopt extension
