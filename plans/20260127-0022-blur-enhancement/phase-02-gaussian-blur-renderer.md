# Phase 2: Gaussian Blur Renderer

**Date**: 2026-01-27
**Priority**: High
**Status**: Pending

## Context Links

- [Main Plan](./plan.md)
- Previous: [Phase 1 - Blur Type Model](./phase-01-blur-type-model.md)
- Next: [Phase 3 - Performance Optimization](./phase-03-performance-optimization.md)

## Overview

Implement Gaussian blur using `CIGaussianBlur` filter with Metal-backed `CIContext` for GPU acceleration. Expected 1.8x speedup (~40 FPS baseline).

## Key Insights

- `CIGaussianBlur` is GPU-accelerated via Core Image
- Metal-backed `CIContext` essential for performance
- Reuse CIContext across renders (expensive to create)
- CIImage coordinate system differs from CGImage

## Requirements

1. Add `CIGaussianBlur` rendering path in `BlurEffectRenderer`
2. Create shared Metal-backed `CIContext`
3. Support configurable blur radius
4. Maintain fallback for pixelated blur

## Architecture

```swift
// BlurEffectRenderer.swift additions
struct BlurEffectRenderer {
  // Shared GPU context (lazy init)
  private static let ciContext: CIContext = {
    guard let device = MTLCreateSystemDefaultDevice() else {
      return CIContext()
    }
    return CIContext(mtlDevice: device, options: [
      .cacheIntermediates: false,
      .priorityRequestLow: false
    ])
  }()

  static func drawGaussianBlur(
    in context: CGContext,
    sourceImage: NSImage,
    region: CGRect,
    radius: CGFloat = 10
  ) { ... }
}
```

## Related Code Files

| File | Changes |
|------|---------|
| `Canvas/BlurEffectRenderer.swift` | Add `drawGaussianBlur` method, shared CIContext |
| `Canvas/BlurCacheManager.swift` | Add Gaussian cache path |
| `Canvas/AnnotationRenderer.swift` | Route to correct blur method |

## Implementation Steps

### Step 1: Add shared CIContext to BlurEffectRenderer
```swift
// Add at top of struct, after defaultPixelSize
private static let ciContext: CIContext = {
  guard let device = MTLCreateSystemDefaultDevice() else {
    return CIContext()
  }
  return CIContext(mtlDevice: device, options: [
    .cacheIntermediates: false
  ])
}()

/// Default Gaussian blur radius
static let defaultBlurRadius: CGFloat = 10
```

### Step 2: Implement drawGaussianBlur method
```swift
/// Draw Gaussian blurred region using CIFilter
/// - Parameters:
///   - context: The graphics context to draw into
///   - sourceImage: The source image to sample from
///   - region: The region bounds in image coordinates
///   - radius: Blur radius (larger = more blur)
static func drawGaussianBlur(
  in context: CGContext,
  sourceImage: NSImage,
  region: CGRect,
  radius: CGFloat = defaultBlurRadius
) {
  guard region.width > 0, region.height > 0 else { return }

  guard let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    drawFallbackBlur(in: context, region: region)
    return
  }

  // Calculate image scale
  let imageScale = CGFloat(cgImage.width) / sourceImage.size.width

  // Convert region to pixel coordinates (CIImage Y is flipped from NSImage)
  let pixelRegion = CGRect(
    x: region.origin.x * imageScale,
    y: (sourceImage.size.height - region.origin.y - region.height) * imageScale,
    width: region.width * imageScale,
    height: region.height * imageScale
  )

  // Clamp to image bounds
  let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
  let clampedRegion = pixelRegion.intersection(imageBounds)
  guard !clampedRegion.isEmpty else {
    drawFallbackBlur(in: context, region: region)
    return
  }

  // Create CIImage from source
  let ciImage = CIImage(cgImage: cgImage)

  // Crop to region first (reduces blur computation area)
  let croppedImage = ciImage.cropped(to: clampedRegion)

  // Apply Gaussian blur
  guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
    drawFallbackBlur(in: context, region: region)
    return
  }

  blurFilter.setValue(croppedImage, forKey: kCIInputImageKey)
  blurFilter.setValue(radius * imageScale, forKey: kCIInputRadiusKey)

  guard let blurredImage = blurFilter.outputImage else {
    drawFallbackBlur(in: context, region: region)
    return
  }

  // Clamp to prevent blur edge artifacts
  let clampedBlur = blurredImage.cropped(to: clampedRegion)

  // Render to CGImage
  guard let resultCGImage = ciContext.createCGImage(clampedBlur, from: clampedRegion) else {
    drawFallbackBlur(in: context, region: region)
    return
  }

  // Draw to context
  context.draw(resultCGImage, in: region)
}
```

