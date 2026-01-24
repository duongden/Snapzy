# Phase 01: Remove zoomControls from VideoControlsView

## Context
- Parent: [plan.md](./plan.md)
- Dependencies: None

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

Remove the zoomControls section from VideoControlsView as this functionality will move to the ZoomTimelineTrack with hover-based interaction.

## Key Insights
- zoomControls contains 3 buttons: add zoom, delete selected, toggle visibility
- Keyboard shortcuts (z, delete) need relocation to parent view
- Zoom count indicator should remain in VideoControlsView

## Requirements
1. Remove `zoomControls` computed property (lines 98-142)
2. Remove `zoomControls` usage from body (line 46)
3. Keep zoom count indicator intact (lines 65-80)
4. Keep trimmed duration indicator intact (lines 82-93)

## Architecture
No architectural changes. Simple removal of UI components.

## Related Code Files
- `ClaudeShot/Features/VideoEditor/Views/VideoControlsView.swift`

## Implementation Steps

### Step 1: Remove zoomControls from body
```swift
// BEFORE (line 46):
zoomControls

// AFTER:
// Remove this line entirely
```

### Step 2: Remove zoomControls computed property
Remove lines 98-142 (entire `private var zoomControls: some View` property)

### Step 3: Remove addZoomAtPlayhead function
Remove lines 146-149 (no longer needed in this view)

### Step 4: Remove deleteSelectedZoom function
Remove lines 151-155 (no longer needed in this view)

## Todo List
- [ ] Remove zoomControls usage from body
- [ ] Remove zoomControls computed property
- [ ] Remove addZoomAtPlayhead function
- [ ] Remove deleteSelectedZoom function
- [ ] Verify build succeeds
- [ ] Test UI renders correctly

## Success Criteria
1. VideoControlsView compiles without errors
2. Zoom count indicator still displays
3. Play/pause, mute, time display still functional
4. No visual regression except removed zoom buttons

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking keyboard shortcuts | Medium | Medium | Relocate in Phase 05 |

## Security Considerations
None - UI-only changes.

## Next Steps
Proceed to Phase 02: Add Hover State to ZoomTimelineTrack
