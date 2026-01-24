# Phase 1: State Management

**Parent:** [plan.md](./plan.md)
**Date:** 2026-01-24
**Priority:** High
**Status:** Pending
**Review:** Not Started

## Overview

Extend `VideoEditorState` with background styling properties, reusing existing types from Annotate feature.

## Key Insights

- `BackgroundStyle`, `GradientPreset`, `ImageAlignment`, `AspectRatioOption` already exist in `Annotate/Background/BackgroundStyle.swift`
- VideoEditorState already has change tracking via Combine publishers
- Need to add undo/redo support for background changes

## Requirements

1. Add background-related `@Published` properties to VideoEditorState
2. Track initial values for unsaved changes detection
3. Add undo/redo actions for background changes
4. Default to `.none` background style

## Related Files

| File | Action |
|------|--------|
| `ClaudeShot/Features/Annotate/Background/BackgroundStyle.swift` | Reference (no changes) |
| `ClaudeShot/Features/VideoEditor/State/VideoEditorState.swift` | Modify |

## Implementation Steps

### Step 1: Add Properties to VideoEditorState

```swift
// MARK: - Background Settings

@Published var backgroundStyle: BackgroundStyle = .none
@Published var backgroundPadding: CGFloat = 0
@Published var backgroundShadowIntensity: CGFloat = 0
@Published var backgroundCornerRadius: CGFloat = 0
@Published var backgroundAlignment: ImageAlignment = .center
@Published var backgroundAspectRatio: AspectRatioOption = .auto
@Published var isBackgroundSidebarVisible: Bool = false
```

### Step 2: Add Initial Value Tracking

```swift
// Add to private properties
private var initialBackgroundStyle: BackgroundStyle = .none
private var initialBackgroundPadding: CGFloat = 0
private var initialBackgroundShadowIntensity: CGFloat = 0
private var initialBackgroundCornerRadius: CGFloat = 0
```

### Step 3: Add Undo/Redo Actions

```swift
// Add to EditorAction enum
case updateBackground(
  oldStyle: BackgroundStyle, newStyle: BackgroundStyle,
  oldPadding: CGFloat, newPadding: CGFloat,
  oldShadow: CGFloat, newShadow: CGFloat,
  oldCorner: CGFloat, newCorner: CGFloat
)
```

### Step 4: Update Change Tracking

Add background properties to `setupChangeTracking()` publisher chain.

### Step 5: Add Toggle Method

```swift
func toggleBackgroundSidebar() {
  isBackgroundSidebarVisible.toggle()
}
```

## Todo List

- [ ] Add background properties to VideoEditorState
- [ ] Add initial value tracking variables
- [ ] Extend EditorAction enum with background action
- [ ] Update setupChangeTracking() for background changes
- [ ] Update updateHasUnsavedChanges() to include background
- [ ] Update markAsSaved() to snapshot background values
- [ ] Implement undo/redo for background action
- [ ] Add toggleBackgroundSidebar() method

## Success Criteria

- [ ] Background properties compile without errors
- [ ] Changes to background trigger `hasUnsavedChanges = true`
- [ ] Undo/redo works for background changes
- [ ] markAsSaved() resets background change detection

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| BackgroundStyle not accessible | Low | High | Import or move to Shared folder |
| Undo stack overflow | Low | Low | Already has maxUndoStackSize = 50 |

## Security Considerations

None - pure state management with no external I/O.

## Next Steps

After completion, proceed to [Phase 2: Sidebar UI Components](./phase-02-sidebar-ui-components.md)
