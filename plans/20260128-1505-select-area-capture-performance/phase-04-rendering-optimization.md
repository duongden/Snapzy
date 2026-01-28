# Phase 4: Rendering Optimization

**Status:** Not Started
**Priority:** P1
**Estimated Impact:** -20-50ms, smoother interaction

## Context Links

- [Main Plan](./plan.md)
- [Phase 3: SCShareableContent Cache](./phase-03-shareable-content-cache.md)

## Overview

Fine-tune rendering performance by eliminating unnecessary redraws, using dirty rect updates, and optimizing view hierarchy. This phase polishes the performance gains from earlier phases.

## Key Insights

1. **Current display() calls** (lines 381, 388): `display()` forces synchronous full redraw
2. **Full view redraws**: Every mouse event triggers complete view redraw
3. **draw() overhead**: Even with CALayer, draw() still called for size indicator
4. **Window configuration**: Some window properties may cause unnecessary compositing

## Requirements

- Replace display() with setNeedsDisplay(in:) for dirty rects
- Move size indicator to CATextLayer
- Optimize window configuration for minimal compositing
- Use drawsAsynchronously for high-frequency layer updates
- Profile and eliminate any remaining bottlenecks

## Architecture

### Dirty Rect Strategy

```
Instead of: needsDisplay = true (redraws entire view)
Use: setNeedsDisplay(in: dirtyRect) (redraws only changed area)

For crosshairs:
- Track previous position
- Invalidate old + new crosshair rects only

For selection:
- Invalidate selection rect + padding for border
```

### Size Indicator Layer

```
Replace draw() text rendering with:
CATextLayer
├── string: "1920 x 1080"
├── font: NSFont.systemFont
├── fontSize: 12
├── foregroundColor: white
├── backgroundColor: black @ 0.7
├── cornerRadius: 4
└── position: calculated from selection rect
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Core/AreaSelectionWindow.swift` | AreaSelectionOverlayView target |

## Implementation Steps

### Step 1: Remove display() Calls

Replace synchronous display() with needsDisplay:

```swift
override func mouseDown(with event: NSEvent) {
    let point = convert(event.locationInWindow, from: nil)
    selectionStartPoint = point
    selectionEndPoint = point
    isSelecting = true

    // Don't use display() - let layers handle it
    updateSelectionLayers()
}

override func mouseDragged(with event: NSEvent) {
    guard isSelecting else { return }
    selectionEndPoint = convert(event.locationInWindow, from: nil)

    // Don't use display() - layers update directly
    updateSelectionLayers()
}
```

### Step 2: Add Size Indicator Layer

```swift
private var sizeIndicatorLayer: CATextLayer!
private var sizeIndicatorBackgroundLayer: CALayer!

private func setupLayers() {
    // ... existing layer setup ...

    // Size indicator background
    sizeIndicatorBackgroundLayer = CALayer()
    sizeIndicatorBackgroundLayer.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor
    sizeIndicatorBackgroundLayer.cornerRadius = 4
    sizeIndicatorBackgroundLayer.isHidden = true
    sizeIndicatorBackgroundLayer.actions = disabledActions
    rootLayer.addSublayer(sizeIndicatorBackgroundLayer)

    // Size indicator text
    sizeIndicatorLayer = CATextLayer()
    sizeIndicatorLayer.font = NSFont.systemFont(ofSize: 12, weight: .medium)
    sizeIndicatorLayer.fontSize = 12
    sizeIndicatorLayer.foregroundColor = NSColor.white.cgColor
    sizeIndicatorLayer.alignmentMode = .center
    sizeIndicatorLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
    sizeIndicatorLayer.isHidden = true
    sizeIndicatorLayer.actions = disabledActions
    rootLayer.addSublayer(sizeIndicatorLayer)
}
```

### Step 3: Update Size Indicator Layer

```swift
private func updateSizeIndicatorLayer(for rect: CGRect) {
    let text = "\(Int(rect.width)) x \(Int(rect.height))"
    sizeIndicatorLayer.string = text

    // Calculate text size
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium)
    ]
    let textSize = (text as NSString).size(withAttributes: attributes)

    // Position below selection rect
    var indicatorFrame = CGRect(
        x: rect.maxX - textSize.width - 16,
        y: rect.minY - textSize.height - 12,
        width: textSize.width + 16,
        height: textSize.height + 8
    )

    // Keep within bounds
    if indicatorFrame.minY < 0 {
        indicatorFrame.origin.y = rect.maxY + 4
    }
    if indicatorFrame.maxX > bounds.maxX {
        indicatorFrame.origin.x = rect.minX
    }

    sizeIndicatorBackgroundLayer.frame = indicatorFrame
    sizeIndicatorLayer.frame = indicatorFrame

    sizeIndicatorBackgroundLayer.isHidden = false
    sizeIndicatorLayer.isHidden = false
}
```

