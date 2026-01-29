# Plan: Dimensions Render Resolution Fix

**Date:** 2026-01-29
**Status:** Not Started
**Objective:** Fix preview to show scaled video at target dimensions instead of cropping

## Problem Statement

When user selects dimension preset (720p, 1080p, etc.), preview shows CROPPED video instead of SCALED video. Export pipeline correctly scales, but preview uses `naturalSize` instead of `exportSize`.

## Root Cause

`ZoomPreviewOverlay.swift` methods use `state.naturalSize` for calculations:
- `previewScaleFactor()` (lines 156-183): calculates scale from naturalSize
- `calculateCompositeSize()` (lines 189-217): uses naturalSize for aspect ratio

Should use `state.exportSettings.exportSize(from: state.naturalSize)` to match export behavior.

## Solution Overview

Update both methods to use export dimensions when dimension preset is not `.original`:
1. Get effective size via `exportSize(from:)`
2. Calculate composite aspect from effective size + padding
3. Scale preview to show full video at target resolution

## Architecture

```
Current (Bug):
  Preview: naturalSize (1920x1080) -> shows full video
  Export:  exportSize (1280x720)  -> scales to 720p
  Result:  Preview != Export (WYSIWYG broken)

Fixed:
  Preview: exportSize (1280x720) -> shows scaled video
  Export:  exportSize (1280x720) -> scales to 720p
  Result:  Preview == Export (WYSIWYG restored)
```

## Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Fix preview dimension calculation | Not Started |
| 02 | Build and verify | Not Started |

## Files Modified

| File | Changes |
|------|---------|
| `ZoomPreviewOverlay.swift` | Update `previewScaleFactor()` and `calculateCompositeSize()` |

## Success Criteria

1. Preview shows full video scaled to target dimensions
2. No cropping when selecting 720p/1080p/etc.
3. Exported video matches preview (WYSIWYG)
4. Build succeeds with no warnings
