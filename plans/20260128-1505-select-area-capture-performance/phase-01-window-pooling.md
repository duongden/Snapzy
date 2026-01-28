# Phase 1: Window Pooling

**Status:** Not Started
**Priority:** P0
**Estimated Impact:** -200-300ms

## Context Links

- [Main Plan](./plan.md)
- [Phase 2: CALayer Crosshair](./phase-02-calayer-crosshair.md)

## Overview

Pre-allocate overlay windows at app launch and reuse them via show/hide instead of create/destroy per activation. CleanShot X uses this pattern - maintains hidden `NSPanel` windows, toggles `orderFront:` for instant appearance.

## Key Insights

1. **Current behavior** (lines 52-57): Creates new `AreaSelectionWindow` for EACH screen on EVERY selection start
2. **NSWindow creation cost**: Window creation involves Quartz compositor registration, ~100-150ms per window
3. **Multi-monitor compound cost**: 2+ displays = 200-300ms+ just for window creation
4. **CleanShot approach**: Pre-allocate hidden panels, reuse via `orderFront:`/`orderOut:`

## Requirements

- Pre-allocate windows during app initialization
- Support dynamic screen configuration changes
- Maintain all existing selection functionality
- No visible flash or artifacts during activation
- Memory-efficient (don't over-allocate)

## Architecture

```
AreaSelectionController
├── windowPool: [CGDirectDisplayID: AreaSelectionWindow]
├── prepareWindows() - called on app launch
├── refreshWindowPool() - called on screen changes
├── activateWindows() - show pooled windows
└── deactivateWindows() - hide (not close) windows
```

### State Machine

```
[App Launch] -> prepareWindows() -> [Windows Hidden]
                                          |
[User Triggers Selection] ----------------+
                                          v
                              activateWindows() -> [Windows Visible]
                                          |
[Selection Complete/Cancel] --------------+
                                          v
                              deactivateWindows() -> [Windows Hidden]
                                          |
[Screen Config Change] -------------------+
                                          v
                              refreshWindowPool() -> [Pool Updated]
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Core/AreaSelectionWindow.swift` | Main target - AreaSelectionController |
| `ClaudeShot/App/StatusBarController.swift` | App lifecycle hooks |
| `ClaudeShot/ClaudeShotApp.swift` | App entry point |

## Implementation Steps

### Step 1: Create WindowPoolManager

Add to `AreaSelectionController`:

```swift
// Window pool keyed by display ID
private var windowPool: [CGDirectDisplayID: AreaSelectionWindow] = [:]
private var isPoolReady = false

/// Called once on app launch to pre-allocate windows
func prepareWindowPool() {
    guard !isPoolReady else { return }

    for screen in NSScreen.screens {
        guard let displayID = screen.displayID else { continue }
        let window = createPooledWindow(for: screen)
        windowPool[displayID] = window
    }

    setupScreenChangeObserver()
    isPoolReady = true
}
```

### Step 2: Modify Window Creation

Update `AreaSelectionWindow.init`:

```swift
init(screen: NSScreen, pooled: Bool = false) {
    // ... existing init code ...

    if pooled {
        // Don't order front immediately for pooled windows
        self.orderOut(nil)
    } else {
        self.makeKeyAndOrderFront(nil)
        self.makeMain()
    }
}
```

### Step 3: Update startSelection()

Replace window creation loop:

```swift
func startSelection(mode: SelectionMode, completion: @escaping AreaSelectionCompletionWithMode) {
    self.selectionMode = mode
    self.completionWithMode = completion

    // Ensure pool is ready
    if !isPoolReady {
        prepareWindowPool()
    }

    // Activate pooled windows (show, don't create)
    activatePooledWindows()

    // Setup escape monitors...
}

private func activatePooledWindows() {
    for screen in NSScreen.screens {
        guard let displayID = screen.displayID,
              let window = windowPool[displayID] else {
            // Fallback: create window if not pooled
            let window = AreaSelectionWindow(screen: screen)
            window.selectionDelegate = self
            windowPool[displayID] = window
            window.orderFrontRegardless()
            continue
        }

        // Reset window state
        window.resetSelection()
        window.selectionDelegate = self

        // Show window instantly
        window.orderFrontRegardless()
        window.makeKey()
    }
}
```

### Step 4: Update closeAllWindows()

Hide instead of close:

```swift
private func closeAllWindows() {
    // Remove escape key monitors...

    for (_, window) in windowPool {
        window.orderOut(nil)  // Hide, don't close
        window.resetSelection()
    }

    activeWindow = nil
}
```

### Step 5: Add Screen Change Observer

```swift
private func setupScreenChangeObserver() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(screenConfigurationDidChange),
        name: NSApplication.didChangeScreenParametersNotification,
        object: nil
    )
}

@objc private func screenConfigurationDidChange() {
    refreshWindowPool()
}

private func refreshWindowPool() {
    let currentDisplayIDs = Set(NSScreen.screens.compactMap { $0.displayID })
    let pooledDisplayIDs = Set(windowPool.keys)

    // Remove windows for disconnected displays
    for displayID in pooledDisplayIDs.subtracting(currentDisplayIDs) {
        windowPool[displayID]?.close()
        windowPool.removeValue(forKey: displayID)
    }

    // Add windows for new displays
    for screen in NSScreen.screens {
        guard let displayID = screen.displayID,
              windowPool[displayID] == nil else { continue }
        let window = createPooledWindow(for: screen)
        windowPool[displayID] = window
    }

    // Update frames for existing windows (screen may have moved)
    for screen in NSScreen.screens {
        guard let displayID = screen.displayID,
              let window = windowPool[displayID] else { continue }
        window.setFrame(screen.frame, display: false)
    }
}
```

### Step 6: Add resetSelection() to AreaSelectionOverlayView

```swift
func resetSelection() {
    isSelecting = false
    selectionStartPoint = nil
    selectionEndPoint = nil
    currentMousePosition = .zero
    needsDisplay = true
}
```

### Step 7: Hook into App Launch

In `StatusBarController` or app delegate:

```swift
// During app initialization
AreaSelectionController.shared.prepareWindowPool()
```

## Todo List

- [ ] Add `windowPool` property to AreaSelectionController
- [ ] Add `prepareWindowPool()` method
- [ ] Modify AreaSelectionWindow init for pooled mode
- [ ] Update `startSelection()` to use pooled windows
- [ ] Change `closeAllWindows()` to hide instead of close
- [ ] Add screen change notification observer
- [ ] Add `refreshWindowPool()` for dynamic screens
- [ ] Add `resetSelection()` to AreaSelectionOverlayView
- [ ] Hook `prepareWindowPool()` to app launch
- [ ] Add NSScreen.displayID extension helper
- [ ] Test multi-monitor scenarios
- [ ] Measure performance improvement

## Success Criteria

- [ ] Overlay appears in <100ms after pooling (vs 300-600ms before)
- [ ] No visible flash or artifacts
- [ ] Works with display connect/disconnect
- [ ] Memory usage stable (no leaks from pooling)
- [ ] All existing functionality preserved

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Stale window state | Medium | High | Always call resetSelection() before activation |
| Memory leak | Low | Medium | Proper cleanup in refreshWindowPool() |
| Screen mismatch | Low | High | Refresh pool on screen change notification |

## Security Considerations

- No sensitive data persisted in pooled windows
- Window state fully reset between uses
- No cross-session data leakage

## Next Steps

After completing Phase 1:
1. Measure actual performance improvement
2. If <150ms achieved, Phase 3+4 optional
3. If >150ms, proceed to Phase 2 (CALayer crosshair)
