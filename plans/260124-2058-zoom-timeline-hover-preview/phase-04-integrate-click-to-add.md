# Phase 04: Integrate Placeholder with Click-to-Add

## Context
- Parent: [plan.md](./plan.md)
- Dependencies: Phase 03

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

Modify tap gesture to add zoom at clicked position when placeholder is visible.

## Key Insights
- Current handleTap selects/deselects segments
- Need to add zoom when tapping empty area (where placeholder shows)
- Zoom should be centered at tap position (matching placeholder preview)
- Existing addZoom(at:) already handles centering logic

## Requirements
1. Click on empty area adds zoom at that position
2. Click on existing segment selects it (unchanged)
3. Added zoom matches placeholder preview position
4. Proper deselection when clicking empty area without adding

## Architecture
Modify existing handleTap function to add zoom creation logic.

## Related Code Files
- `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomTimelineTrack.swift`
- `ClaudeShot/Features/VideoEditor/State/VideoEditorState.swift` (addZoom method)

## Implementation Steps

### Step 1: Modify handleTap to add zoom on empty area
```swift
private func handleTap(at location: CGPoint) {
    let tappedTime = (location.x / timelineWidth) * videoDuration
    print("🎯 [Tap] location: \(location), time: \(tappedTime)s")

    if let segment = state.zoomSegment(at: tappedTime) {
        // Tapped on existing segment - select it
        print("🎯 [Tap] Selected segment: \(segment.id)")
        state.selectZoom(id: segment.id)
    } else {
        // Tapped on empty area - add new zoom centered at tap position
        print("🎯 [Tap] Adding zoom at: \(tappedTime)s")
        state.addZoom(at: tappedTime)
    }
}
```

### Step 2: Update context menu to reflect new behavior
The context menu already has "Add Zoom at Playhead" option. Consider adding:
```swift
// In trackContextMenu, update first button
Button {
    // Add at current hover/tap position instead of playhead
    state.addZoom(at: hoverTime)
} label: {
    Label("Add Zoom Here", systemImage: "plus.magnifyingglass")
}
```

### Step 3: Add visual feedback on click
```swift
// Optional: Add brief scale animation on placeholder before it becomes real segment
// This provides satisfying feedback
```

## Todo List
- [ ] Modify handleTap to add zoom on empty area tap
- [ ] Update context menu label from "at Playhead" to "Here"
- [ ] Test tap adds zoom at correct position
- [ ] Test tap on segment still selects
- [ ] Verify zoom appears at placeholder position
- [ ] Test undo/redo works for added zooms

## Success Criteria
1. Clicking empty area adds zoom at that position
2. New zoom matches placeholder preview location
3. Clicking existing segment selects it
4. Undo works for newly added zooms
5. No double-add or ghost segments

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Accidental zoom creation | Medium | Low | Clear placeholder preview shows intent |
| Double-tap issues | Low | Low | Existing tap gesture handling |

## Security Considerations
None - user action handling.

## Next Steps
Proceed to Phase 05: Relocate Keyboard Shortcuts