### Step 3: Update BlurCacheManager for Gaussian support
```swift
// Update getCachedBlur signature
func getCachedBlur(
  for annotationId: UUID,
  bounds: CGRect,
  sourceImage: NSImage,
  blurType: BlurType,
  pixelSize: CGFloat = BlurEffectRenderer.defaultPixelSize,
  blurRadius: CGFloat = BlurEffectRenderer.defaultBlurRadius
) -> CGImage? {
  // ... existing cache check ...

  // Render based on blur type
  guard let rendered = renderBlurToImage(
    bounds: bounds,
    sourceImage: sourceImage,
    blurType: blurType,
    pixelSize: pixelSize,
    blurRadius: blurRadius
  ) else { return nil }

  // ... cache and return ...
}

// Update renderBlurToImage
private func renderBlurToImage(
  bounds: CGRect,
  sourceImage: NSImage,
  blurType: BlurType,
  pixelSize: CGFloat,
  blurRadius: CGFloat
) -> CGImage? {
  // ... context creation ...

  switch blurType {
  case .pixelated:
    renderPixelatedRegion(...)
  case .gaussian:
    BlurEffectRenderer.drawGaussianBlur(
      in: context,
      sourceImage: sourceImage,
      region: localRegion,
      radius: blurRadius
    )
  }

  return context.makeImage()
}
```

### Step 4: Update AnnotationRenderer
```swift
private func drawBlur(bounds: CGRect, annotationId: UUID, blurType: BlurType) {
  guard let sourceImage = sourceImage else {
    BlurEffectRenderer.drawBlurPreview(in: context, region: bounds, strokeColor: NSColor.gray.cgColor)
    return
  }

  // Try cached version first
  if let cacheManager = blurCacheManager,
     let cachedImage = cacheManager.getCachedBlur(
       for: annotationId,
       bounds: bounds,
       sourceImage: sourceImage,
       blurType: blurType
     ) {
    context.draw(cachedImage, in: bounds)
    return
  }

  // Fallback to direct render
  switch blurType {
  case .pixelated:
    BlurEffectRenderer.drawPixelatedRegion(in: context, sourceImage: sourceImage, region: bounds)
  case .gaussian:
    BlurEffectRenderer.drawGaussianBlur(in: context, sourceImage: sourceImage, region: bounds)
  }
}
```

## Todo List

- [ ] Add shared Metal-backed CIContext to BlurEffectRenderer
- [ ] Implement `drawGaussianBlur` method
- [ ] Add `defaultBlurRadius` constant
- [ ] Update BlurCacheManager for blurType parameter
- [ ] Update AnnotationRenderer blur routing
- [ ] Test Gaussian blur rendering in canvas
- [ ] Verify blur edge artifacts handled

## Success Criteria

- [x] Gaussian blur renders correctly in canvas
- [x] No edge artifacts or clipping issues
- [x] Metal device used for CIContext
- [x] Blur radius configurable
- [x] Fallback works when Metal unavailable

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Metal unavailable on old Macs | Low | Low | CPU CIContext fallback |
| Blur edge artifacts | Medium | Medium | Crop after blur |
| CIContext creation overhead | Low | Medium | Static shared instance |

## Next Steps

After completing this phase, proceed to [Phase 3](./phase-03-performance-optimization.md) for MTLTexture caching and lazy invalidation.
