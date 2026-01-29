# Phase 01: Fix Preview Dimension Calculation

**Status:** Not Started
**File:** `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomPreviewOverlay.swift`

## Objective

Update `ZoomableVideoPlayerSection` to use export dimensions for preview calculations, ensuring WYSIWYG behavior.

## Changes

### 1. Update `previewScaleFactor()` (Lines 156-183)

**Current code:**
```swift
private func previewScaleFactor(for containerSize: CGSize) -> CGFloat {
  let naturalSize = state.naturalSize
  guard naturalSize.width > 0 && naturalSize.height > 0 &&
        containerSize.width > 0 && containerSize.height > 0 else { return 1.0 }

  // Calculate how the video fits in the container (aspect fit)
  let containerAspect = containerSize.width / containerSize.height
  let videoAspect = naturalSize.width / naturalSize.height
  // ... rest uses naturalSize
}
```

**Updated code:**
```swift
private func previewScaleFactor(for containerSize: CGSize) -> CGFloat {
  // Use export size for WYSIWYG preview
  let effectiveSize = state.exportSettings.exportSize(from: state.naturalSize)
  guard effectiveSize.width > 0 && effectiveSize.height > 0 &&
        containerSize.width > 0 && containerSize.height > 0 else { return 1.0 }

  // Calculate how the video fits in the container (aspect fit)
  let containerAspect = containerSize.width / containerSize.height
  let videoAspect = effectiveSize.width / effectiveSize.height

  let fittedSize: CGSize
  if containerAspect > videoAspect {
    // Container is wider - video height fills container
    fittedSize = CGSize(
      width: containerSize.height * videoAspect,
      height: containerSize.height
    )
  } else {
    // Container is taller - video width fills container
    fittedSize = CGSize(
      width: containerSize.width,
      height: containerSize.width / videoAspect
    )
  }

  // Scale factor = preview size / effective size
  // This converts "pixels" in state to "points" in preview
  return min(fittedSize.width / effectiveSize.width, fittedSize.height / effectiveSize.height)
}
```

### 2. Update `calculateCompositeSize()` (Lines 189-217)

**Current code:**
```swift
private func calculateCompositeSize(containerSize: CGSize, scaledPadding: CGFloat) -> CGSize {
  let naturalSize = state.naturalSize
  guard naturalSize.width > 0 && naturalSize.height > 0 &&
        containerSize.width > 0 && containerSize.height > 0 else {
    return containerSize
  }

  // Calculate the composite aspect ratio (video + padding on all sides)
  let compositeNaturalWidth = naturalSize.width + (state.backgroundPadding * 2)
  let compositeNaturalHeight = naturalSize.height + (state.backgroundPadding * 2)
  // ... rest uses naturalSize-based composite
}
```

**Updated code:**
```swift
private func calculateCompositeSize(containerSize: CGSize, scaledPadding: CGFloat) -> CGSize {
  // Use export size for WYSIWYG preview
  let effectiveSize = state.exportSettings.exportSize(from: state.naturalSize)
  guard effectiveSize.width > 0 && effectiveSize.height > 0 &&
        containerSize.width > 0 && containerSize.height > 0 else {
    return containerSize
  }

  // Calculate the composite aspect ratio (video + padding on all sides)
  // Scale padding proportionally to export dimensions
  let paddingScale = effectiveSize.width / state.naturalSize.width
  let scaledBackgroundPadding = state.backgroundPadding * paddingScale
  let compositeWidth = effectiveSize.width + (scaledBackgroundPadding * 2)
  let compositeHeight = effectiveSize.height + (scaledBackgroundPadding * 2)
  let compositeAspect = compositeWidth / compositeHeight

  // Fit composite into container maintaining aspect ratio
  let containerAspect = containerSize.width / containerSize.height

  if containerAspect > compositeAspect {
    // Container is wider - composite height fills container
    return CGSize(
      width: containerSize.height * compositeAspect,
      height: containerSize.height
    )
  } else {
    // Container is taller - composite width fills container
    return CGSize(
      width: containerSize.width,
      height: containerSize.width / compositeAspect
    )
  }
}
```

## Implementation Steps

1. Open `ZoomPreviewOverlay.swift`
2. Locate `previewScaleFactor()` method (line 156)
3. Replace `naturalSize` references with `effectiveSize` calculation
4. Locate `calculateCompositeSize()` method (line 189)
5. Replace `naturalSize` references with `effectiveSize` calculation
6. Add padding scale factor for proportional background padding

## Verification

After changes:
- Select 720p preset: preview should show full video scaled down, not cropped
- Select 1080p preset: preview should match export result
- Background padding should scale proportionally with dimension changes

## Rollback

Revert changes to `ZoomPreviewOverlay.swift` if issues occur.
