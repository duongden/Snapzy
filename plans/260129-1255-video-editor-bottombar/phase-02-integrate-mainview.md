# Phase 02: Integrate with VideoEditorMainView

## Context
- Parent: [plan.md](plan.md)
- Dependencies: [Phase 01](phase-01-create-bottombar.md)

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

## Description
Add VideoEditorBottomBar to VideoEditorMainView and add onCancel callback.

## Key Insights
- Current structure: VStack with toolbar, divider, content, spacer
- Bottom bar goes after Spacer, before closing VStack brace
- Need to add `onCancel` callback prop to view

## Requirements
1. Add `onCancel` callback property
2. Place bottom bar at end of main VStack
3. Pass `onSave` as `onConvert` callback
4. Add Divider above bottom bar

## Related Code Files
- Target: [VideoEditorMainView.swift](../../ClaudeShot/Features/VideoEditor/Views/VideoEditorMainView.swift)

## Implementation Steps

### Step 1: Add onCancel property
```swift
struct VideoEditorMainView: View {
  @ObservedObject var state: VideoEditorState
  var onSave: (() -> Void)?
  var onCancel: (() -> Void)?  // NEW
```

### Step 2: Add bottom bar to VStack
After line 70 (`Spacer(minLength: 0)`), before closing brace:

```swift
Spacer(minLength: 0)

Divider()

// Bottom bar with Cancel/Convert
VideoEditorBottomBar(
  onCancel: { onCancel?() },
  onConvert: { onSave?() }
)
```

### Step 3: Remove onSave from toolbar
Update line 30-33:
```swift
VideoEditorToolbarView(state: state)
```

## Todo List
- [ ] Add `onCancel` callback property
- [ ] Add Divider before bottom bar
- [ ] Add VideoEditorBottomBar component
- [ ] Wire onConvert to existing onSave
- [ ] Wire onCancel to new callback
- [ ] Remove onSave from toolbar call

## Success Criteria
- [ ] Bottom bar visible at bottom of editor
- [ ] Cancel triggers onCancel callback
- [ ] Convert triggers onSave callback
- [ ] No compilation errors

## Risk Assessment
- Low - straightforward view composition

## Security Considerations
- None
