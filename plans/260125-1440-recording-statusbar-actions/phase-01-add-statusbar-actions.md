# Phase 01: Add StatusBar Actions

## Context Links

- [Plan Overview](./plan.md)
- [Codebase Analysis](./reports/01-codebase-analysis.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-25 |
| Description | Add Delete and Restart buttons to RecordingStatusBarView |
| Priority | Medium |
| Status | Pending |

## Key Insights

1. `ToolbarIconButton` already handles hover states and accessibility
2. `RecordingToolbarDivider` provides consistent visual separation
3. Only 1 call site to update: `RecordingToolbarWindow.showRecordingStatusBar`
4. Follow existing pattern: pause button uses ToolbarIconButton, stop uses custom style

## Requirements

### Delete Button
- Icon: `trash` (or `trash.fill` for consistency)
- Position: After pause/resume, before restart
- Callback: `onDelete: () -> Void`
- Accessibility label: "Delete recording"

### Restart Button
- Icon: `arrow.counterclockwise`
- Position: After delete, before stop
- Callback: `onRestart: () -> Void`
- Accessibility label: "Restart recording"

## Architecture

```
RecordingStatusBarView
├── HStack
│   ├── Recording indicator (red dot)
│   ├── Timer display
│   ├── Divider
│   ├── Pause/Resume button (ToolbarIconButton)
│   ├── Divider
│   ├── Delete button (ToolbarIconButton) ← NEW
│   ├── Divider ← NEW
│   ├── Restart button (ToolbarIconButton) ← NEW
│   ├── Divider
│   └── Stop button (StopButtonStyle)
```

## Related Code Files

| File | Purpose | Action |
|------|---------|--------|
| `ClaudeShot/Features/Recording/RecordingStatusBarView.swift` | Main view | Modify |
| `ClaudeShot/Features/Recording/RecordingToolbarWindow.swift` | Call site | Modify |
| `ClaudeShot/Features/Recording/Components/ToolbarIconButton.swift` | Button component | Reference |
| `ClaudeShot/Features/Recording/Styles/RecordingToolbarStyles.swift` | Divider, constants | Reference |

## Implementation Steps

### Step 1: Update RecordingStatusBarView

```swift
// Add new callbacks to struct
let onDelete: () -> Void
let onRestart: () -> Void

// Add buttons in body after pause/resume divider:
RecordingToolbarDivider()

ToolbarIconButton(
  systemName: "trash",
  action: onDelete,
  accessibilityLabel: "Delete recording"
)

RecordingToolbarDivider()

ToolbarIconButton(
  systemName: "arrow.counterclockwise",
  action: onRestart,
  accessibilityLabel: "Restart recording"
)

RecordingToolbarDivider()
// ... existing stop button
```

### Step 2: Update Preview

```swift
#Preview {
  RecordingStatusBarView(
    recorder: ScreenRecordingManager.shared,
    onDelete: {},
    onRestart: {},
    onStop: {}
  )
  .padding()
}
```

### Step 3: Update RecordingToolbarWindow

```swift
// Add callback properties
var onDelete: (() -> Void)?
var onRestart: (() -> Void)?

// Update showRecordingStatusBar method
func showRecordingStatusBar(recorder: ScreenRecordingManager) {
  mode = .recording
  let view = RecordingStatusBarView(
    recorder: recorder,
    onDelete: { [weak self] in self?.onDelete?() },
    onRestart: { [weak self] in self?.onRestart?() },
    onStop: { [weak self] in self?.onStop?() }
  )
  setContent(AnyView(view))
  positionBelowRect(anchorRect)
}
```

## Todo List

- [ ] Add `onDelete` and `onRestart` properties to RecordingStatusBarView
- [ ] Add Delete button using ToolbarIconButton
- [ ] Add Restart button using ToolbarIconButton
- [ ] Add dividers between buttons
- [ ] Update Preview with new callbacks
- [ ] Add callback properties to RecordingToolbarWindow
- [ ] Update showRecordingStatusBar to pass callbacks
- [ ] Test UI renders correctly
- [ ] Test button actions trigger callbacks

## Success Criteria

1. Delete and Restart buttons visible in status bar during recording
2. Buttons match existing ToolbarIconButton styling (hover state, size)
3. Accessibility labels present for VoiceOver
4. Callbacks properly forwarded from window to view
5. Build succeeds without warnings

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Button overflow on small screens | Low | Low | StatusBar already has horizontal padding |
| Accidental delete clicks | Medium | Medium | Consider confirmation dialog (future enhancement) |

## Security Considerations

- No sensitive data handling
- Callbacks are closure-based, no external dependencies

## Next Steps

After implementation:
1. Wire up actual delete/restart logic in calling code
2. Consider adding confirmation dialog for delete action
3. Add keyboard shortcuts if needed (Cmd+Delete, Cmd+R)

## Unresolved Questions

1. Should delete require confirmation dialog? (Recommend: yes, but implement in parent)
2. Should buttons be disabled during certain states (e.g., paused)? (Recommend: no, keep always enabled)
