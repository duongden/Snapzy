# Codebase Analysis Report

**Date:** 2026-01-25
**Task:** Add Delete and Restart buttons to RecordingStatusBarView

## Current Implementation

### RecordingStatusBarView.swift
- Location: `ClaudeShot/Features/Recording/RecordingStatusBarView.swift`
- Current structure: HStack with recording indicator, timer, pause/resume button, stop button
- Uses `ToolbarIconButton` for pause/resume
- Uses `RecordingToolbarDivider` for visual separation
- Accepts `recorder: ScreenRecordingManager` and `onStop: () -> Void`

### ToolbarIconButton Component
- Location: `ClaudeShot/Features/Recording/Components/ToolbarIconButton.swift`
- Reusable icon button with hover state
- Parameters: `systemName`, `action`, `accessibilityLabel`
- Uses `ToolbarConstants` for sizing

### RecordingToolbarDivider
- Location: `ClaudeShot/Features/Recording/Styles/RecordingToolbarStyles.swift`
- Simple divider with fixed height from `ToolbarConstants.dividerHeight`

### Call Sites
1. `RecordingToolbarWindow.swift` (line 116-118) - calls `showRecordingStatusBar(recorder:)`
   - Only passes `recorder` and `onStop`
   - Window has `onStop` callback property

## Required Changes

### RecordingStatusBarView.swift
- Add `onDelete: () -> Void` parameter
- Add `onRestart: () -> Void` parameter
- Add delete button using ToolbarIconButton (icon: "trash")
- Add restart button using ToolbarIconButton (icon: "arrow.counterclockwise")
- Add dividers between new buttons

### RecordingToolbarWindow.swift
- Add `onDelete` and `onRestart` callback properties
- Update `showRecordingStatusBar` to pass new callbacks

## Button Order (Left to Right)
1. Recording indicator (red dot)
2. Timer display
3. Divider
4. Pause/Resume button
5. Divider
6. Delete button (NEW)
7. Divider
8. Restart button (NEW)
9. Divider
10. Stop button
