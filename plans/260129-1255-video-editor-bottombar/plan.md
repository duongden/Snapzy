# Video Editor Bottom Bar Implementation

## Overview
Move "Save" button from top toolbar to new bottom bar component. Rename to "Convert" and add "Cancel" button.

## Status
| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Create VideoEditorBottomBar component | ⬜ Pending |
| 02 | Update VideoEditorMainView integration | ⬜ Pending |
| 03 | Update VideoEditorToolbarView cleanup | ⬜ Pending |
| 04 | Update VideoEditorWindowController | ⬜ Pending |

## Key Changes
- **New file**: `VideoEditorBottomBar.swift` - Bottom bar with Cancel/Convert buttons
- **Modified**: `VideoEditorMainView.swift` - Add bottom bar, new `onCancel` callback
- **Modified**: `VideoEditorToolbarView.swift` - Remove Save button and `onSave` param
- **Modified**: `VideoEditorWindowController.swift` - Wire up `onCancel` callback

## Architecture
```
VideoEditorWindowController
    └── VideoEditorMainView
            ├── VideoEditorToolbarView (top - no save button)
            ├── Content Area (sidebars + player + timeline)
            └── VideoEditorBottomBar (new - Cancel left, Convert right)
```

## Phase Files
- [Phase 01: Create Bottom Bar Component](phase-01-create-bottombar.md)
- [Phase 02: Integrate with Main View](phase-02-integrate-mainview.md)
- [Phase 03: Cleanup Toolbar](phase-03-cleanup-toolbar.md)
- [Phase 04: Update Controller](phase-04-update-controller.md)

## Requirements Summary
1. Cancel button: left side, secondary style
2. Convert button: right side, primary style, **always enabled**
3. Maintain ⌘S keyboard shortcut for Convert
4. Consistent spacing using `WindowSpacingConfiguration`
