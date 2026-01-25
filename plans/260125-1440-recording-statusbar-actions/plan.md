# Recording StatusBar Actions Plan

**Created:** 2026-01-25
**Status:** Draft
**Priority:** Medium

## Overview

Add Delete and Restart buttons to RecordingStatusBarView for enhanced recording control.

## Scope

- Add 2 new action buttons to status bar
- Update view initializer with callbacks
- Update single call site in RecordingToolbarWindow

## Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Add StatusBar Actions | Pending |

## Files to Modify

1. `ClaudeShot/Features/Recording/RecordingStatusBarView.swift`
2. `ClaudeShot/Features/Recording/RecordingToolbarWindow.swift`

## Dependencies

- ToolbarIconButton component (exists)
- RecordingToolbarDivider component (exists)
- ToolbarConstants for styling (exists)

## Estimated Effort

- Implementation: ~30 minutes
- Testing: ~15 minutes

## Reports

- [01-codebase-analysis.md](./reports/01-codebase-analysis.md)

## Phase Details

- [phase-01-add-statusbar-actions.md](./phase-01-add-statusbar-actions.md)
