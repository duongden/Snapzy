# Phase 2: Sidebar UI Components

**Parent:** [plan.md](./plan.md)
**Dependencies:** [Phase 1](./phase-01-state-management.md)
**Date:** 2026-01-24
**Priority:** High
**Status:** Pending
**Review:** Not Started

## Overview

Create `VideoBackgroundSidebarView` with background customization controls, reusing UI components from Annotate sidebar.

## Key Insights

- `AnnotateSidebarView.swift` provides complete reference implementation
- Reusable components exist in `AnnotateSidebarComponents.swift`:
  - `SidebarSectionHeader`
  - `GradientPresetButton`
  - `CompactSliderRow` (in AnnotateSidebarView)
  - `AlignmentGrid`
- Keep sidebar width consistent (280px like VideoDetailsSidebarView)

## Requirements

1. Create VideoBackgroundSidebarView with all background controls
2. Integrate into VideoEditorMainView layout
3. Add toolbar toggle button for sidebar visibility
4. Match visual style of existing sidebars

## Related Files

| File | Action |
|------|--------|
| `ClaudeShot/Features/Annotate/Views/AnnotateSidebarView.swift` | Reference |
| `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift` | Reference (reuse) |
| `ClaudeShot/Features/VideoEditor/Views/VideoBackgroundSidebarView.swift` | Create |
| `ClaudeShot/Features/VideoEditor/Views/VideoEditorMainView.swift` | Modify |
| `ClaudeShot/Features/VideoEditor/Views/VideoEditorToolbarView.swift` | Modify |

## Architecture

```
VideoBackgroundSidebarView
├── ScrollView
│   ├── None Button (reset background)
│   ├── Gradients Section (GradientPresetButton grid)
│   ├── Colors Section (CompactColorSwatchGrid)
│   ├── Divider
│   ├── Sliders Section
│   │   ├── Padding (0-100)
│   │   ├── Shadow (0-1)
│   │   └── Corners (0-32)
│   ├── Alignment Section (AlignmentGrid)
│   └── Ratio Section (Picker)
└── Background: controlBackgroundColor
```

## Implementation Steps

### Step 1: Create VideoBackgroundSidebarView.swift

```swift
struct VideoBackgroundSidebarView: View {
  @ObservedObject var state: VideoEditorState

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 12) {
        // Header
        HStack {
          Image(systemName: "rectangle.on.rectangle")
            .foregroundColor(ZoomColors.primary)
          Text("Background")
            .font(.system(size: 13, weight: .semibold))
        }

        Divider()

        noneButton
        gradientSection
        colorSection

        Divider()

        slidersSection
        alignmentSection
        ratioSection

        Spacer(minLength: 20)
      }
      .padding(12)
    }
    .frame(maxHeight: .infinity)
    .background(Color(NSColor.controlBackgroundColor))
  }
}
```

### Step 2: Implement Section Views

Mirror structure from AnnotateSidebarView with bindings to VideoEditorState.

### Step 3: Update VideoEditorMainView

Add conditional sidebar display:
```swift
if state.isBackgroundSidebarVisible {
  VideoBackgroundSidebarView(state: state)
    .frame(width: 280)
  Divider()
}
```

### Step 4: Add Toolbar Toggle

Add button in VideoEditorToolbarView to toggle background sidebar.

## Todo List

- [ ] Create VideoBackgroundSidebarView.swift
- [ ] Implement noneButton view
- [ ] Implement gradientSection with GradientPresetButton grid
- [ ] Implement colorSection with CompactColorSwatchGrid
- [ ] Implement slidersSection (padding, shadow, corners)
- [ ] Implement alignmentSection with AlignmentGrid
- [ ] Implement ratioSection with Picker
- [ ] Add sidebar to VideoEditorMainView HStack
- [ ] Add toggle button in VideoEditorToolbarView
- [ ] Add keyboard shortcut (Cmd+B for background)

## Success Criteria

- [ ] Sidebar renders without errors
- [ ] All controls update state correctly
- [ ] Toggle button shows/hides sidebar
- [ ] Visual consistency with VideoDetailsSidebarView
- [ ] Auto-apply default background when padding > 0

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Component import issues | Low | Medium | Components in same target |
| Layout conflicts with existing sidebars | Medium | Low | Test all sidebar combinations |

## Security Considerations

None - UI components with no external I/O.

## Next Steps

After completion, proceed to [Phase 3: Preview Integration](./phase-03-preview-integration.md)
