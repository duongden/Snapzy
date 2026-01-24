# Phase 3: Preview Integration

**Parent:** [plan.md](./plan.md)
**Dependencies:** [Phase 1](./phase-01-state-management.md), [Phase 2](./phase-02-sidebar-ui-components.md)
**Date:** 2026-01-24
**Priority:** High
**Status:** Pending
**Review:** Not Started

## Overview

Modify video player preview to display background/padding effects in real-time during editing.

## Key Insights

- Current `VideoPlayerSection` is simple AVPlayerView wrapper
- `ZoomableVideoPlayerSection` handles zoom preview overlay
- SwiftUI ZStack approach is performant for backgrounds
- Corner radius + shadow can coexist using SwiftUI modifier ordering
- Performance impact <15% on modern Macs (research confirmed)

## Requirements

1. Wrap video player with background layer
2. Apply padding to create visible background area
3. Add corner radius and shadow to video frame
4. Respect alignment settings for video position
5. Maintain smooth playback performance

## Related Files

| File | Action |
|------|--------|
| `ClaudeShot/Features/VideoEditor/Views/VideoPlayerSection.swift` | Reference |
| `ClaudeShot/Features/VideoEditor/Views/VideoEditorMainView.swift` | Modify |

## Architecture

```
ZStack (background container)
├── BackgroundView (gradient/solid/none)
│   └── Respects aspectRatio setting
└── VideoPlayerSection
    ├── .padding(state.backgroundPadding)
    ├── .cornerRadius(state.backgroundCornerRadius)
    └── .shadow(opacity: state.backgroundShadowIntensity)
```

## Implementation Steps

### Step 1: Create BackgroundView Helper

```swift
@ViewBuilder
private func backgroundView() -> some View {
  switch state.backgroundStyle {
  case .none:
    Color.clear
  case .gradient(let preset):
    LinearGradient(
      colors: preset.colors,
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  case .solidColor(let color):
    color
  case .wallpaper(let url):
    AsyncImage(url: url) { image in
      image.resizable().aspectRatio(contentMode: .fill)
    } placeholder: {
      Color.gray
    }
  case .blurred(let url):
    AsyncImage(url: url) { image in
      image.resizable().aspectRatio(contentMode: .fill).blur(radius: 20)
    } placeholder: {
      Color.gray
    }
  }
}
```

### Step 2: Modify ZoomableVideoPlayerSection

Wrap existing content with background:

```swift
var body: some View {
  GeometryReader { geometry in
    ZStack {
      // Background layer
      if state.backgroundStyle != .none {
        backgroundView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      // Video with effects
      videoPlayerContent
        .cornerRadius(state.backgroundCornerRadius)
        .shadow(
          color: .black.opacity(Double(state.backgroundShadowIntensity) * 0.5),
          radius: CGFloat(state.backgroundShadowIntensity) * 20,
          x: 0,
          y: CGFloat(state.backgroundShadowIntensity) * 10
        )
        .padding(state.backgroundPadding)
    }
  }
}
```

### Step 3: Handle Alignment

Apply alignment based on `state.backgroundAlignment`:

```swift
private var alignmentValue: Alignment {
  switch state.backgroundAlignment {
  case .topLeft: return .topLeading
  case .top: return .top
  case .topRight: return .topTrailing
  case .left: return .leading
  case .center: return .center
  case .right: return .trailing
  case .bottomLeft: return .bottomLeading
  case .bottom: return .bottom
  case .bottomRight: return .bottomTrailing
  }
}
```

### Step 4: Handle Aspect Ratio

Calculate container size based on `state.backgroundAspectRatio`.

## Todo List

- [ ] Create backgroundView() helper function
- [ ] Wrap video player with ZStack + background
- [ ] Apply padding modifier from state
- [ ] Apply cornerRadius modifier from state
- [ ] Apply shadow modifier from state
- [ ] Implement alignment positioning
- [ ] Handle aspect ratio constraints
- [ ] Test playback performance with effects
- [ ] Verify zoom overlay still works correctly

## Success Criteria

- [ ] Background displays correctly for all style types
- [ ] Padding creates visible background border
- [ ] Corner radius clips video content
- [ ] Shadow renders around video frame
- [ ] Alignment positions video correctly
- [ ] Playback remains smooth (>30fps)
- [ ] Zoom preview overlay still functional

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Performance degradation | Low | Medium | Profile with Instruments |
| Zoom overlay conflicts | Medium | Medium | Test layer ordering |
| Aspect ratio calculation errors | Medium | Low | Use GeometryReader |

## Security Considerations

- Wallpaper URLs from local filesystem only (validated by file picker)
- No remote URL loading

## Next Steps

After completion, proceed to [Phase 4: Export Pipeline](./phase-04-export-pipeline.md)
