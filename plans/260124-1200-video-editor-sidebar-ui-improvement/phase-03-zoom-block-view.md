# Phase 03: Polish ZoomBlockView Timeline Blocks

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** [Phase 01](./phase-01-zoom-colors-refactor.md)
- **Related Docs:** None

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Description | Polish timeline zoom blocks with system colors and refined visual treatment |
| Priority | Medium |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Not Started |

## Key Insights

1. `ZoomColors` already centralized - Phase 01 updates will cascade here
2. Block uses shadow for selected state - keep but refine
3. Type badge uses `Color.white.opacity(0.2)` - acceptable, keep
4. Resize handle highlighting works well

## Requirements

- Blocks use system accent color (via ZoomColors)
- Subtle refinements to shadow/border treatment
- Maintain drag/resize functionality
- Keep white text for contrast on accent backgrounds

## Architecture

### Block Fill Color
```swift
// Already uses ZoomColors - will update automatically from Phase 01
private var blockFillColor: Color {
  if !segment.isEnabled { return ZoomColors.disabled }
  if isDragging { return ZoomColors.primaryDark }
  return ZoomColors.primary
}
```

### Selected State Border
```swift
// CURRENT - good, keep
.strokeBorder(isSelected ? ZoomColors.selected : Color.clear, lineWidth: 2)
```

### Shadow
```swift
// BEFORE
.shadow(color: isSelected ? ZoomColors.primary.opacity(0.4) : .clear, radius: 4, y: 2)

// AFTER - slightly refined
.shadow(color: isSelected ? ZoomColors.primary.opacity(0.35) : .clear, radius: 3, y: 1)
```

## Related Code Files

| File | Lines | Purpose |
|------|-------|---------|
| `ZoomBlockView.swift:69-139` | Main body with block rendering |
| `ZoomBlockView.swift:192-202` | blockFillColor computed property |

## Implementation Steps

1. Verify ZoomColors updates from Phase 01 cascade correctly
2. Refine shadow values (radius 3, y 1, opacity 0.35)
3. Optional: adjust handle highlight opacity if needed
4. Test drag/resize still works

## Todo List

- [ ] Verify ZoomColors.primary uses system accent (from Phase 01)
- [ ] Refine shadow: radius 4→3, y 2→1, opacity 0.4→0.35
- [ ] Test in light and dark mode
- [ ] Verify drag gestures unaffected

## Success Criteria

- [ ] Blocks use system accent color
- [ ] Selected state has subtle, professional shadow
- [ ] All interactions work correctly
- [ ] Consistent look with sidebar

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Shadow too subtle | Low | Low | Adjust if needed |
| Gesture conflicts | Very Low | High | Test thoroughly |

## Security Considerations

None - UI only changes.

## Next Steps

Proceed to Phase 04: ZoomCenterPicker refinement
