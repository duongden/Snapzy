# Video Preview/Export Mismatch Fix

**Date:** 2026-01-24
**Status:** Ready for Implementation
**Complexity:** Medium
**Estimated Effort:** 2-3 hours

---

## Problem Summary

The video preview in the editor does not match the exported video output due to three root causes:

1. **Padding Mismatch**: Preview uses SwiftUI `.padding()` (points), export uses raw pixel translation without scale factor conversion
2. **Corner Radius Not Applied**: `cornerRadius` property passed to `ZoomVideoCompositionInstruction` but never used in `applyEffects()` method
3. **Aspect Ratio Differences**: Preview uses GeometryReader container size, export uses fixed video `naturalSize`

---

## Files to Modify

| File | Changes |
|------|---------|
| `ZoomCompositor.swift` | Add corner radius masking, fix padding calculation |
| `ZoomPreviewOverlay.swift` | Align preview sizing with export behavior |

---

## Implementation Plan

### Phase 1: Fix Corner Radius in Export (ZoomCompositor.swift)

**Location:** `ClaudeShot/Features/VideoEditor/Export/ZoomCompositor.swift`

**Problem:** The `cornerRadius` property is stored but never applied in `applyEffects()`.

**Solution:** Apply rounded corners using CIFilter masking before compositing.

#### Step 1.1: Add Corner Radius Masking Method

Add new private method after `scaleToFill()` (around line 391):

```swift
/// Apply corner radius mask to an image
/// - Parameters:
///   - image: Source CIImage
///   - cornerRadius: Corner radius in pixels
///   - size: Size of the image
/// - Returns: CIImage with rounded corners
private func applyCornerRadius(
  to image: CIImage,
  cornerRadius: CGFloat,
  size: CGSize
) -> CIImage {
  guard cornerRadius > 0 else { return image }

  // Create rounded rectangle path
  let rect = CGRect(origin: .zero, size: size)
  let path = CGPath(
    roundedRect: rect,
    cornerWidth: cornerRadius,
    cornerHeight: cornerRadius,
    transform: nil
  )

  // Create mask image from path
  let context = CGContext(
    data: nil,
    width: Int(size.width),
    height: Int(size.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceGray(),
    bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
  )!

  context.setFillColor(CGColor(gray: 1, alpha: 1))
  context.addPath(path)
  context.fillPath()

  guard let maskCGImage = context.makeImage() else { return image }
  let maskImage = CIImage(cgImage: maskCGImage)

  // Apply mask using CIBlendWithMask
  guard let blendFilter = CIFilter(name: "CIBlendWithAlphaMask") else { return image }
  blendFilter.setValue(image, forKey: kCIInputImageKey)
  blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)

  return blendFilter.outputImage ?? image
}
```

#### Step 1.2: Integrate Corner Radius in applyEffects()

Modify `applyEffects()` method (around line 287-338) to apply corner radius before compositing with background:

**Current code (line 313-328):**
```swift
// Apply background if needed
let hasBackground = instruction.backgroundStyle != .none && instruction.backgroundPadding > 0
if hasBackground {
  // Position video in center with padding
  let translatedVideo = processedImage.transformed(
    by: CGAffineTransform(translationX: instruction.backgroundPadding, y: instruction.backgroundPadding)
  )

  // Create background
  let background = createBackgroundImage(
    style: instruction.backgroundStyle,
    size: instruction.paddedRenderSize
  )

  // Composite video over background
  processedImage = translatedVideo.composited(over: background)
}
```

**Updated code:**
```swift
// Apply background if needed
let hasBackground = instruction.backgroundStyle != .none && instruction.backgroundPadding > 0
if hasBackground {
  // Apply corner radius BEFORE positioning (to the video frame itself)
  let videoSize = CGSize(width: sourceExtent.width, height: sourceExtent.height)
  if instruction.cornerRadius > 0 {
    processedImage = applyCornerRadius(
      to: processedImage,
      cornerRadius: instruction.cornerRadius,
      size: videoSize
    )
  }

  // Position video in center with padding
  let translatedVideo = processedImage.transformed(
    by: CGAffineTransform(translationX: instruction.backgroundPadding, y: instruction.backgroundPadding)
  )

  // Create background
  let background = createBackgroundImage(
    style: instruction.backgroundStyle,
    size: instruction.paddedRenderSize
  )

  // Composite video over background
  processedImage = translatedVideo.composited(over: background)
}
```

---

### Phase 2: Fix Padding Calculation for WYSIWYG (Both Files)

**Problem:** Preview padding uses SwiftUI points, export uses raw pixels without considering aspect ratio differences.

#### Step 2.1: Add Padding Ratio Calculation to VideoEditorState

The padding should be stored as a **ratio** (0.0 to 1.0) relative to video dimensions, not absolute pixels.

**Option A (Minimal Change):** Convert at export time using video natural size.

In `ZoomCompositor.swift`, the `backgroundPadding` from state should be interpreted as a ratio of the smaller dimension:

