# Phase 01: Reduce Component Sizes

## Context
- **Parent Plan**: [plan.md](./plan.md)
- **Dependencies**: None

## Overview
- **Date**: 2026-01-25
- **Description**: Reduce gradient preset button sizes and adjust grid layout for better sidebar fit
- **Priority**: Low
- **Implementation Status**: Pending
- **Review Status**: Awaiting approval

## Key Insights
1. Current 44x44px buttons with 4 columns = ~188px content width (excluding spacing)
2. Sidebar is 320px with 12px padding on each side = 296px available
3. Reducing to 32x32px with 5 columns = ~172px content width, better density
4. CompactColorSwatchGrid already uses 5 columns at 28px - should match pattern

## Requirements
- Reduce GradientPresetButton from 44x44 to 32x32
- Reduce WallpaperPlaceholder from 44x44 to 32x32
- Reduce BlurredPlaceholder from 44x44 to 32x32
- Update grid from 4 columns to 5 columns in both sidebar views
- Reduce corner radius proportionally (6 -> 4)

## Architecture
No architectural changes. Pure UI sizing adjustments.

## Related Code Files

| File | Purpose | Changes |
|------|---------|---------|
| `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift` | Shared components | Reduce button/placeholder sizes |
| `ClaudeShot/Features/VideoEditor/Views/VideoBackgroundSidebarView.swift` | Video sidebar | Update grid column count |
| `ClaudeShot/Features/Annotate/Views/AnnotateSidebarView.swift` | Annotate sidebar | Update grid column count |

## Implementation Steps

### Step 1: Update AnnotateSidebarComponents.swift
**File**: `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`

1. **GradientPresetButton** (lines 30-41):
   - Change `.frame(width: 44, height: 44)` to `.frame(width: 32, height: 32)`
   - Change `.cornerRadius(6)` to `.cornerRadius(4)`

2. **WallpaperPlaceholder** (lines 46-52):
   - Change `.frame(width: 44, height: 44)` to `.frame(width: 32, height: 32)`

3. **BlurredPlaceholder** (lines 54-61):
   - Change `.frame(width: 44, height: 44)` to `.frame(width: 32, height: 32)`

### Step 2: Update VideoBackgroundSidebarView.swift
**File**: `ClaudeShot/Features/VideoEditor/Views/VideoBackgroundSidebarView.swift`

1. **gradientSection** (line 58):
   - Change `count: 4` to `count: 5`

### Step 3: Update AnnotateSidebarView.swift
**File**: `ClaudeShot/Features/Annotate/Views/AnnotateSidebarView.swift`

1. **gradientSection** (line 82):
   - Change `count: 4` to `count: 5`

## Todo List
- [ ] Reduce GradientPresetButton size to 32x32
- [ ] Reduce WallpaperPlaceholder size to 32x32
- [ ] Reduce BlurredPlaceholder size to 32x32
- [ ] Update corner radius from 6 to 4
- [ ] Change grid columns from 4 to 5 in VideoBackgroundSidebarView
- [ ] Change grid columns from 4 to 5 in AnnotateSidebarView
- [ ] Visual verification in both sidebars

## Success Criteria
- Gradient buttons appear at 32x32px
- 5 gradient presets per row
- No overflow or clipping in 320px sidebar
- Visual consistency with CompactColorSwatchGrid (28px circles, 5 columns)
- Both AnnotateSidebarView and VideoBackgroundSidebarView updated

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Layout overflow | Low | Low | Test at minimum sidebar width |
| Touch target too small | Low | Low | 32px still meets HIG minimum |

## Security Considerations
None - UI changes only.

## Next Steps
After approval, implement changes in order:
1. AnnotateSidebarComponents.swift (shared components first)
2. VideoBackgroundSidebarView.swift
3. AnnotateSidebarView.swift
4. Visual testing
