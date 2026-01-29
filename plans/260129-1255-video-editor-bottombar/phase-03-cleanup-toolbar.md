# Phase 03: Cleanup VideoEditorToolbarView

## Context
- Parent: [plan.md](plan.md)
- Dependencies: [Phase 02](phase-02-integrate-mainview.md)

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

## Description
Remove Save button and onSave parameter from toolbar view.

## Key Insights
- Save button currently at lines 174-180 in rightSection
- onSave param used only for Save button
- Keep "Unsaved changes" indicator (optional per requirements)

## Requirements
1. Remove `onSave` parameter from struct
2. Remove Save button from rightSection
3. Keep unsaved indicator if desired
4. Update Preview

## Related Code Files
- Target: [VideoEditorToolbarView.swift](../../ClaudeShot/Features/VideoEditor/Views/VideoEditorToolbarView.swift)

## Implementation Steps

### Step 1: Remove onSave parameter
```swift
struct VideoEditorToolbarView: View {
  @ObservedObject var state: VideoEditorState
  // REMOVE: var onSave: () -> Void
```

### Step 2: Update rightSection
Remove lines 174-180 (Save button):
```swift
// REMOVE:
// Button(action: onSave) {
//   Text("Save")
// }
// .buttonStyle(.borderedProminent)
// .keyboardShortcut("s", modifiers: [.command])
// .disabled(!state.hasUnsavedChanges)
```

### Step 3: Update Preview
```swift
#Preview {
  VideoEditorToolbarView(
    state: VideoEditorState(url: URL(fileURLWithPath: "/tmp/test-video.mov"))
    // REMOVE: onSave: {}
  )
  ...
}
```

## Todo List
- [ ] Remove onSave parameter
- [ ] Remove Save button from rightSection
- [ ] Keep Unsaved indicator (lines 163-172)
- [ ] Update #Preview
- [ ] Verify no compile errors

## Success Criteria
- [ ] Toolbar renders without Save button
- [ ] Unsaved indicator still visible when applicable
- [ ] No compilation errors
- [ ] Preview works

## Risk Assessment
- Low - removal only

## Security Considerations
- None