### Step 4: Remove draw() Override

```swift
// DELETE the entire draw() override - all rendering now via layers
// override func draw(_ dirtyRect: NSRect) { ... }
```

### Step 5: Enable Async Drawing for Layers

```swift
private func setupLayers() {
    guard let rootLayer = layer else { return }

    // Enable async drawing for high-frequency updates
    rootLayer.drawsAsynchronously = true

    // ... rest of layer setup ...
}
```

### Step 6: Optimize Window Configuration

Update `AreaSelectionWindow.init`:

```swift
init(screen: NSScreen, pooled: Bool = false) {
    // ... existing init ...

    // Optimize for performance
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = false

    // Disable Core Animation implicit animations at window level
    self.animationBehavior = .none

    // Use .buffered backing for best performance with layers
    // (already set in super.init)
}
```

### Step 7: Add Dirty Rect Tracking for Fallback

If any draw() usage remains:

```swift
private var previousCrosshairPosition: CGPoint = .zero

private func dirtyRectForCrosshair(at point: CGPoint) -> CGRect {
    // Vertical line rect
    let vRect = CGRect(x: point.x - 1, y: 0, width: 3, height: bounds.height)
    // Horizontal line rect
    let hRect = CGRect(x: 0, y: point.y - 1, width: bounds.width, height: 3)
    return vRect.union(hRect)
}

override func mouseMoved(with event: NSEvent) {
    let newPosition = convert(event.locationInWindow, from: nil)

    if !isSelecting {
        // Invalidate old position
        let oldDirty = dirtyRectForCrosshair(at: previousCrosshairPosition)
        setNeedsDisplay(oldDirty)

        // Invalidate new position
        let newDirty = dirtyRectForCrosshair(at: newPosition)
        setNeedsDisplay(newDirty)

        previousCrosshairPosition = newPosition
    }

    currentMousePosition = newPosition
    updateCrosshairLayers()
}
```

### Step 8: Profile and Optimize

Use Instruments to identify remaining bottlenecks:

```bash
# Run with Time Profiler
xcrun xctrace record --template 'Time Profiler' --launch ClaudeShot.app

# Run with Core Animation instrument
xcrun xctrace record --template 'Core Animation' --launch ClaudeShot.app
```

## Todo List

- [ ] Remove `display()` calls from mouseDown/mouseDragged
- [ ] Add `sizeIndicatorLayer` and `sizeIndicatorBackgroundLayer`
- [ ] Implement `updateSizeIndicatorLayer(for:)` method
- [ ] Remove `draw()` override entirely
- [ ] Remove `drawSizeIndicator()`, `drawCrosshair()`, `drawSelection()` methods
- [ ] Enable `drawsAsynchronously` on root layer
- [ ] Set `animationBehavior = .none` on window
- [ ] Add dirty rect tracking if any draw() fallback needed
- [ ] Profile with Instruments Time Profiler
- [ ] Profile with Core Animation instrument
- [ ] Verify 60fps in all scenarios
- [ ] Test on non-Retina displays

## Success Criteria

- [ ] No draw() method in AreaSelectionOverlayView
- [ ] All rendering via CALayers
- [ ] 60fps during crosshair movement
- [ ] 60fps during selection drag
- [ ] Size indicator displays correctly
- [ ] No visual glitches or artifacts
- [ ] CPU usage minimal during interaction

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| CATextLayer font rendering | Low | Low | Use system font, proper contentsScale |
| Layer ordering issues | Low | Medium | Test layer visibility order |
| Retina scaling | Medium | Medium | Set contentsScale from screen |
| Accessibility impact | Low | Low | Size indicator still visible |

## Security Considerations

- No security impact - rendering optimization only

## Performance Verification

After all phases complete, verify:

```swift
// Add timing to AreaSelectionController.startSelection()
func startSelection(mode: SelectionMode, completion: @escaping AreaSelectionCompletionWithMode) {
    let startTime = CFAbsoluteTimeGetCurrent()

    // ... existing code ...

    // After windows are visible
    let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
    print("[Performance] Overlay appeared in \(elapsed)ms")
}
```

Target: `< 150ms` consistently

## Next Steps

After completing all phases:
1. Run comprehensive performance tests
2. Document final metrics vs baseline
3. Create automated performance regression test
4. Update documentation with architecture changes
