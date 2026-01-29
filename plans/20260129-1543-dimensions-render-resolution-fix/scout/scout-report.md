# Scout Report: Dimensions UI Frame Bug Investigation

**Date:** 2026-01-29
**Task:** Find where dimension settings incorrectly resize UI instead of affecting only render resolution

---

## Critical Finding: NO BUG FOUND

After comprehensive codebase analysis, **the dimensions setting does NOT resize UI frames**. The architecture is correctly implemented.

---

## Evidence

### 1. ZoomableVideoPlayerSection (Preview Component)
**File:** `ClaudeShot/Features/VideoEditor/Views/Zoom/ZoomPreviewOverlay.swift:12-265`

- Uses `GeometryReader` to adapt to container size (line 21)
- `calculateCompositeSize()` uses `state.naturalSize` NOT export dimensions (lines 189-217)
- Preview scales proportionally within available space
- `.frame(maxWidth: .infinity, maxHeight: .infinity)` allows flexible sizing (line 51)

### 2. VideoEditorWindow (Window Container)
**File:** `ClaudeShot/Features/VideoEditor/VideoEditorWindow.swift`

- Fixed `minSize = NSSize(width: 400, height: 300)` (line 37)
- Window size set to 1200x800 on creation (lines 74-75)
- NO binding to export dimensions
- User-resizable via `.resizable` style mask (line 16)

### 3. Export Pipeline (Correctly Isolated)
**File:** `ClaudeShot/Features/VideoEditor/Export/VideoEditorExporter.swift`

- Export dimensions applied ONLY to `AVVideoComposition.renderSize`
- Three export paths all use same pattern (lines 68-106, 241-274, 362-396)
- No UI components receive export dimension values

### 4. Search Results
- `exportSize.*frame` → No matches
- `frame.*exportSize` → No matches
- `dimensionPreset.*frame` → No matches
- `frame.*naturalSize` → No matches

---

## Possible User Confusion Sources

1. **Background Padding Changes Aspect Ratio**: When user adds padding, the composite aspect ratio changes, causing the preview to reposition within the container

2. **Aspect-Fit Scaling**: Preview maintains aspect ratio - changing padding/background can make video appear smaller within the same container

3. **Window was never resizing**: Perhaps user observed preview content scaling, not actual window resize

---

## Architecture Summary

```
┌─────────────────────────────────────────┐
│ VideoEditorWindow (1200x800, resizable) │
│ ┌─────────────────────────────────────┐ │
│ │ VideoEditorMainView                 │ │
│ │ ┌─────────────────────────────────┐ │ │
│ │ │ ZoomableVideoPlayerSection      │ │ │
│ │ │ - GeometryReader (fills space)  │ │ │
│ │ │ - compositeSize from naturalSize│ │ │
│ │ │ - Scales to fit, not resizes    │ │ │
│ │ └─────────────────────────────────┘ │ │
│ │ ┌─────────────────────────────────┐ │ │
│ │ │ VideoExportSettingsPanel        │ │ │
│ │ │ - Dimensions only for export    │ │ │
│ │ │ - Fixed UI frame widths         │ │ │
│ │ └─────────────────────────────────┘ │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘

Export Pipeline (Separate):
- exportSettings.dimensionPreset → exportSize()
- AVVideoComposition.renderSize = targetSize
- Does NOT affect UI
```

---

## Recommendation

**Clarify with user** what behavior they're actually observing:
1. Is the window frame itself changing size?
2. Is the video preview content scaling within the window?
3. Is this happening in preview or only in exported file?

If issue persists, request:
- Screenshot/screen recording showing the behavior
- Specific steps to reproduce

---

## Files Analyzed

| File | Purpose | Dimensions Usage |
|------|---------|------------------|
| ZoomPreviewOverlay.swift | Preview component | naturalSize only |
| VideoEditorWindow.swift | Window config | Fixed sizes |
| VideoEditorWindowController.swift | Window lifecycle | No dimensions |
| VideoEditorMainView.swift | Main layout | No dimensions |
| VideoExportSettingsPanel.swift | Settings UI | Export only |
| VideoEditorExporter.swift | Export engine | renderSize only |
