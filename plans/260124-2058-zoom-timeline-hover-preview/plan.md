# Zoom Timeline Hover Preview

## Overview
Remove zoom controls from VideoControlsView and add hover-based zoom placeholder preview in ZoomTimelineTrack for intuitive click-to-add zoom functionality.

## Status
| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Remove zoomControls from VideoControlsView | ✅ Complete |
| 02 | Add hover state tracking to ZoomTimelineTrack | ✅ Complete |
| 03 | Create ZoomPlaceholderView component | ✅ Complete |
| 04 | Integrate placeholder with click-to-add | ✅ Complete |
| 05 | Relocate keyboard shortcuts | ✅ Complete |

## Implementation Phases

### [Phase 01: Remove zoomControls](./phase-01-remove-zoom-controls.md)
Remove zoomControls computed property and its usage from VideoControlsView.

### [Phase 02: Add Hover State](./phase-02-add-hover-state.md)
Add hover tracking state and mouse position tracking to ZoomTimelineTrack.

### [Phase 03: Create Placeholder View](./phase-03-create-placeholder-view.md)
Create ghost/placeholder visual for zoom segment preview on hover.

### [Phase 04: Integrate Click-to-Add](./phase-04-integrate-click-to-add.md)
Modify tap gesture to add zoom at clicked position with placeholder preview.

### [Phase 05: Relocate Shortcuts](./phase-05-relocate-shortcuts.md)
Move keyboard shortcuts to appropriate parent views.

## Files Modified
- `ClaudeShot/Features/VideoEditor/Views/VideoControlsView.swift`
- `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomTimelineTrack.swift`

## Dependencies
- ZoomSegment model (unchanged)
- ZoomColors (unchanged)
- VideoEditorState (unchanged)

## Success Criteria
1. Zoom controls removed from VideoControlsView
2. Placeholder appears on hover over empty track area
3. Placeholder centered on mouse X position
4. Click adds zoom at placeholder position
5. All existing functionality preserved (drag, select, context menu)
6. Keyboard shortcuts functional
