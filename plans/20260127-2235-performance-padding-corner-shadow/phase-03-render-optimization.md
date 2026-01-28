# Phase 03: Render Optimization with drawingGroup

## Context
- Parent: [plan.md](plan.md)
- Dependencies: Phase 01, Phase 02 (recommended but not required)

## Overview
- **Date:** 2026-01-27
- **Priority:** High
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
SwiftUI recalculates expensive modifiers on every frame:
- `.shadow()` - GPU-intensive blur operation
- `.cornerRadius()` - Mask clipping operation
- Gradient fills - Color interpolation

Using `drawingGroup()` rasterizes view hierarchy into a single Metal texture, reducing per-frame work.

## Requirements
- Reduce GPU work during slider drag
- Maintain visual quality
- No visible artifacts or rendering issues

## Architecture

### Current Flow
```
Each frame: SwiftUI calculates shadow → clips corners → composites layers
```

### Proposed Flow
```
drawingGroup() → Rasterize to texture → GPU composites single layer
```

## Related Code Files
- [AnnotateCanvasView.swift:128-166](../../ClaudeShot/Features/Annotate/Views/AnnotateCanvasView.swift#L128-L166) - canvasContent
- [AnnotateCanvasView.swift:170-235](../../ClaudeShot/Features/Annotate/Views/AnnotateCanvasView.swift#L170-L235) - backgroundLayer
- [AnnotateCanvasView.swift:240-254](../../ClaudeShot/Features/Annotate/Views/AnnotateCanvasView.swift#L240-L254) - imageLayer

## Implementation Steps

### Step 1: Apply drawingGroup to Background Layer
```swift
private func backgroundLayer(width: CGFloat, height: CGFloat) -> some View {
  Group {
    switch state.backgroundStyle {
    // ... existing switch cases
    }
  }
  .drawingGroup()  // ← Rasterize entire background
}
```

### Step 2: Separate Shadow from Content
Move shadow to wrapper to avoid re-rasterizing content:

```swift
// Before (shadow recalculated with content):
RoundedRectangle(cornerRadius: state.cornerRadius)
  .fill(color)
  .shadow(...)

// After (shadow on separate layer):
RoundedRectangle(cornerRadius: state.cornerRadius)
  .fill(color)
  .background(
    RoundedRectangle(cornerRadius: state.cornerRadius)
      .fill(Color.black.opacity(state.shadowIntensity))
      .blur(radius: 20)
      .offset(y: 10)
  )
```

### Step 3: Add drawingGroup to Image Layer
```swift
private func imageLayer(width: CGFloat, height: CGFloat) -> some View {
  if let sourceImage = state.sourceImage {
    Image(nsImage: sourceImage)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: width, height: height)
      .cornerRadius(state.cornerRadius)
      .drawingGroup()  // ← Rasterize image with corners
      .shadow(...)     // Shadow applied to rasterized result
  }
}
```

### Step 4: Consider Conditional Optimization
Only apply heavy optimizations during drag:

```swift
// In AnnotateState
@Published var isSliderDragging: Bool = false

// In view
.drawingGroup(opaque: false, colorMode: state.isSliderDragging ? .linear : .nonLinear)
```

## Todo List
- [ ] Add drawingGroup() to backgroundLayer
- [ ] Refactor shadow rendering to separate layer
- [ ] Add drawingGroup() to imageLayer
- [ ] Test with various background types
- [ ] Profile GPU usage before/after
- [ ] Verify no visual artifacts

## Success Criteria
- GPU usage reduced during slider drag
- No visual quality loss
- Smooth 60fps during interaction

## Risk Assessment
- **Medium Risk:** drawingGroup can cause issues with certain effects
- **Mitigation:** Test thoroughly with all background types
- **Fallback:** Can remove drawingGroup if issues arise

## Security Considerations
None - rendering optimization only

## Next Steps
After completing all phases:
1. Profile with Instruments to verify improvements
2. Test on lower-spec Macs
3. Consider additional optimizations if needed
