# Phase 02: Integrate into RecordingToolbarView

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 01 (ToolbarMicToggleButton)

## Overview

| Field | Value |
|-------|-------|
| Date | 2025-01-24 |
| Description | Add mic toggle to toolbar layout |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

## Key Insights

- `RecordingToolbarView` already has `@Binding var captureAudio: Bool`
- Just need to add button to HStack layout
- Position: between Options menu and Record button

## Requirements

1. Add `ToolbarMicToggleButton` to toolbar
2. Bind to existing `captureAudio` property
3. Maintain visual consistency with toolbar layout

## Architecture

```
RecordingToolbarView HStack:
├── ToolbarIconButton (close)
├── RecordingToolbarDivider
├── ToolbarOptionsMenu
├── ToolbarMicToggleButton (NEW) ← Add here
├── RecordingToolbarDivider (optional)
├── Record Button
```

## Related Code Files

| File | Purpose |
|------|---------|
| `RecordingToolbarView.swift` | Main toolbar view to edit |
| `ToolbarMicToggleButton.swift` | New component from Phase 01 |

## Implementation Steps

### Step 1: Update RecordingToolbarView.swift

Add mic toggle between Options and Record:

```swift
var body: some View {
  HStack(spacing: ToolbarConstants.itemSpacing) {
    // Close button
    ToolbarIconButton(
      systemName: "xmark",
      action: onCancel,
      accessibilityLabel: "Cancel recording"
    )

    RecordingToolbarDivider()

    // Options menu
    ToolbarOptionsMenu(
      selectedFormat: $selectedFormat,
      selectedQuality: $selectedQuality,
      captureAudio: $captureAudio
    )

    // NEW: Mic toggle button
    ToolbarMicToggleButton(isOn: $captureAudio)

    RecordingToolbarDivider()

    // Record button
    Button(action: onRecord) {
      HStack(spacing: 6) {
        Image(systemName: "record.circle.fill")
        Text("Record")
      }
    }
    .buttonStyle(RecordButtonStyle())
    // ... rest unchanged
  }
  // ... rest unchanged
}
```

### Step 2: Update Preview

Ensure preview still works with existing bindings (no changes needed).

## Todo List

- [ ] Import/reference ToolbarMicToggleButton
- [ ] Add button to HStack after ToolbarOptionsMenu
- [ ] Bind to `$captureAudio`
- [ ] Test in Xcode preview
- [ ] Build and verify no errors

## Success Criteria

- [ ] Mic toggle visible in toolbar
- [ ] Clicking toggles `captureAudio` state
- [ ] Options menu audio toggle stays in sync
- [ ] Layout looks balanced
- [ ] No build errors

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Layout too wide | Low | Low | Adjust spacing if needed |

## Security Considerations

- None (UI-only change)

## Next Steps

→ Implementation complete after this phase
→ Manual testing recommended
