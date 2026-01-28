# Select Area Capture Performance Optimization Plan

**Created:** 260128
**Target:** Reduce overlay initialization from 400-600ms to 0-150ms
**Benchmark:** CleanShot X performance

## Executive Summary

Current `AreaSelectionWindow.swift` creates new windows per-activation, uses expensive NSView.draw() for rendering, and lacks pre-warming. This plan implements 4 phases to achieve sub-150ms overlay appearance.

## Current Bottlenecks

| Issue | Location | Impact |
|-------|----------|--------|
| Window creation per-activation | Lines 52-57 | ~200-300ms |
| NSView.draw() for crosshairs | Lines 345-358 | ~50-100ms per frame |
| Full view redraws on mouseMoved | Line 411 | Cumulative lag |
| No SCShareableContent caching | ScreenCaptureManager | ~30ms-6s first call |
| Synchronous display() calls | Lines 381, 388 | Blocks main thread |

## Phase Overview

| Phase | Title | Est. Impact | Priority |
|-------|-------|-------------|----------|
| [Phase 1](./phase-01-window-pooling.md) | Window Pooling | -200-300ms | P0 |
| [Phase 2](./phase-02-calayer-crosshair.md) | CALayer Crosshair | -50-100ms | P0 |
| [Phase 3](./phase-03-shareable-content-cache.md) | SCShareableContent Cache | -30ms-6s | P1 |
| [Phase 4](./phase-04-rendering-optimization.md) | Rendering Optimization | -20-50ms | P1 |

## Implementation Status

- [x] Phase 1: Window Pooling
- [x] Phase 2: CALayer Crosshair
- [ ] Phase 3: SCShareableContent Cache
- [ ] Phase 4: Rendering Optimization

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Overlay appearance time | 400-600ms | 0-150ms |
| Frame rate during selection | ~30fps | 60fps |
| Memory footprint | Low (no pool) | Moderate (pooled) |

## Key Files

- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/AreaSelectionWindow.swift`
- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/ScreenCaptureManager.swift`

## Architecture Decisions

1. **Hybrid AppKit + CALayer**: Keep NSWindow/NSView for event handling, use CALayer for rendering
2. **Pre-allocation on app launch**: Create hidden windows during app init
3. **Background SCShareableContent fetch**: Cache on foreground, refresh on display change
4. **Dirty rect updates**: Only redraw changed regions, not full view

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Memory overhead from pooling | Limit pool size to screen count |
| Stale display cache | Refresh on NSApplication.didChangeScreenParametersNotification |
| CALayer animation interference | Disable implicit animations via layer.actions |

## Dependencies

- macOS 14.0+ (ScreenCaptureKit APIs)
- No external dependencies

## Next Steps

1. Start with Phase 1 (Window Pooling) - highest impact
2. Phase 2 can run in parallel if resources available
3. Phase 3 + 4 after core optimizations validated
