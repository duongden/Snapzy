# Phase 02: Add Hover State to ZoomTimelineTrack

## Context
- Parent: [plan.md](./plan.md)
- Dependencies: Phase 01

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

Add hover state tracking and mouse position tracking to ZoomTimelineTrack for placeholder preview.

## Key Insights
- SwiftUI provides `onContinuousHover` for precise mouse tracking (macOS 13+)
- Need both hover state (bool) and position (CGPoint)
- Should hide placeholder when hovering over existing segment
- Should hide placeholder during drag operations

## Requirements
1. Track hover state (isHovering: Bool)
2. Track mouse position (hoverLocation: CGPoint)
3. Calculate time position from mouse X
4. Detect if hovering over existing segment

## Architecture
Add state variables to ZoomTimelineTrack for hover tracking.

## Related Code Files
- `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomTimelineTrack.swift`

## Implementation Steps

### Step 1: Add state variables
```swift
// Add after existing @State variables (around line 25)
@State private var isHovering: Bool = false
@State private var hoverLocation: CGPoint = .zero
```

### Step 2: Add computed property for hover time
```swift
private var hoverTime: TimeInterval {
    guard videoDuration > 0 else { return 0 }
    return (hoverLocation.x / timelineWidth) * videoDuration
}
```

### Step 3: Add computed property to check if over existing segment
```swift
private var isHoveringOverSegment: Bool {
    state.zoomSegment(at: hoverTime) != nil
}
```

### Step 4: Add computed property for placeholder visibility
```swift
private var shouldShowPlaceholder: Bool {
    isHovering && !isHoveringOverSegment && dragMode == .none
}
```

### Step 5: Add onContinuousHover modifier to track
```swift
// Add to .frame(height: trackHeight) chain
.onContinuousHover { phase in
    switch phase {
    case .active(let location):
        isHovering = true
        hoverLocation = location
    case .ended:
        isHovering = false
    }
}
```

## Todo List
- [ ] Add isHovering state
- [ ] Add hoverLocation state
- [ ] Add hoverTime computed property
- [ ] Add isHoveringOverSegment computed property
- [ ] Add shouldShowPlaceholder computed property
- [ ] Add onContinuousHover modifier
- [ ] Verify build succeeds

## Success Criteria
1. Hover state updates correctly on mouse enter/exit
2. Mouse position tracked accurately
3. No interference with existing drag gestures
4. No performance issues

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gesture conflicts | Low | Medium | onContinuousHover is observation-only |
| Performance | Low | Low | Only updates on mouse move |

## Security Considerations
None - state tracking only.

## Next Steps
Proceed to Phase 03: Create ZoomPlaceholderView
