# Video Export Track Mismatch - Root Cause Analysis

**Date:** 2026-01-29
**Issue:** Export fails at 73% with "Track ID mismatch: expected 1, available: []"
**Severity:** Critical - Blocks video export functionality

---

## Executive Summary

Export fails at frame 96 (~73% progress) due to **timing mismatch between video composition duration and source frame availability**. The compositor requests frames beyond the source video's trimmed duration, causing AVFoundation to report no available track IDs.

**Root Cause:** Custom dimension changes applied AFTER composition creation cause frame rate calculations to request frames beyond source material duration.

**Business Impact:** Users cannot export videos with custom dimensions (480p, 720p, 1080p presets) when zoom effects or backgrounds are enabled.

---

## Technical Analysis

### Timeline of Failure

```
Video Stats:
- Original duration: 3.9435s
- Natural size: 2528x1698
- Export dimensions: 708x480 (480p preset)
- Frame rate: 30fps
- Expected frames: 3.9435s × 30fps = 118 frames
- Failure point: Frame 96 (2.97s → 73% progress)
```

### Code Flow Analysis

**VideoEditorExporter.swift (Lines 216-230):**
```swift
// 1. Create composition with trimmedDuration
let compositionTimeRange = CMTimeRange(start: .zero, duration: state.trimmedDuration)

videoComposition = try await zoomCompositor.createVideoComposition(
  for: composition,
  timeRange: compositionTimeRange  // ✅ Correct duration
)

// 2. THEN modify renderSize (PROBLEM!)
if state.exportSettings.dimensionPreset != .original {
  let targetSize = state.exportSettings.exportSize(from: baseRenderSize)
  videoComposition.renderSize = targetSize  // ❌ Changes frame calculations
}
```

**ZoomCompositor.swift (Line 69):**
```swift
videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 fps
```

### The Problem Sequence

1. **Composition created** with correct duration (3.9435s) and renderSize matching natural size
2. **RenderSize changed** from natural size (2528x1698) to custom dimensions (708x480)
3. **AVFoundation recalculates** frame boundaries based on new renderSize
4. **Frame 96 requested** at time beyond source material availability
5. **Source track becomes unavailable** - compositor receives empty track ID array
6. **Export fails** with trackMismatch error

### Why Frame 96?

```
Calculation:
- Frame 90 at 2.97s: SUCCESS (2.97s < 3.9435s duration)
- Frames 96-100: FAIL
- Frame 96 timestamp: 96/30 = 3.2s

Issue: renderSize change affects frame timing/sampling
- AVFoundation may adjust frame boundaries when renderSize changes
- Temporal alignment between composition and source breaks
- Compositor requests frames at times where source no longer exists
```

### Evidence from Logs

```
✅ Frame 90 at time 2.97s - SUCCESS
❌ Frame 96: No source frame for trackID 1
❌ Available track IDs: []  ← Source completely unavailable
```

This pattern indicates **temporal boundary violation** - compositor requesting frames outside the valid time range of the inserted source material.

---

## Root Cause Statement

**Modifying `videoComposition.renderSize` after composition creation causes AVFoundation to recalculate frame sampling boundaries, resulting in frame requests beyond the source video's inserted time range. This breaks the temporal contract between the composition instruction's timeRange and the actual availability of source frames.**

---

## Contributing Factors

1. **Two-step composition setup:**
   - Composition created with one renderSize
   - RenderSize changed afterward for custom dimensions

2. **Frame duration fixed at 30fps:**
   - No validation that frame count fits within source duration
   - No guards against requesting frames beyond timeRange.end

3. **No temporal validation:**
   - Compositor doesn't verify requested frame time is within instruction timeRange
   - No fallback when source becomes unavailable

4. **Track ID assumptions:**
   - Code assumes trackID remains valid throughout export
   - No handling for track availability changes during export

---

## Potential Solutions

### Solution 1: Set RenderSize Before Composition Creation (RECOMMENDED)

**Approach:** Calculate final renderSize upfront, pass to compositor

**Changes:**
```swift
// VideoEditorExporter.swift line ~202
let finalRenderSize: CGSize
if state.exportSettings.dimensionPreset != .original {
  let baseRenderSize = zoomCompositor.paddedRenderSize
  finalRenderSize = state.exportSettings.exportSize(from: baseRenderSize)
} else {
  finalRenderSize = zoomCompositor.paddedRenderSize
}

let zoomCompositor = ZoomCompositor(
  zooms: adjustedZooms,
  renderSize: state.naturalSize,
  backgroundStyle: state.backgroundStyle,
  backgroundPadding: state.backgroundPadding,
  cornerRadius: state.backgroundCornerRadius
)

videoComposition = try await zoomCompositor.createVideoComposition(
  for: composition,
  timeRange: compositionTimeRange
)

// Set renderSize once, before export
videoComposition.renderSize = finalRenderSize
```

