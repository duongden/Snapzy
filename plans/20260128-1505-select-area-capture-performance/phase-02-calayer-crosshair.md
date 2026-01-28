# Phase 2: CALayer Crosshair

**Status:** Not Started
**Priority:** P0
**Estimated Impact:** -50-100ms per frame, 60fps target

## Context Links

- [Main Plan](./plan.md)
- [Phase 1: Window Pooling](./phase-01-window-pooling.md)
- [Phase 3: SCShareableContent Cache](./phase-03-shareable-content-cache.md)

## Overview

Replace expensive `NSView.draw()` crosshair rendering with CALayer-based approach. CALayers use GPU compositing, bypass CPU-heavy Core Graphics path rendering.

## Key Insights

1. **Current behavior** (lines 345-358): Uses NSBezierPath in `draw()` - CPU-bound, full redraw
2. **mouseMoved triggers** (line 411): `needsDisplay = true` forces complete view redraw
3. **CALayer advantage**: GPU-composited, only changed layer properties update
4. **Animation gotcha**: Must disable implicit CALayer animations for responsive crosshairs

## Requirements

- Replace NSBezierPath crosshair with CAShapeLayer
- Achieve 60fps crosshair movement
- No visual change to crosshair appearance
- Disable implicit layer animations
- Maintain selection rectangle drawing in draw()

## Architecture

```
AreaSelectionOverlayView
├── layer (root CALayer)
│   ├── dimLayer (CALayer - semi-transparent overlay)
│   ├── horizontalCrosshairLayer (CAShapeLayer)
│   ├── verticalCrosshairLayer (CAShapeLayer)
│   └── selectionLayer (CAShapeLayer - selection border)
└── draw() - only handles size indicator text
```

### Layer Hierarchy

```
Root Layer (wantsLayer = true)
    │
    ├── Dim Layer (backgroundColor: black @ 0.4 alpha)
    │
    ├── Horizontal Crosshair (CAShapeLayer)
    │   └── path: horizontal line, strokeColor: white @ 0.6
    │
    ├── Vertical Crosshair (CAShapeLayer)
    │   └── path: vertical line, strokeColor: white @ 0.6
    │
    └── Selection Layer (CAShapeLayer)
        └── path: selection rect, strokeColor: white, fillColor: clear
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Core/AreaSelectionWindow.swift` | AreaSelectionOverlayView target |

## Implementation Steps

### Step 1: Enable Layer-Backed View

```swift
override init(frame: CGRect) {
    super.init(frame: frame)
    wantsLayer = true
    setupLayers()
    setupTrackingArea()
}
```

### Step 2: Create Layer Properties

```swift
// Layer-based rendering
private var dimLayer: CALayer!
private var horizontalCrosshairLayer: CAShapeLayer!
private var verticalCrosshairLayer: CAShapeLayer!
private var selectionBorderLayer: CAShapeLayer!
private var selectionClearLayer: CALayer!
```

### Step 3: Setup Layers

```swift
private func setupLayers() {
    guard let rootLayer = layer else { return }

    // Disable implicit animations globally for sublayers
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    // Dim overlay layer
    dimLayer = CALayer()
    dimLayer.backgroundColor = NSColor.black.withAlphaComponent(0.4).cgColor
    dimLayer.frame = bounds
    dimLayer.actions = disabledActions
    rootLayer.addSublayer(dimLayer)

    // Horizontal crosshair
    horizontalCrosshairLayer = CAShapeLayer()
    horizontalCrosshairLayer.strokeColor = NSColor.white.withAlphaComponent(0.6).cgColor
    horizontalCrosshairLayer.lineWidth = 1.0
    horizontalCrosshairLayer.actions = disabledActions
    rootLayer.addSublayer(horizontalCrosshairLayer)

    // Vertical crosshair
    verticalCrosshairLayer = CAShapeLayer()
    verticalCrosshairLayer.strokeColor = NSColor.white.withAlphaComponent(0.6).cgColor
    verticalCrosshairLayer.lineWidth = 1.0
    verticalCrosshairLayer.actions = disabledActions
    rootLayer.addSublayer(verticalCrosshairLayer)

    // Selection border layer
    selectionBorderLayer = CAShapeLayer()
    selectionBorderLayer.strokeColor = NSColor.white.cgColor
    selectionBorderLayer.fillColor = nil
    selectionBorderLayer.lineWidth = 2.0
    selectionBorderLayer.isHidden = true
    selectionBorderLayer.actions = disabledActions
    rootLayer.addSublayer(selectionBorderLayer)

    // Selection clear area (mask for dim layer)
    selectionClearLayer = CALayer()
    selectionClearLayer.backgroundColor = NSColor.black.cgColor
    selectionClearLayer.isHidden = true

    CATransaction.commit()
}

// Disable all implicit animations
private var disabledActions: [String: CAAction] {
    return [
        "position": NSNull(),
        "bounds": NSNull(),
        "path": NSNull(),
        "hidden": NSNull(),
        "opacity": NSNull(),
        "backgroundColor": NSNull()
    ]
}
```

