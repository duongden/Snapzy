# Phase 5: Export Integration

**Date**: 2026-01-27
**Priority**: High
**Status**: Pending

## Context Links

- [Main Plan](./plan.md)
- Previous: [Phase 4 - UI Integration](./phase-04-ui-integration.md)

## Overview

Ensure blur annotations export correctly with proper blur type. Fix placeholder at line 353 in `AnnotateExporter.swift`.

## Key Insights

- Line 353 has blur-related placeholder in `drawBackground`
- Export uses `AnnotationRenderer` which already handles blur
- Must pass blur type through export pipeline
- Both pixelated and Gaussian must render in final image

## Requirements

1. Blur annotations render correctly in exported image
2. Blur type (pixelated/gaussian) preserved during export
3. No placeholder/stub code remaining

## Architecture

Export flow:
```
renderFinalImage()
  -> AnnotationRenderer.draw(annotation)
    -> drawBlur(bounds, annotationId, blurType)
      -> BlurEffectRenderer.drawPixelatedRegion() or drawGaussianBlur()
```

## Related Code Files

| File | Changes |
|------|---------|
| `Export/AnnotateExporter.swift` | Remove placeholder, verify blur export |
| `Canvas/AnnotationRenderer.swift` | Extract blurType from annotation |

## Implementation Steps

### Step 1: Update AnnotationRenderer blur extraction
```swift
// In AnnotationRenderer.draw(), update blur case
case .blur(let blurType):
  drawBlur(bounds: annotation.bounds, annotationId: annotation.id, blurType: blurType)
```

### Step 2: Verify export renderer has source image
```swift
// In AnnotateExporter.renderFinalImage()
// Ensure renderer is created with sourceImage
let renderer = AnnotationRenderer(
  context: context,
  sourceImage: sourceImage,
  blurCacheManager: nil  // No cache needed for export
)
```

### Step 3: Remove placeholder at line 353
```swift
// Current placeholder in drawBackground:
case .blurred(let url):
  if let wallpaper = NSImage(contentsOf: url) {
    wallpaper.draw(in: rect)
    if case .blurred = state.backgroundStyle {
      // Apply blur effect would require CIFilter  <-- REMOVE THIS COMMENT
    }
  }

// Replace with actual implementation:
case .blurred(let url):
  if let wallpaper = NSImage(contentsOf: url) {
    // Apply Gaussian blur to wallpaper background
    BlurEffectRenderer.drawGaussianBlur(
      in: context,
      sourceImage: wallpaper,
      region: rect,
      radius: 20
    )
  }
```

### Step 4: Test export pipeline
1. Create blur annotation (pixelated)
2. Export image, verify pixelated blur renders
3. Create blur annotation (gaussian)
4. Export image, verify gaussian blur renders
5. Test both in same export

## Todo List

- [ ] Update blur case in AnnotationRenderer.draw()
- [ ] Verify sourceImage passed to export renderer
- [ ] Implement blurred background at line 353
- [ ] Test pixelated blur export
- [ ] Test gaussian blur export
- [ ] Test mixed blur types in same export

## Success Criteria

- [x] Pixelated blur exports correctly
- [x] Gaussian blur exports correctly
- [x] Blurred background style works
- [x] No placeholder comments remain
- [x] Export matches canvas preview

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Export blur differs from preview | Medium | Medium | Use same renderer code |
| Memory spike on large images | Low | Medium | No cache in export |

## Verification Checklist

- [ ] Export PNG with pixelated blur
- [ ] Export PNG with gaussian blur
- [ ] Export JPEG with blur (compression artifacts?)
- [ ] Copy to clipboard with blur
- [ ] Share sheet with blur
