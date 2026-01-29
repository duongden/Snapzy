# Phase 01: Simplify VideoExportSettingsPanel

## Context
- **Parent Plan**: [plan.md](plan.md)
- **Dependencies**: None

## Overview
- **Date**: 2026-01-29
- **Description**: Remove collapse wrapper, display settings inline
- **Priority**: High
- **Implementation Status**: ⬜ Pending
- **Review Status**: ⬜ Pending

## Key Insights
- Panel currently wraps content in collapsible VStack with toggle header
- `panelContent` contains all actual settings UI - this should become main body
- Header (lines 32-60) adds unnecessary interaction step
- Animation/transition code tied to collapse behavior

## Requirements
1. Remove `panelHeader` toggle button entirely
2. Remove conditional `if state.isExportPanelExpanded` check
3. Remove collapse-related animations
4. Keep `panelContent` as primary view body
5. Update file comments to reflect non-collapsible nature

## Architecture
No architectural changes. Simple view simplification.

## Related Code Files
| File | Purpose |
|------|---------|
| [VideoExportSettingsPanel.swift](../../ClaudeShot/Features/VideoEditor/Views/VideoExportSettingsPanel.swift) | Target file |
| [VideoEditorMainView.swift](../../ClaudeShot/Features/VideoEditor/Views/VideoEditorMainView.swift) | Parent view (line 63) |

## Implementation Steps

### Step 1: Update file header comment
```swift
// Before: "Collapsible export settings panel for video editor"
// After: "Export settings panel for video editor"
```

### Step 2: Update struct documentation
```swift
// Before: "Collapsible panel for export settings below timeline"
// After: "Export settings panel displayed below timeline"
```

### Step 3: Simplify body view
Replace current body (lines 14-28):
```swift
var body: some View {
  VStack(spacing: 0) {
    panelHeader
    if state.isExportPanelExpanded {
      Divider()
      panelContent
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
  }
  .cornerRadius(8)
  .animation(.easeInOut(duration: 0.2), value: state.isExportPanelExpanded)
}
```

With simplified version:
```swift
var body: some View {
  panelContent
}
```

### Step 4: Remove panelHeader
Delete lines 30-60 (entire `panelHeader` computed property)

### Step 5: Inline panelContent
Convert `panelContent` from private computed property to main body, or keep as-is for readability.

## Todo List
- [ ] Update file header comment
- [ ] Update struct documentation
- [ ] Simplify body to show `panelContent` directly
- [ ] Remove `panelHeader` computed property
- [ ] Test all export options work correctly
- [ ] Verify file size estimate displays

## Success Criteria
- Export settings visible immediately without toggle
- Quality, Dimensions, Audio sections functional
- Estimated file size displays correctly
- No visual regression in settings layout

## Risk Assessment
- **Risk**: Low - UI simplification only
- **Mitigation**: Keep `panelContent` structure intact

## Security Considerations
None - UI-only change

## Next Steps
Proceed to [Phase 02](phase-02-cleanup-state.md) to remove unused state properties
