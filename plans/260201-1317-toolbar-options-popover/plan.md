# Toolbar Options Popover Implementation

**Date:** 2026-02-01
**Status:** In Progress

## Overview

Replace the "Options" text menu in RecordingToolbarView with an icon button that opens a popover containing grouped recording settings.

## Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Create ToolbarOptionsPopover component | Pending |
| 2 | Update ToolbarOptionsMenu to use icon + popover | Pending |
| 3 | Add frame rate setting support | Pending |
| 4 | Testing & verification | Pending |

## Key Changes

1. **Icon Button**: Replace "Options" text with `gearshape` icon
2. **Popover UI**: Grouped settings (Format, Quality, Audio) in popover
3. **Frame Rate**: Add FPS setting to quick access in popover
4. **Consistent Styling**: Match existing toolbar component patterns

## Files to Modify

- `Snapzy/Features/Recording/Components/ToolbarOptionsMenu.swift` - Refactor to popover
- `Snapzy/Features/Recording/RecordingToolbarView.swift` - Add FPS binding
- `Snapzy/Features/Recording/RecordingToolbarWindow.swift` - Add FPS state

## Success Criteria

- Icon button replaces text "Options"
- Popover shows on tap with grouped settings
- Settings persist correctly via bindings
- Matches existing design language
