# Phase 05: Relocate Keyboard Shortcuts

## Context
- Parent: [plan.md](./plan.md)
- Dependencies: Phase 01, Phase 04

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Priority | Medium |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

Move keyboard shortcuts from removed zoomControls to appropriate parent views.

## Key Insights
- "z" shortcut: Add zoom at playhead - move to VideoEditorMainView or VideoTimelineView
- Delete shortcut: Delete selected zoom - move to VideoEditorMainView
- Toggle visibility button: Consider keeping elsewhere or removing if redundant
- Shortcuts should work regardless of focus state

## Requirements
1. "z" key adds zoom at playhead position
2. Delete key removes selected zoom
3. Shortcuts work when editor window is focused
4. No duplicate shortcuts

## Architecture
Add keyboard shortcuts to VideoEditorMainView or ZoomTimelineTrack using `.keyboardShortcut` modifier.

## Related Code Files
- `ClaudeShot/Features/VideoEditor/Views/VideoEditorMainView.swift`
- `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomTimelineTrack.swift`
- `ClaudeShot/Features/VideoEditor/Views/VideoTimelineView.swift`

## Implementation Steps

### Step 1: Check VideoEditorMainView structure
Need to read file to determine best placement.

### Step 2: Add "z" shortcut for add zoom at playhead
```swift
// In VideoEditorMainView or appropriate parent
.keyboardShortcut("z", modifiers: [])
// Or use Button with hidden appearance
Button("") {
    let currentTime = CMTimeGetSeconds(state.currentTime)
    state.addZoom(at: currentTime)
}
.keyboardShortcut("z", modifiers: [])
.opacity(0)
.frame(width: 0, height: 0)
```

### Step 3: Add delete shortcut for selected zoom
```swift
Button("") {
    if let id = state.selectedZoomId {
        state.removeZoom(id: id)
    }
}
.keyboardShortcut(.delete, modifiers: [])
.opacity(0)
.frame(width: 0, height: 0)
.disabled(state.selectedZoomId == nil)
```

### Step 4: Consider toggle visibility shortcut
The eye/eye.slash toggle may need relocation or can be accessed via context menu only.

## Todo List
- [ ] Read VideoEditorMainView to find best shortcut placement
- [ ] Add hidden button with "z" shortcut for add zoom
- [ ] Add hidden button with delete shortcut for remove zoom
- [ ] Verify shortcuts don't conflict with existing ones
- [ ] Test shortcuts work when focus on different parts of UI
- [ ] Update help tooltips if any

## Success Criteria
1. Press "z" adds zoom at playhead
2. Press Delete removes selected zoom
3. Shortcuts work without focus on specific control
4. No shortcut conflicts

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Shortcut conflicts | Low | Medium | Check existing shortcuts first |
| Focus issues | Medium | Low | Test with different focus states |

## Security Considerations
None - keyboard handling only.

## Next Steps
Implementation complete. Proceed to testing and verification.
