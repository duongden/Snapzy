# Phase 4: Export Pipeline

**Parent:** [plan.md](./plan.md)
**Dependencies:** [Phase 1](./phase-01-state-management.md), [Phase 2](./phase-02-sidebar-ui-components.md), [Phase 3](./phase-03-preview-integration.md)
**Date:** 2026-01-24
**Priority:** High
**Status:** Pending
**Review:** Not Started

## Overview

Extend ZoomCompositor to render video with background/padding during export using CIFilter compositing.

## Key Insights

- ZoomCompositor already uses CIFilter-based frame processing
- CIContext with GPU acceleration exists: `CIContext(options: [.useSoftwareRenderer: false])`
- Background rendering adds minimal overhead per frame
- Export output size changes when padding applied
- Gradient/solid backgrounds render as CIImage, composited under video

## Requirements

1. Calculate new render size including padding
2. Generate background CIImage (gradient/solid/wallpaper)
3. Composite video frame over background
4. Apply corner radius masking
5. Maintain audio sync during export

## Related Files

| File | Action |
|------|--------|
| `ClaudeShot/Features/VideoEditor/Export/ZoomCompositor.swift` | Modify |
| `ClaudeShot/Features/VideoEditor/Export/VideoEditorExporter.swift` | Modify |

## Architecture

```
ZoomCompositor (extended)
├── backgroundStyle: BackgroundStyle
├── backgroundPadding: CGFloat
├── cornerRadius: CGFloat
├── shadowIntensity: CGFloat
└── processRequest()
    ├── Calculate padded render size
    ├── Generate background CIImage
    ├── Scale/position video frame
    ├── Apply corner radius mask
    ├── Composite video over background
    └── Apply shadow (optional)
```

## Implementation Steps

### Step 1: Extend ZoomCompositor Init

```swift
init(
  zooms: [ZoomSegment],
  renderSize: CGSize,
  transitionDuration: TimeInterval = 0.3,
  backgroundStyle: BackgroundStyle = .none,
  backgroundPadding: CGFloat = 0,
  cornerRadius: CGFloat = 0,
  shadowIntensity: CGFloat = 0
) {
  // Store background properties
  self.backgroundStyle = backgroundStyle
  self.backgroundPadding = backgroundPadding
  self.cornerRadius = cornerRadius
  self.shadowIntensity = shadowIntensity

  // Calculate padded render size
  self.paddedRenderSize = CGSize(
    width: renderSize.width + (backgroundPadding * 2),
    height: renderSize.height + (backgroundPadding * 2)
  )
}
```

### Step 2: Create Background CIImage Generator

```swift
private func createBackgroundImage(size: CGSize) -> CIImage {
  switch backgroundStyle {
  case .none:
    return CIImage(color: .clear).cropped(to: CGRect(origin: .zero, size: size))

  case .gradient(let preset):
    // Create gradient using CILinearGradient filter
    let filter = CIFilter(name: "CILinearGradient")!
    filter.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
    filter.setValue(CIVector(x: size.width, y: size.height), forKey: "inputPoint1")
    filter.setValue(CIColor(color: NSColor(preset.colors[0]))!, forKey: "inputColor0")
    filter.setValue(CIColor(color: NSColor(preset.colors[1]))!, forKey: "inputColor1")
    return filter.outputImage!.cropped(to: CGRect(origin: .zero, size: size))

  case .solidColor(let color):
    let ciColor = CIColor(color: NSColor(color))!
    return CIImage(color: ciColor).cropped(to: CGRect(origin: .zero, size: size))

  case .wallpaper(let url), .blurred(let url):
    guard let image = CIImage(contentsOf: url) else {
      return CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: size))
    }
    // Scale to fill and crop
    let scaled = image.transformed(by: scaleToFill(image.extent.size, to: size))
    return scaled.cropped(to: CGRect(origin: .zero, size: size))
  }
}
```

### Step 3: Modify Frame Processing

```swift
private func applyBackgroundAndZoom(
  to sourceBuffer: CVPixelBuffer,
  zoomLevel: CGFloat,
  center: CGPoint,
  renderSize: CGSize
) -> CVPixelBuffer? {
  let sourceImage = CIImage(cvPixelBuffer: sourceBuffer)

  // Apply zoom if needed
  var processedImage = sourceImage
  if zoomLevel > 1.0 {
    processedImage = applyZoom(to: sourceImage, level: zoomLevel, center: center)
  }

  // Skip background if none
  guard backgroundStyle != .none else {
    return renderToBuffer(processedImage)
  }

  // Scale video to fit within padded area
  let videoRect = CGRect(
    x: backgroundPadding,
    y: backgroundPadding,
    width: renderSize.width,
    height: renderSize.height
  )
  let scaledVideo = processedImage.transformed(
    by: CGAffineTransform(translationX: videoRect.origin.x, y: videoRect.origin.y)
  )

  // Apply corner radius mask
  let maskedVideo = applyCornerRadiusMask(to: scaledVideo, rect: videoRect)

  // Create background
  let background = createBackgroundImage(size: paddedRenderSize)

  // Composite
  let output = maskedVideo.composited(over: background)

  return renderToBuffer(output)
}
```

### Step 4: Corner Radius Masking

```swift
private func applyCornerRadiusMask(to image: CIImage, rect: CGRect) -> CIImage {
  guard cornerRadius > 0 else { return image }

  // Create rounded rect mask
  let path = CGPath(
    roundedRect: rect,
    cornerWidth: cornerRadius,
    cornerHeight: cornerRadius,
    transform: nil
  )

  // Use CIBlendWithMask or geometry masking
  // Implementation depends on CoreImage availability
  return image // Simplified - implement proper masking
}
```

### Step 5: Update VideoEditorExporter

Pass background settings to ZoomCompositor:

```swift
let zoomCompositor = ZoomCompositor(
  zooms: adjustedZooms,
  renderSize: state.naturalSize,
  backgroundStyle: state.backgroundStyle,
  backgroundPadding: state.backgroundPadding,
  cornerRadius: state.backgroundCornerRadius,
  shadowIntensity: state.backgroundShadowIntensity
)
```

### Step 6: Update Export Session Render Size

```swift
videoComposition.renderSize = zoomCompositor.paddedRenderSize
```

## Todo List

- [ ] Add background properties to ZoomCompositor
- [ ] Calculate padded render size
- [ ] Implement createBackgroundImage() for all style types
- [ ] Implement gradient CIImage generation
- [ ] Implement solid color CIImage generation
- [ ] Implement wallpaper loading and scaling
- [ ] Implement corner radius masking
- [ ] Modify processRequest() to composite background
- [ ] Update VideoEditorExporter to pass background settings
- [ ] Update render size in video composition
- [ ] Test export with various background configurations
- [ ] Verify audio sync maintained

## Success Criteria

- [ ] Export produces video with visible background
- [ ] Gradient backgrounds render correctly
- [ ] Solid color backgrounds render correctly
- [ ] Padding creates border around video
- [ ] Corner radius clips video correctly
- [ ] Audio remains in sync
- [ ] Export time increase < 20%

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CIFilter gradient quality | Low | Low | Test various presets |
| Memory pressure large files | Medium | Medium | Profile with Instruments |
| Corner radius mask complexity | Medium | Low | Use simpler crop if needed |
| Render size mismatch | Medium | High | Validate all size calculations |

## Security Considerations

- Wallpaper URLs validated to local filesystem only
- No arbitrary code execution in CIFilter pipeline

## Next Steps

After completion:
- Run full integration testing
- Performance profiling
- Update documentation
