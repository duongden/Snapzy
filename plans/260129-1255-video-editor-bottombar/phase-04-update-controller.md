# Phase 04: Update VideoEditorWindowController

## Context
- Parent: [plan.md](plan.md)
- Dependencies: [Phase 02](phase-02-integrate-mainview.md), [Phase 03](phase-03-cleanup-toolbar.md)

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

## Description
Wire up the new onCancel callback in VideoEditorWindowController.

## Key Insights
- Controller already has `handleCancel()` method at lines 293-301
- Method checks for unsaved changes before closing
- Just need to pass this as onCancel to MainView

## Requirements
1. Update setupContent() to pass onCancel
2. Use existing handleCancel() method

## Related Code Files
- Target: [VideoEditorWindowController.swift](../../ClaudeShot/Features/VideoEditor/VideoEditorWindowController.swift)

## Implementation Steps

### Step 1: Update setupContent method
Change lines 93-97:

```swift
private func setupContent() {
  guard let state = state else {
    setupEmptyContent()
    return
  }

  let mainView = VideoEditorMainView(
    state: state,
    onSave: { [weak self] in self?.showSaveConfirmation() },
    onCancel: { [weak self] in self?.handleCancel() }  // NEW
  )
  window?.contentView = NSHostingView(rootView: mainView)
}
```

## Todo List
- [ ] Add onCancel callback to VideoEditorMainView init
- [ ] Pass handleCancel() as onCancel
- [ ] Test cancel flow with unsaved changes
- [ ] Test cancel flow without unsaved changes

## Success Criteria
- [ ] Cancel button closes window when no unsaved changes
- [ ] Cancel button shows unsaved alert when changes exist
- [ ] All existing save/export functionality works

## Risk Assessment
- Low - using existing handleCancel method

## Security Considerations
- None

## Next Steps
After all phases complete:
1. Build and test
2. Verify keyboard shortcut ⌘S works for Convert
3. Test Cancel with/without unsaved changes
4. Visual review of bottom bar styling