**Current code (line 44-52):**
```swift
// Calculate padded render size
if backgroundStyle != .none && backgroundPadding > 0 {
  self.paddedRenderSize = CGSize(
    width: renderSize.width + (backgroundPadding * 2),
    height: renderSize.height + (backgroundPadding * 2)
  )
} else {
  self.paddedRenderSize = renderSize
}
```

**Keep as-is** - The padding value passed from the exporter already uses the state's `backgroundPadding` which is in points. The issue is the **preview** using SwiftUI `.padding()` directly.

#### Step 2.2: Update ZoomPreviewOverlay to Match Export Behavior

**Location:** `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomPreviewOverlay.swift`

**Problem:** Preview uses `.padding(state.backgroundPadding)` which is relative to the container (GeometryReader), not the video's natural size.

**Solution:** Calculate padding as a proportion of the preview container that matches what export will produce.

**Current code (line 29-39):**
```swift
// Video with effects
videoPlayerContent(in: geometry.size)
  .cornerRadius(state.backgroundCornerRadius)
  .shadow(
    color: .black.opacity(Double(state.backgroundShadowIntensity) * 0.5),
    radius: state.backgroundShadowIntensity * 20,
    x: 0,
    y: state.backgroundShadowIntensity * 10
  )
  .padding(state.backgroundPadding)
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentValue)
```

**Updated approach:** Calculate the video frame size based on natural size ratio, then apply padding proportionally.

```swift
// Video with effects
videoPlayerContent(in: geometry.size)
  .cornerRadius(scaledCornerRadius(for: geometry.size))
  .shadow(
    color: .black.opacity(Double(state.backgroundShadowIntensity) * 0.5),
    radius: state.backgroundShadowIntensity * 20,
    x: 0,
    y: state.backgroundShadowIntensity * 10
  )
  .padding(scaledPadding(for: geometry.size))
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentValue)
```

Add helper methods:

```swift
// MARK: - Scaled Values for WYSIWYG

/// Calculate the scale factor between preview container and video natural size
private func previewScaleFactor(for containerSize: CGSize) -> CGFloat {
  guard state.naturalSize.width > 0, state.naturalSize.height > 0 else { return 1.0 }

  let videoAspect = state.naturalSize.width / state.naturalSize.height
  let containerAspect = containerSize.width / containerSize.height

  // Video fits within container maintaining aspect ratio
  if containerAspect > videoAspect {
    // Container is wider - video height matches container height
    return containerSize.height / state.naturalSize.height
  } else {
    // Container is taller - video width matches container width
    return containerSize.width / state.naturalSize.width
  }
}

/// Scale padding from video pixels to preview points
private func scaledPadding(for containerSize: CGSize) -> CGFloat {
  let scale = previewScaleFactor(for: containerSize)
  return state.backgroundPadding * scale
}

/// Scale corner radius from video pixels to preview points
private func scaledCornerRadius(for containerSize: CGSize) -> CGFloat {
  let scale = previewScaleFactor(for: containerSize)
  return state.backgroundCornerRadius * scale
}
```

---

### Phase 3: Ensure Consistent Aspect Ratio Handling

**Problem:** Export uses `state.naturalSize` directly, preview uses GeometryReader container which may have different aspect ratio.

**Solution:** Already addressed in Phase 2 by calculating scale factor. The preview will now scale padding/cornerRadius proportionally to match what export produces at full resolution.

---

## Code Changes Summary

### File 1: ZoomCompositor.swift

| Line Range | Change Type | Description |
|------------|-------------|-------------|
| ~391 | Add | New `applyCornerRadius(to:cornerRadius:size:)` method |
| 313-328 | Modify | Call `applyCornerRadius` before compositing with background |

### File 2: ZoomPreviewOverlay.swift

| Line Range | Change Type | Description |
|------------|-------------|-------------|
| 29-39 | Modify | Use `scaledPadding()` and `scaledCornerRadius()` |
| After 116 | Add | New helper methods for scale calculations |

---

## Testing Checklist

- [ ] Export video with background + padding, verify padding matches preview
- [ ] Export video with corner radius, verify corners are rounded in output
- [ ] Test with different video resolutions (720p, 1080p, 4K)
- [ ] Test with different aspect ratios (16:9, 4:3, 1:1, 9:16)
- [ ] Verify zoom effects still work correctly with new changes
- [ ] Test edge cases: padding=0, cornerRadius=0, no background

---

## Potential Issues

1. **Performance**: CGContext-based masking for corner radius may be slower than Metal-based approach. If performance is an issue, consider using `CIRoundedRectangleGenerator` (iOS 15+/macOS 12+) or pre-computed mask textures.

2. **Coordinate Systems**: Core Image uses bottom-left origin. Ensure corner radius mask is correctly oriented.

3. **Scale Factor Edge Cases**: Very small previews or very large videos may produce visible differences. Test at extreme scales.

---

## Alternative Approaches Considered

1. **Use CIFilter chain**: Could use `CIRoundedRectangleGenerator` + blend, but requires macOS 12+ and is less flexible.

2. **Pre-render mask as CIImage**: More performant but adds complexity for dynamic corner radius values.

3. **Metal shader**: Best performance but significantly more complex implementation.

**Chosen approach** (CGContext masking) balances simplicity, compatibility, and correctness.
