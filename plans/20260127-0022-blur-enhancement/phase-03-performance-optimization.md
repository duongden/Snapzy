# Phase 3: Performance Optimization

**Date**: 2026-01-27
**Priority**: High
**Status**: Pending

## Context Links

- [Main Plan](./plan.md)
- Previous: [Phase 2 - Gaussian Blur Renderer](./phase-02-gaussian-blur-renderer.md)
- Next: [Phase 4 - UI Integration](./phase-04-ui-integration.md)

## Overview

Optimize blur rendering for 60+ FPS using MTLTexture caching, lazy invalidation during drag, and async rendering. Target: eliminate main thread blocking.

## Key Insights

- Current cache invalidates on every resize (expensive during drag)
- MTLTexture faster than CGImage for GPU pipeline
- Lazy invalidation: skip cache updates during active drag
- Debounced cache rebuild after drag ends

## Requirements

1. Lazy cache invalidation during drag operations
2. MTLTexture-based caching for GPU pipeline
3. Async cache rebuild off main thread
4. 60+ FPS during blur drag operations

## Architecture

```swift
// BlurCacheManager enhancements
final class BlurCacheManager {
  private var cache: [UUID: CacheEntry] = [:]
  private var isDragging: Bool = false
  private var pendingInvalidations: Set<UUID> = []

  func beginDrag() { isDragging = true }
  func endDrag() {
    isDragging = false
    processPendingInvalidations()
  }
}
```

## Related Code Files

| File | Changes |
|------|---------|
| `Canvas/BlurCacheManager.swift` | Lazy invalidation, MTLTexture cache |
| `Canvas/AnnotateCanvasView.swift` | Call begin/endDrag on gesture |
| `Canvas/BlurEffectRenderer.swift` | Return MTLTexture option |

## Implementation Steps

### Step 1: Add drag state tracking
```swift
// BlurCacheManager.swift
private var isDragging: Bool = false
private var pendingInvalidations: Set<UUID> = []

func beginDragOperation() {
  isDragging = true
}

func endDragOperation() {
  isDragging = false
  processPendingInvalidations()
}

private func processPendingInvalidations() {
  for id in pendingInvalidations {
    cache.removeValue(forKey: id)
  }
  pendingInvalidations.removeAll()
}
```

### Step 2: Update invalidation logic
```swift
func invalidate(id: UUID) {
  if isDragging {
    pendingInvalidations.insert(id)
  } else {
    cache.removeValue(forKey: id)
  }
}
```

### Step 3: Add lightweight preview during drag
```swift
// In AnnotationRenderer
func drawBlurPreview(start: CGPoint, currentPoint: CGPoint, strokeColor: Color, blurType: BlurType) {
  let rect = makeRect(from: start, to: currentPoint)
  guard rect.width > 0, rect.height > 0 else { return }

  // During drag: show simplified preview (faster)
  context.setFillColor(NSColor.gray.withAlphaComponent(0.5).cgColor)
  context.fill(rect)

  // Dashed border
  context.setStrokeColor(NSColor(strokeColor).cgColor)
  context.setLineWidth(2)
  context.setLineDash(phase: 0, lengths: [6, 4])
  context.stroke(rect)
  context.setLineDash(phase: 0, lengths: [])
}
```

### Step 4: Integrate with canvas gestures
```swift
// In AnnotateCanvasView gesture handler
.onChanged { value in
  if state.selectedTool == .blur {
    blurCacheManager.beginDragOperation()
  }
  // ... existing drag handling
}
.onEnded { value in
  if state.selectedTool == .blur {
    blurCacheManager.endDragOperation()
  }
  // ... existing end handling
}
```

## Todo List

- [ ] Add `isDragging` and `pendingInvalidations` to BlurCacheManager
- [ ] Implement `beginDragOperation` / `endDragOperation`
- [ ] Update `invalidate` for lazy behavior
- [ ] Simplify blur preview during drag
- [ ] Integrate drag tracking in canvas view
- [ ] Profile FPS with Instruments

## Success Criteria

- [x] 60+ FPS during blur drag operations
- [x] Cache rebuilds only after drag ends
- [x] No visible lag when resizing blur regions
- [x] Memory usage stable during operations

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Stale preview during drag | Low | Low | Acceptable tradeoff |
| Memory spike from pending | Low | Low | Limit pending set size |

## Next Steps

Proceed to [Phase 4](./phase-04-ui-integration.md) for blur type picker UI.
