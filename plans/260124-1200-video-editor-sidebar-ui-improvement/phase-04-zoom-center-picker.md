# Phase 04: Refine ZoomCenterPicker Widget

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** [Phase 01](./phase-01-zoom-colors-refactor.md)
- **Related Docs:** None

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Description | Refine center picker with better contrast and system-consistent styling |
| Priority | Low |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Not Started |

## Key Insights

1. Uses `Color.gray.opacity(0.3)` for placeholder - fine
2. Crosshair uses white with black shadow - good contrast
3. Zoom region overlay could use system colors
4. Border uses `Color.white.opacity(0.2)` - consistent with app

## Requirements

- Minor refinements only - widget is functional
- Improve zoom region visibility
- Consistent with overall styling

## Architecture

### Zoom Region Overlay
```swift
// BEFORE
.strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
.background(Color.white.opacity(0.1))

// AFTER - use accent for region highlight
.strokeBorder(ZoomColors.primary.opacity(0.6), lineWidth: 1.5)
.background(ZoomColors.primary.opacity(0.15))
```

### Crosshair - Keep Current
```swift
// Current implementation is good - white with shadow for visibility
Circle()
  .strokeBorder(Color.white, lineWidth: 2)
  .shadow(color: .black.opacity(0.5), radius: 2)
```

## Related Code Files

| File | Lines | Purpose |
|------|-------|---------|
| `ZoomCenterPicker.swift:57-69` | zoomRegionOverlay |
| `ZoomCenterPicker.swift:71-102` | crosshairView |

## Implementation Steps

1. Update `zoomRegionOverlay` to use `ZoomColors.primary`
2. Increase stroke width 1→1.5 for visibility
3. Keep crosshair as-is (white for universal visibility)
4. Test with various preview images

## Todo List

- [ ] Update region stroke to `ZoomColors.primary.opacity(0.6)`
- [ ] Update region background to `ZoomColors.primary.opacity(0.15)`
- [ ] Increase stroke lineWidth 1→1.5
- [ ] Test visibility on dark/light preview images

## Success Criteria

- [ ] Zoom region uses accent color
- [ ] Region visible on various backgrounds
- [ ] Crosshair remains clearly visible
- [ ] Drag interaction works correctly

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Region hard to see on blue images | Low | Low | White fallback if needed |

## Security Considerations

None - UI only changes.

## Next Steps

Implementation complete after this phase. Run full UI review.
