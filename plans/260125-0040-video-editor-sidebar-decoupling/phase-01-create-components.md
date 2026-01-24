# Phase 01: Create VideoEditor Sidebar Components

## Context
- **Parent Plan**: [plan.md](./plan.md)
- **Dependencies**: None

## Overview
- **Date**: 2026-01-25
- **Description**: Create dedicated sidebar components for VideoEditor, decoupled from Annotate
- **Priority**: Medium
- **Implementation Status**: Pending
- **Review Status**: Awaiting approval

## Key Insights
1. VideoBackgroundSidebarView uses 4 shared components from Annotate feature
2. Components need "Video" prefix to avoid naming conflicts
3. Can customize sizing independently (currently Annotate uses 44x44, Video can use 32x32)

## Requirements
- Create VideoEditorSidebarComponents.swift with:
  - VideoSidebarSectionHeader
  - VideoGradientPresetButton (32x32, cornerRadius 4)
  - VideoColorSwatchGrid (28x28, 5 columns, spacing 4)
  - VideoSliderRow
- Update VideoBackgroundSidebarView to use new components
- Standardize spacing: 4px horizontal and vertical for all grids

## Architecture
No architectural changes. Simple component duplication with renaming.

## Related Code Files

| File | Purpose | Action |
|------|---------|--------|
| `ClaudeShot/Features/VideoEditor/Views/VideoEditorSidebarComponents.swift` | New components | Create |
| `ClaudeShot/Features/VideoEditor/Views/VideoBackgroundSidebarView.swift` | Sidebar view | Update imports |

## Implementation Steps

### Step 1: Create VideoEditorSidebarComponents.swift
**Path**: `ClaudeShot/Features/VideoEditor/Views/VideoEditorSidebarComponents.swift`

Create file with:
```swift
// VideoSidebarSectionHeader - copy from AnnotateSidebarComponents.swift:12-21
// VideoGradientPresetButton - copy from AnnotateSidebarComponents.swift:25-42, change to 32x32
// VideoColorSwatchGrid - copy from AnnotateSidebarView.swift:168-193
// VideoSliderRow - copy from AnnotateSidebarView.swift:195-215
```

### Step 2: Update VideoBackgroundSidebarView.swift
Replace component references:
- `SidebarSectionHeader` → `VideoSidebarSectionHeader`
- `GradientPresetButton` → `VideoGradientPresetButton`
- `CompactColorSwatchGrid` → `VideoColorSwatchGrid`
- `CompactSliderRow` → `VideoSliderRow`

## Todo List
- [ ] Create VideoEditorSidebarComponents.swift
- [ ] Add VideoSidebarSectionHeader
- [ ] Add VideoGradientPresetButton (32x32, cornerRadius 4)
- [ ] Add VideoColorSwatchGrid
- [ ] Add VideoSliderRow
- [ ] Update VideoBackgroundSidebarView to use new components
- [ ] Build and verify

## Success Criteria
- VideoEditorSidebarComponents.swift exists with 4 components
- VideoBackgroundSidebarView compiles using local components
- Annotate sidebar unchanged and working
- Build succeeds

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Naming conflict | Low | Low | Use "Video" prefix |
| Missing component | Low | Medium | Verify all 4 copied |

## Security Considerations
None - UI refactoring only.

## Next Steps
After implementation:
1. Verify build
2. Test both VideoEditor and Annotate sidebars
3. Confirm visual consistency
