# Phase 4: UI Integration

**Date**: 2026-01-27
**Priority**: Medium
**Status**: Pending

## Context Links

- [Main Plan](./plan.md)
- Previous: [Phase 3 - Performance Optimization](./phase-03-performance-optimization.md)
- Next: [Phase 5 - Export Integration](./phase-05-export-integration.md)

## Overview

Add blur type picker to sidebar when blur tool is active. Follow existing section patterns from `AnnotateSidebarSections.swift`.

## Key Insights

- Sidebar sections follow consistent pattern: `SidebarSectionHeader` + content
- Conditional visibility based on `state.selectedTool`
- Use `Picker` or segmented control for type selection

## Requirements

1. Blur type picker visible only when blur tool selected
2. Match existing sidebar visual style
3. Instant preview update on type change

## Architecture

```swift
// New section in AnnotateSidebarSections.swift
struct SidebarBlurTypeSection: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SidebarSectionHeader(title: "Blur Type")
      Picker("", selection: $state.blurType) {
        ForEach(BlurType.allCases) { type in
          Label(type.displayName, systemImage: type.icon)
            .tag(type)
        }
      }
      .pickerStyle(.segmented)
    }
  }
}
```

## Related Code Files

| File | Changes |
|------|---------|
| `Views/AnnotateSidebarSections.swift` | Add `SidebarBlurTypeSection` |
| `Views/AnnotateSidebarView.swift` | Conditionally show blur section |

## Implementation Steps

### Step 1: Add SidebarBlurTypeSection
```swift
// In AnnotateSidebarSections.swift, add new section
struct SidebarBlurTypeSection: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SidebarSectionHeader(title: "Blur Type")

      Picker("", selection: $state.blurType) {
        ForEach(BlurType.allCases) { type in
          HStack {
            Image(systemName: type.icon)
            Text(type.displayName)
          }
          .tag(type)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
    }
  }
}
```

### Step 2: Add to sidebar view
```swift
// In AnnotateSidebarView.swift, add conditional section
if state.selectedTool == .blur {
  SidebarBlurTypeSection(state: state)
  Divider()
}
```

## Todo List

- [ ] Create `SidebarBlurTypeSection` view
- [ ] Add conditional rendering in sidebar
- [ ] Test picker updates state correctly
- [ ] Verify preview updates on change

## Success Criteria

- [x] Picker appears when blur tool selected
- [x] Picker hidden for other tools
- [x] Selection updates `state.blurType`
- [x] Visual style matches existing sections

## Next Steps

Proceed to [Phase 5](./phase-05-export-integration.md) for export integration.
