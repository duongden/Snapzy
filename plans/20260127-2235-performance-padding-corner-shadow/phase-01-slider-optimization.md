# Phase 01: Slider Debouncing & Local State

## Context
- Parent: [plan.md](plan.md)
- Dependencies: None

## Overview
- **Date:** 2026-01-27
- **Priority:** Critical
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
Current `SliderRow` uses direct `@Binding` to `AnnotateState`, causing:
1. Every slider tick fires `@Published` update
2. All views observing `AnnotateState` re-render
3. Canvas recalculates layout, shadows, corners ~60 times/second during drag

## Requirements
- Slider feels responsive during drag (no lag)
- Final value syncs to state only on drag end
- Visual preview updates smoothly during drag

## Architecture

### Current Flow (Problematic)
```
Slider drag → $state.padding → @Published fires →
All ObservedObject views re-render → Canvas recalcs → LAG
```

### Proposed Flow
```
Slider drag → @State localValue → lightweight preview update
Drag end → sync to state.padding → single re-render
```

## Related Code Files
- [AnnotateSidebarComponents.swift:214-229](../../ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift#L214-L229) - SliderRow
- [AnnotateSidebarSections.swift:198-215](../../ClaudeShot/Features/Annotate/Views/AnnotateSidebarSections.swift#L198-L215) - SidebarSlidersSection

## Implementation Steps

### Step 1: Create OptimizedSliderRow Component
Replace `SliderRow` with version using local state:

```swift
struct SliderRow: View {
  let label: String
  @Binding var value: CGFloat
  let range: ClosedRange<CGFloat>

  @State private var localValue: CGFloat = 0
  @State private var isDragging: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xs) {
      Text(label)
        .font(Typography.labelMedium)
        .foregroundColor(SidebarColors.labelSecondary)

      Slider(
        value: $localValue,
        in: range,
        onEditingChanged: { editing in
          isDragging = editing
          if !editing {
            // Sync to binding only when drag ends
            value = localValue
          }
        }
      )
      .controlSize(.small)
    }
    .onAppear { localValue = value }
    .onChange(of: value) { newValue in
      // External changes sync to local (e.g., preset selection)
      if !isDragging { localValue = newValue }
    }
  }
}
```

### Step 2: Add Preview Binding for Live Feedback
Create separate "preview" properties in AnnotateState for live visual feedback:

```swift
// In AnnotateState.swift - add preview properties
@Published var previewPadding: CGFloat?
@Published var previewCornerRadius: CGFloat?
@Published var previewShadowIntensity: CGFloat?

// Computed property for canvas to use
var effectivePadding: CGFloat { previewPadding ?? padding }
var effectiveCornerRadius: CGFloat { previewCornerRadius ?? cornerRadius }
var effectiveShadowIntensity: CGFloat { previewShadowIntensity ?? shadowIntensity }
```

### Step 3: Update Canvas to Use Effective Values
In `AnnotateCanvasView`, use `state.effectivePadding` etc instead of direct properties.

## Todo List
- [ ] Refactor SliderRow with local @State and onEditingChanged
- [ ] Add preview properties to AnnotateState
- [ ] Update AnnotateCanvasView to use effective* properties
- [ ] Test slider responsiveness

## Success Criteria
- Slider drag feels instant (no perceptible lag)
- Value changes apply on mouse release
- Visual feedback during drag is smooth

## Risk Assessment
- **Low Risk:** Changes isolated to slider component
- **Regression:** Ensure preset selections still update sliders

## Security Considerations
None - UI-only changes

## Next Steps
After completing, proceed to [Phase 02: Image Caching](phase-02-image-caching.md)