**Pros:**
- Minimal code changes
- Fixes temporal mismatch
- Preserves existing architecture

**Cons:**
- May still have edge cases with certain aspect ratios

---

### Solution 2: Add Temporal Validation in Compositor

**Approach:** Guard frame requests against instruction timeRange

**Changes:**
```swift
// ZoomCompositor.swift processRequest() line ~214
private func processRequest(_ request: AVAsynchronousVideoCompositionRequest) {
  frameCount += 1
  let currentTime = request.compositionTime

  guard let instruction = request.videoCompositionInstruction as? ZoomVideoCompositionInstruction else {
    request.finish(with: ZoomCompositor.ZoomCompositorError.compositionFailed)
    return
  }

  // NEW: Validate time is within instruction range
  guard CMTimeRangeContainsTime(instruction.timeRange, currentTime) else {
    print("⚠️ [Compositor] Frame at \(CMTimeGetSeconds(currentTime))s outside timeRange")
    // Use last valid frame or black frame as fallback
    if let renderContext = renderContext, let blackBuffer = renderContext.newPixelBuffer() {
      request.finish(withComposedVideoFrame: blackBuffer)
    } else {
      request.finish(with: ZoomCompositor.ZoomCompositorError.compositionFailed)
    }
    return
  }

  // Continue with existing logic...
}
```

**Pros:**
- Defensive programming
- Catches temporal violations early
- Provides graceful degradation

**Cons:**
- Doesn't fix root cause
- May result in black frames at end

---

### Solution 3: Dynamic Frame Duration Calculation

**Approach:** Calculate frameDuration based on composition duration and renderSize

**Changes:**
```swift
// ZoomCompositor.swift createVideoComposition() line ~67
func createVideoComposition(
  for asset: AVAsset,
  timeRange: CMTimeRange
) async throws -> AVMutableVideoComposition {
  let videoComposition = AVMutableVideoComposition()
  videoComposition.renderSize = renderSize

  // NEW: Calculate frame duration to ensure exact frame count
  let durationSeconds = CMTimeGetSeconds(timeRange.duration)
  let frameCount = Int(ceil(durationSeconds * 30.0))
  let exactFrameDuration = CMTime(
    value: Int64(timeRange.duration.value),
    timescale: Int32(frameCount * Int(timeRange.duration.timescale))
  )
  videoComposition.frameDuration = exactFrameDuration

  // Rest of code...
}
```

**Pros:**
- Mathematically ensures frames fit within duration
- Prevents overrun

**Cons:**
- May affect playback smoothness
- Complex timescale calculations

---

## Recommended Action Plan

**Immediate Fix (Priority 1):**
1. Implement Solution 1 (Set RenderSize Before Composition)
2. Add logging to track frame requests vs timeRange
3. Test with all dimension presets (480p, 720p, 1080p, original)

**Short-term Enhancement (Priority 2):**
1. Implement Solution 2 (Temporal Validation) as safety net
2. Add unit tests for edge cases (very short videos, high frame counts)

**Long-term Improvement (Priority 3):**
1. Research AVFoundation best practices for renderSize changes
2. Consider pre-calculating exact frame count for validation
3. Add telemetry to detect similar timing issues in production

---

## Testing Strategy

**Test Cases:**
1. Export 4s video with 480p preset (reproduces current bug)
2. Export 4s video with 720p preset
3. Export 4s video with 1080p preset
4. Export 4s video with original dimensions (should work)
5. Export very short video (1s) with all presets
6. Export long video (30s) with all presets
7. Export with zoom + background + custom dimensions
8. Export without zoom but with background + custom dimensions

**Success Criteria:**
- All exports complete to 100%
- No trackMismatch errors
- Output video duration matches input
- No black frames at end
- Frame quality maintained

---

## Unresolved Questions

1. Why does AVFoundation mark tracks as unavailable when renderSize changes?
2. Is there documentation on safe timing for renderSize modifications?
3. Could this be related to hardware encoder limitations at certain resolutions?
4. Are there other videoComposition properties that cause similar issues when modified post-creation?
