# Phase 02: Redesign ZoomSettingsPopover Sidebar

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** [Phase 01](./phase-01-zoom-colors-refactor.md)
- **Related Docs:** VideoEditorToolbarView.swift (styling reference)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Description | Redesign sidebar panel with macOS-native styling, better hierarchy, refined controls |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Not Started |

## Key Insights

1. Current uses hardcoded `.purple` and `.opacity(0.2)` backgrounds
2. Toolbar uses `Color.white.opacity(0.1)` - should match
3. Font sizes (9-12pt) are appropriate but need better weight hierarchy
4. Quick presets could use Picker with `.segmented` style for native feel

## Requirements

- Replace all `.purple` with `ZoomColors.primary` (system accent)
- Use `Color.white.opacity(0.1)` for button backgrounds (match toolbar)
- Improve visual hierarchy with consistent spacing
- Native-looking preset buttons

## Architecture

### Header Section
```swift
// BEFORE
Image(systemName: "plus.magnifyingglass")
  .foregroundColor(.purple)

// AFTER
Image(systemName: "plus.magnifyingglass")
  .foregroundColor(ZoomColors.primary)
```

### Preset Buttons
```swift
// BEFORE
.background(localZoomLevel == level ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2))

// AFTER
.background(localZoomLevel == level ? ZoomColors.primary.opacity(0.3) : Color.white.opacity(0.1))
```

### Type Badge
```swift
// BEFORE
.background(Color.purple.opacity(0.2))

// AFTER
.background(ZoomColors.primary.opacity(0.2))
```

## Related Code Files

| File | Lines | Purpose |
|------|-------|---------|
| `ZoomSettingsPopover.swift:55-74` | Header section |
| `ZoomSettingsPopover.swift:76-132` | Zoom level section |
| `ZoomSettingsPopover.swift:134-170` | Center picker section |
| `ZoomSettingsPopover.swift:172-209` | Actions section |

## Implementation Steps

1. **Header (lines 55-74)**
   - Replace `.purple` with `ZoomColors.primary`
   - Replace badge `.purple.opacity(0.2)` with `ZoomColors.primary.opacity(0.2)`

2. **Zoom Level Section (lines 76-132)**
   - Update preset button backgrounds to use `Color.white.opacity(0.1)`
   - Selected state uses `ZoomColors.primary.opacity(0.3)`

3. **Center Picker Section (lines 134-170)**
   - Update position preset backgrounds same as zoom presets
   - Replace `.purple.opacity(0.3)` with `ZoomColors.primary.opacity(0.3)`

4. **Actions Section (lines 172-209)**
   - Update enable/disable button background to `Color.white.opacity(0.1)`
   - Keep delete button red styling (semantic meaning)

## Todo List

- [ ] Replace header icon `.purple` → `ZoomColors.primary`
- [ ] Replace badge background `.purple.opacity(0.2)` → `ZoomColors.primary.opacity(0.2)`
- [ ] Update zoom preset buttons: selected `ZoomColors.primary.opacity(0.3)`, unselected `Color.white.opacity(0.1)`
- [ ] Update center position presets same pattern
- [ ] Update enable/disable button background
- [ ] Verify consistent 6pt corner radius throughout

## Success Criteria

- [ ] No hardcoded `.purple` references
- [ ] Consistent with toolbar button styling
- [ ] Respects user's system accent color
- [ ] Clean visual hierarchy

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Inconsistent opacity values | Medium | Low | Use constants |
| Poor contrast in light mode | Low | Medium | Test both modes |

## Security Considerations

None - UI only changes.

## Next Steps

Proceed to Phase 03: ZoomBlockView polish
