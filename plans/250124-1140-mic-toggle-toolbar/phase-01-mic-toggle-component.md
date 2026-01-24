# Phase 01: Create ToolbarMicToggleButton Component

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** `ToolbarIconButton.swift`, `RecordingToolbarStyles.swift`

## Overview

| Field | Value |
|-------|-------|
| Date | 2025-01-24 |
| Description | Create reusable mic toggle button component |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

## Key Insights

- Existing `ToolbarIconButton` is action-only, not toggle-aware
- Need similar component but with state-based icon switching
- Use `ToolbarConstants` for consistent sizing/styling
- SF Symbols: `mic.fill` (on), `mic.slash.fill` (off)

## Requirements

1. Toggle button component with `@Binding var isOn: Bool`
2. Icon changes based on state
3. Hover effect matching `ToolbarIconButton`
4. Accessibility labels for both states
5. Optional: subtle visual distinction for muted state

## Architecture

```
ToolbarMicToggleButton
├── @Binding isOn: Bool
├── @State isHovered: Bool
├── Computed: systemName (mic.fill / mic.slash.fill)
├── Computed: accessibilityLabel
└── Button with state-aware icon
```

## Related Code Files

| File | Purpose |
|------|---------|
| `Components/ToolbarIconButton.swift` | Reference pattern |
| `Styles/RecordingToolbarStyles.swift` | ToolbarConstants |

## Implementation Steps

### Step 1: Create file structure
```swift
// ToolbarMicToggleButton.swift
// ClaudeShot
//
// Toggle button for microphone mute/unmute in recording toolbar
```

### Step 2: Implement component
```swift
struct ToolbarMicToggleButton: View {
  @Binding var isOn: Bool
  @State private var isHovered = false

  private var systemName: String {
    isOn ? "mic.fill" : "mic.slash.fill"
  }

  private var accessibilityLabel: String {
    isOn ? "Mute microphone" : "Unmute microphone"
  }

  var body: some View {
    Button { isOn.toggle() } label: {
      Image(systemName: systemName)
        .font(.system(size: ToolbarConstants.iconSize, weight: .medium))
        .foregroundColor(isOn ? .primary : .secondary)
        .frame(width: ToolbarConstants.iconButtonSize,
               height: ToolbarConstants.iconButtonSize)
        .background(
          RoundedRectangle(cornerRadius: ToolbarConstants.buttonCornerRadius)
            .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
        )
        .animation(ToolbarConstants.hoverAnimation, value: isHovered)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .accessibilityLabel(accessibilityLabel)
  }
}
```

### Step 3: Add preview
```swift
#Preview {
  HStack(spacing: 16) {
    ToolbarMicToggleButton(isOn: .constant(true))
    ToolbarMicToggleButton(isOn: .constant(false))
  }
  .padding()
  .background(.ultraThinMaterial)
}
```

## Todo List

- [ ] Create `ToolbarMicToggleButton.swift` in Components folder
- [ ] Implement toggle logic with binding
- [ ] Add hover state animation
- [ ] Add accessibility labels
- [ ] Add SwiftUI preview
- [ ] Test in Xcode preview

## Success Criteria

- [ ] Component compiles without errors
- [ ] Icon switches between `mic.fill` and `mic.slash.fill`
- [ ] Hover effect works
- [ ] Preview shows both states

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| None | - | - | Simple component |

## Security Considerations

- None (UI-only component)

## Next Steps

→ Proceed to [Phase 02: Toolbar Integration](./phase-02-toolbar-integration.md)
