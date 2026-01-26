# Phase 1: Blur Type Model

**Date**: 2026-01-27
**Priority**: High
**Status**: Pending

## Context Links

- [Main Plan](./plan.md)
- Next: [Phase 2 - Gaussian Blur Renderer](./phase-02-gaussian-blur-renderer.md)

## Overview

Add `BlurType` enum and integrate into state/model layer. Foundation for blur type selection.

## Key Insights

- `AnnotationType.blur` currently has no associated data
- `AnnotateState` needs `blurType` property for tool state
- `AnnotationItem` must store blur type per annotation for export

## Requirements

1. Create `BlurType` enum with `.pixelated` and `.gaussian` cases
2. Add `blurType` property to `AnnotateState`
3. Update `AnnotationType.blur` to `blur(BlurType)`
4. Default to `.pixelated` for backward compatibility

## Architecture

```swift
// New enum in AnnotationItem.swift or separate file
enum BlurType: String, CaseIterable {
  case pixelated
  case gaussian

  var displayName: String {
    switch self {
    case .pixelated: return "Pixelated"
    case .gaussian: return "Gaussian"
    }
  }
}

// Update AnnotationType
enum AnnotationType: Equatable {
  // ... existing cases
  case blur(BlurType)  // was: case blur
}

// Update AnnotateState
@Published var blurType: BlurType = .pixelated
```

## Related Code Files

| File | Changes |
|------|---------|
| `State/AnnotationItem.swift` | Add `BlurType` enum, update `AnnotationType.blur` |
| `State/AnnotateState.swift` | Add `blurType: BlurType` property |
| `Canvas/AnnotationRenderer.swift` | Update blur case pattern matching |
| `Canvas/AnnotateCanvasView.swift` | Pass blurType when creating blur annotation |

## Implementation Steps

### Step 1: Add BlurType enum
```swift
// In AnnotationItem.swift, before AnnotationType
enum BlurType: String, CaseIterable, Identifiable {
  case pixelated
  case gaussian

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .pixelated: return "Pixelated"
    case .gaussian: return "Gaussian"
    }
  }

  var icon: String {
    switch self {
    case .pixelated: return "square.grid.3x3"
    case .gaussian: return "drop.halffull"
    }
  }
}
```

### Step 2: Update AnnotationType
```swift
// Change from:
case blur
// To:
case blur(BlurType)
```

### Step 3: Update AnnotateState
```swift
// Add in Tool State section (around line 28)
@Published var blurType: BlurType = .pixelated
```

### Step 4: Fix compilation errors
Update all usages of `.blur` pattern matching:
- `AnnotationItem.swift` line 75: `case .rectangle, .blur:` -> `case .rectangle, .blur(_):`
- `AnnotationRenderer.swift` line 67: extract blur type for rendering

### Step 5: Update annotation creation
Where blur annotations are created, pass current `state.blurType`:
```swift
// In canvas gesture handler
let annotation = AnnotationItem(
  type: .blur(state.blurType),
  bounds: rect,
  properties: properties
)
```

## Todo List

- [ ] Add `BlurType` enum to `AnnotationItem.swift`
- [ ] Update `AnnotationType.blur` to accept `BlurType`
- [ ] Add `blurType` property to `AnnotateState`
- [ ] Fix pattern matching in `AnnotationItem.containsPoint`
- [ ] Update `AnnotationRenderer.draw` blur case
- [ ] Update blur annotation creation in canvas view
- [ ] Verify app compiles without errors

## Success Criteria

- [x] `BlurType` enum exists with pixelated/gaussian cases
- [x] `AnnotateState.blurType` property accessible
- [x] `AnnotationType.blur(BlurType)` stores blur type
- [x] App compiles and runs without crashes
- [x] Existing pixelated blur still works (regression test)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing blur annotations | Low | Medium | Default to .pixelated |
| Compilation errors missed | Low | Low | Full project build |

## Next Steps

After completing this phase, proceed to [Phase 2](./phase-02-gaussian-blur-renderer.md) to implement the Gaussian blur renderer using CIFilter.