### Step 4: Update Crosshair on Mouse Move

```swift
override func mouseMoved(with event: NSEvent) {
    currentMousePosition = convert(event.locationInWindow, from: nil)

    if !isSelecting {
        updateCrosshairLayers()
    }
}

private func updateCrosshairLayers() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    // Show crosshairs
    horizontalCrosshairLayer.isHidden = false
    verticalCrosshairLayer.isHidden = false

    // Horizontal line path
    let hPath = CGMutablePath()
    hPath.move(to: CGPoint(x: 0, y: currentMousePosition.y))
    hPath.addLine(to: CGPoint(x: bounds.width, y: currentMousePosition.y))
    horizontalCrosshairLayer.path = hPath

    // Vertical line path
    let vPath = CGMutablePath()
    vPath.move(to: CGPoint(x: currentMousePosition.x, y: 0))
    vPath.addLine(to: CGPoint(x: currentMousePosition.x, y: bounds.height))
    verticalCrosshairLayer.path = vPath

    CATransaction.commit()
}
```

### Step 5: Update Selection Rectangle

```swift
override func mouseDragged(with event: NSEvent) {
    guard isSelecting else { return }
    selectionEndPoint = convert(event.locationInWindow, from: nil)
    updateSelectionLayers()
}

private func updateSelectionLayers() {
    guard let rect = calculateSelectionRect() else { return }

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    // Hide crosshairs during selection
    horizontalCrosshairLayer.isHidden = true
    verticalCrosshairLayer.isHidden = true

    // Show selection border
    selectionBorderLayer.isHidden = false
    selectionBorderLayer.path = CGPath(rect: rect, transform: nil)

    // Update dim layer mask to clear selection area
    updateDimLayerMask(for: rect)

    CATransaction.commit()

    // Trigger draw() only for size indicator text
    needsDisplay = true
}

private func updateDimLayerMask(for selectionRect: CGRect) {
    // Create mask that clears the selection area
    let maskLayer = CAShapeLayer()
    let path = CGMutablePath()
    path.addRect(bounds)
    path.addRect(selectionRect)
    maskLayer.path = path
    maskLayer.fillRule = .evenOdd
    dimLayer.mask = maskLayer
}
```

### Step 6: Simplify draw() Method

```swift
override func draw(_ dirtyRect: NSRect) {
    // Only draw size indicator - layers handle everything else
    if isSelecting, let rect = calculateSelectionRect() {
        drawSizeIndicator(for: rect)
    }
}
```

### Step 7: Reset Layers on Selection Reset

```swift
func resetSelection() {
    isSelecting = false
    selectionStartPoint = nil
    selectionEndPoint = nil
    currentMousePosition = .zero

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    // Reset layers
    horizontalCrosshairLayer.isHidden = false
    verticalCrosshairLayer.isHidden = false
    selectionBorderLayer.isHidden = true
    dimLayer.mask = nil

    // Reset dim layer to cover full view
    dimLayer.frame = bounds

    CATransaction.commit()

    needsDisplay = true
}
```

### Step 8: Handle Layout Changes

```swift
override func layout() {
    super.layout()

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    dimLayer.frame = bounds

    CATransaction.commit()
}
```

## Todo List

- [ ] Add `wantsLayer = true` to init
- [ ] Create layer property declarations
- [ ] Implement `setupLayers()` method
- [ ] Add `disabledActions` computed property
- [ ] Update `mouseMoved()` to use `updateCrosshairLayers()`
- [ ] Implement `updateCrosshairLayers()` method
- [ ] Update `mouseDragged()` to use `updateSelectionLayers()`
- [ ] Implement `updateSelectionLayers()` method
- [ ] Implement `updateDimLayerMask()` method
- [ ] Simplify `draw()` to only handle size indicator
- [ ] Update `resetSelection()` to reset layers
- [ ] Add `layout()` override for frame updates
- [ ] Remove old `drawCrosshair()` and `drawSelection()` methods
- [ ] Test crosshair smoothness at 60fps
- [ ] Test selection rectangle appearance

## Success Criteria

- [ ] Crosshair movement at 60fps
- [ ] No visual artifacts during selection
- [ ] Selection rectangle renders correctly
- [ ] Size indicator still displays
- [ ] Clear area in dim overlay for selection
- [ ] No CALayer animation interference

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Animation not disabled | High | High | Use NSNull() actions + CATransaction |
| Layer ordering wrong | Medium | Medium | Test visibility of each layer |
| Mask performance | Low | Medium | Simple rect mask, minimal overhead |
| Retina scaling issues | Medium | Medium | Use contentsScale from backing |

## Security Considerations

- No security impact - rendering optimization only

## Next Steps

After completing Phase 2:
1. Profile with Instruments to verify 60fps
2. Combine with Phase 1 for cumulative measurement
3. Proceed to Phase 3 if <150ms not yet achieved
