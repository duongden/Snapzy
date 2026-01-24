# Phase 03: Create ZoomPlaceholderView

## Context
- Parent: [plan.md](./plan.md)
- Dependencies: Phase 02

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

Create ghost/placeholder visual that previews where zoom will be added on click.

## Key Insights
- Match ZoomBlockVisual styling but with reduced opacity
- Use dashed border for "preview" appearance
- Width based on ZoomSegment.defaultDuration (2.0s)
- Center on mouse X position
- Use ZoomColors.primary for consistency

## Requirements
1. Ghost appearance (semi-transparent)
2. Dashed border
3. Centered on mouse position
4. Correct width based on default duration
5. Smooth appearance animation

## Architecture
Create private struct ZoomPlaceholderView inside ZoomTimelineTrack.swift.

## Related Code Files
- `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomTimelineTrack.swift`

## Implementation Steps

### Step 1: Add computed properties for placeholder positioning
```swift
private var placeholderWidth: CGFloat {
    guard videoDuration > 0 else { return 32 }
    return (ZoomSegment.defaultDuration / videoDuration) * timelineWidth
}

private var placeholderX: CGFloat {
    // Center placeholder on mouse position
    let centeredX = hoverLocation.x - (placeholderWidth / 2)
    // Clamp to track bounds
    return max(0, min(centeredX, timelineWidth - placeholderWidth))
}
```

### Step 2: Create ZoomPlaceholderView struct
```swift
private struct ZoomPlaceholderView: View {
    let width: CGFloat
    let xPosition: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(ZoomColors.primary.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        ZoomColors.primary.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
            )
            .frame(width: width, height: 28)
            .offset(x: xPosition)
            .allowsHitTesting(false)
    }
}
```

### Step 3: Add placeholder to ZStack in body
```swift
// Add after ForEach(state.zoomSegments) block
if shouldShowPlaceholder {
    ZoomPlaceholderView(
        width: placeholderWidth,
        xPosition: placeholderX
    )
    .transition(.opacity.animation(.easeOut(duration: 0.15)))
}
```

### Step 4: Add icon and label to placeholder
```swift
// Inside ZoomPlaceholderView body, add content overlay
.overlay(
    HStack(spacing: 4) {
        Image(systemName: "plus.magnifyingglass")
            .font(.system(size: 10, weight: .semibold))
        Text("Click to add")
            .font(.system(size: 9, weight: .medium))
    }
    .foregroundColor(ZoomColors.primary.opacity(0.8))
)
```

## Todo List
- [ ] Add placeholderWidth computed property
- [ ] Add placeholderX computed property
- [ ] Create ZoomPlaceholderView struct
- [ ] Add placeholder to body ZStack
- [ ] Add appearance animation
- [ ] Add content overlay (icon + label)
- [ ] Verify visual matches design
- [ ] Test hover behavior

## Success Criteria
1. Placeholder appears on hover over empty area
2. Placeholder hidden when over existing segment
3. Placeholder follows mouse position (centered)
4. Placeholder stays within track bounds
5. Smooth fade in/out animation

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Visual clutter | Low | Low | Subtle opacity and dashed style |
| Z-index issues | Low | Low | Add after segments in ZStack |

## Security Considerations
None - UI component only.

## Next Steps
Proceed to Phase 04: Integrate Click-to-Add
