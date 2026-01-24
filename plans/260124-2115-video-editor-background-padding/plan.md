# Video Editor Background & Padding Feature

**Date:** 2026-01-24
**Status:** Planning
**Priority:** High

## Overview

Add professional background/padding customization to Video Editor sidebar, similar to existing Annotate feature. Enables users to export videos with gradient/solid backgrounds, padding, shadows, and corner radius for professional presentation.

## Implementation Phases

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 1 | [State Management](./phase-01-state-management.md) | Pending | 0% |
| 2 | [Sidebar UI Components](./phase-02-sidebar-ui-components.md) | Pending | 0% |
| 3 | [Preview Integration](./phase-03-preview-integration.md) | Pending | 0% |
| 4 | [Export Pipeline](./phase-04-export-pipeline.md) | Pending | 0% |

## Architecture Summary

```
VideoEditorState (extended)
    ├── backgroundStyle: BackgroundStyle
    ├── padding: CGFloat
    ├── shadowIntensity: CGFloat
    ├── cornerRadius: CGFloat
    └── imageAlignment: ImageAlignment

VideoBackgroundSidebarView (new)
    ├── Reuses: BackgroundStyle, GradientPreset, AspectRatioOption
    └── Reuses: SidebarSectionHeader, GradientPresetButton, CompactSliderRow

ZoomableVideoPlayerSection (modified)
    └── Wraps player with background/padding overlay

ZoomCompositor (extended)
    └── Renders background during export via CIFilter compositing
```

## Key Decisions

1. **Reuse existing types** from `Annotate/Background/BackgroundStyle.swift`
2. **CIFilter approach** for export (matches existing ZoomCompositor pattern)
3. **SwiftUI ZStack** for preview (performant, simple)
4. **Separate sidebar** for background settings (keeps VideoDetailsSidebarView focused)

## Research References

- [AVFoundation Compositing](./research/researcher-01-avfoundation-compositing.md)
- [SwiftUI Video Preview](./research/researcher-02-swiftui-video-preview.md)

## Estimated Scope

- **Files to modify:** 4
- **Files to create:** 2
- **Lines of code:** ~400-500
