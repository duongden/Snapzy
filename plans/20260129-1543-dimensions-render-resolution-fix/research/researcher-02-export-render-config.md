# Research: Export/Render Resolution Configuration

## Summary
Export resolution handled via AVVideoComposition.renderSize in 3 export paths. No SCStreamConfiguration involvement in export. Dimensions setting correctly applied only to export, not recording.

## Key Findings

### 1. Export Pipeline Architecture
**File:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/VideoEditor/Export/VideoEditorExporter.swift`

Three export paths based on content:
- `exportStandard()` - Lines 43-131: Basic trim/resize
- `exportWithZooms()` - Lines 134-333: Zoom effects + background
- `exportVideoOnly()` - Lines 336-426: Muted audio

All paths use `AVMutableVideoComposition` for dimension changes.

### 2. Dimension Application Points

#### Standard Export (Lines 68-106)
```swift
// Line 69: Check if custom dimensions needed
if state.exportSettings.dimensionPreset != .original {
  let targetSize = state.exportSettings.exportSize(from: state.naturalSize)

  // Lines 74-75: Set render size
  let videoComposition = AVMutableVideoComposition()
  videoComposition.renderSize = targetSize

  // Lines 84-98: Scale transform for aspect-fit
  let scale = min(targetSize.width / naturalSize.width,
                  targetSize.height / naturalSize.height)
  let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
  // ... centering logic
}
```

#### Zoom Export (Lines 241-274)
```swift
// Lines 243-250: Calculate target BEFORE compositor
let baseRenderSize: CGSize
if state.exportSettings.dimensionPreset != .original {
  baseRenderSize = state.exportSettings.exportSize(from: state.naturalSize)
} else {
  baseRenderSize = state.naturalSize
}

// Lines 253-260: Pass to ZoomCompositor
let zoomCompositor = ZoomCompositor(
  zooms: adjustedZooms,
  renderSize: baseRenderSize,  // <-- Critical parameter
  backgroundStyle: state.backgroundStyle,
  backgroundPadding: state.backgroundPadding,
  cornerRadius: state.backgroundCornerRadius
)

// Line 274: Use compositor's padded size (includes background)
videoComposition.renderSize = zoomCompositor.paddedRenderSize
```

#### Video-Only Export (Lines 362-396)
Same pattern as standard export - creates AVMutableVideoComposition with custom renderSize.

### 3. No SCStreamConfiguration in Export
**Finding:** SCStreamConfiguration NOT used in export pipeline.

Checked `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/ScreenRecordingManager.swift`:
- SCStreamConfiguration used for RECORDING only
- Sets capture dimensions during screen recording
- Export reads from already-recorded AVAsset

**Separation confirmed:**
- Recording: SCStreamConfiguration controls capture resolution
- Export: AVVideoComposition.renderSize controls output resolution

### 4. ZoomCompositor Pixel Buffer Handling
**File:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/VideoEditor/Export/ZoomCompositor.swift`

Need to verify pixel buffer dimensions match renderSize parameter, not natural size.

### 5. Correct Implementation Pattern

**Current flow (correct):**
1. User selects dimension preset in UI
2. ExportSettings.exportSize() calculates target dimensions
3. AVVideoComposition.renderSize set to target
4. Scale transform applied to fit content
5. Export writes at target resolution

**NOT affected:**
- UI preview dimensions
- Timeline rendering
- Player display size

## Critical Code Paths

### exportSize() Calculation
```swift
// ExportSettings.swift (inferred)
func exportSize(from naturalSize: CGSize) -> CGSize {
  // Returns scaled size based on dimensionPreset
  // e.g., .half = naturalSize * 0.5
}
```

### Transform Application
All three export paths use same pattern:
1. Calculate scale factor (aspect-fit)
2. Create scale transform
3. Center in target renderSize
4. Apply to AVVideoCompositionLayerInstruction

## Analysis

**Bug likely NOT in export configuration.**

Export pipeline correctly:
- Checks dimensionPreset before applying
- Calculates target size via exportSize()
- Sets AVVideoComposition.renderSize
- Applies transforms for proper scaling

**Potential issues:**
1. ZoomCompositor may use wrong dimensions for pixel buffers
2. paddedRenderSize calculation might ignore dimension preset
3. UI might be reading estimated size from wrong source

## Next Steps

1. Verify ZoomCompositor pixel buffer allocation uses renderSize param
2. Check paddedRenderSize calculation respects custom dimensions
3. Trace how UI reads estimated dimensions (likely separate issue)

## File References

- VideoEditorExporter.swift: Lines 69-106, 243-274, 362-396
- ZoomCompositor.swift: Need pixel buffer init code
- ExportSettings.swift: Need exportSize() implementation
- ScreenRecordingManager.swift: Confirmed no export involvement
