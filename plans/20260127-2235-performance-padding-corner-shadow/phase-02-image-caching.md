# Phase 02: Wallpaper Image Caching

## Context
- Parent: [plan.md](plan.md)
- Dependencies: None (can run parallel to Phase 01)

## Overview
- **Date:** 2026-01-27
- **Priority:** Critical
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
**Critical Bug Found:** In `backgroundLayer()` at line 204:
```swift
case .wallpaper(let url):
  if let nsImage = NSImage(contentsOf: url) {  // ← LOADED EVERY RENDER!
```

This loads the wallpaper image from disk on EVERY view update. During slider drag = 60+ disk reads/second.

## Requirements
- Cache wallpaper image in memory after first load
- Invalidate cache only when wallpaper URL changes
- Reduce disk I/O during slider interactions to zero

## Architecture

### Current Flow (Problematic)
```
Slider tick → View re-render → backgroundLayer() →
NSImage(contentsOf: url) → DISK READ → Image view created → LAG
```

### Proposed Flow
```
Wallpaper selected → Load once → Cache in AnnotateState
Slider tick → View re-render → Use cached NSImage → FAST
```

## Related Code Files
- [AnnotateCanvasView.swift:170-235](../../ClaudeShot/Features/Annotate/Views/AnnotateCanvasView.swift#L170-L235) - backgroundLayer
- [AnnotateState.swift:50](../../ClaudeShot/Features/Annotate/State/AnnotateState.swift#L50) - backgroundStyle

## Implementation Steps

### Step 1: Add Cached Image to AnnotateState
```swift
// In AnnotateState.swift
@Published var backgroundStyle: BackgroundStyle = .none {
  didSet {
    // Pre-cache wallpaper image when style changes
    if case .wallpaper(let url) = backgroundStyle {
      loadWallpaperImage(from: url)
    } else {
      cachedWallpaperImage = nil
    }
  }
}

/// Cached wallpaper image for performance
private(set) var cachedWallpaperImage: NSImage?

private func loadWallpaperImage(from url: URL) {
  // Skip preset URLs (handled differently)
  guard url.scheme != "preset" else {
    cachedWallpaperImage = nil
    return
  }
  cachedWallpaperImage = NSImage(contentsOf: url)
}
```

### Step 2: Update backgroundLayer to Use Cache
```swift
// In AnnotateCanvasView.swift backgroundLayer()
case .wallpaper(let url):
  if url.scheme == "preset", let presetName = url.host,
     let preset = WallpaperPreset(rawValue: presetName) {
    // Preset gradient - unchanged
    RoundedRectangle(cornerRadius: state.cornerRadius)
      .fill(preset.gradient)
      ...
  } else if let nsImage = state.cachedWallpaperImage {
    // Use CACHED image instead of loading from URL
    Image(nsImage: nsImage)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: width, height: height)
      .clipped()
      .cornerRadius(state.cornerRadius)
  }
```

### Step 3: Handle Blurred Background Similarly
Same pattern for `.blurred(let url)` case - cache the blurred image.

## Todo List
- [ ] Add cachedWallpaperImage property to AnnotateState
- [ ] Implement didSet on backgroundStyle to trigger caching
- [ ] Update backgroundLayer() to use cached image
- [ ] Apply same pattern to blurred backgrounds
- [ ] Test with large wallpaper images

## Success Criteria
- Zero disk reads during slider drag
- Wallpaper displays correctly after caching
- Memory usage reasonable (single cached image)

## Risk Assessment
- **Medium Risk:** Memory increase for large wallpapers
- **Mitigation:** Only cache current wallpaper, clear on change

## Security Considerations
None - local file caching only

## Next Steps
After completing, proceed to [Phase 03: Render Optimization](phase-03-render-optimization.md)
