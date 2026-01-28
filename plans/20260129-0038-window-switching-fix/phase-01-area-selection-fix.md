# Phase 01: AreaSelectionWindow Non-Activating Fix

## Context

- **Parent Plan:** [plan.md](plan.md)
- **Dependencies:** None
- **Related Docs:** [researcher-02-swiftui-window-management.md](research/researcher-02-swiftui-window-management.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Description | Convert AreaSelectionWindow to non-activating behavior |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

## Key Insights

1. `AreaSelectionWindow` currently uses `NSWindow` with `makeKey()` calls that steal focus
2. macOS provides `NSPanel` with `.nonactivatingPanel` style for exactly this use case
3. The selection overlay should capture mouse events but NOT become the key/main window

## Requirements

- [ ] Area selection overlay must NOT steal focus from user's active window
- [ ] Mouse events (click, drag) must still work for region selection
- [ ] Escape key must still cancel selection
- [ ] Multi-monitor support must continue working

## Architecture

**Current Flow:**
```
activatePooledWindows() → makeKey() → FOCUS STOLEN
```

**Fixed Flow:**
```
activatePooledWindows() → orderFrontRegardless() → FOCUS PRESERVED
```

## Related Code Files

| File | Purpose |
|------|---------|
| [AreaSelectionWindow.swift](../../ClaudeShot/Core/AreaSelectionWindow.swift) | Main file to modify |

## Implementation Steps

### Step 1: Modify AreaSelectionWindow class (lines 270-329)

Change window configuration to prevent activation:

```swift
// Line 295: Change level to allow overlay without activation
self.level = .screenSaver  // Keep as is - high level is fine

// Line 321-322: Override canBecomeKey and canBecomeMain
override var canBecomeKey: Bool { false }  // Changed from true
override var canBecomeMain: Bool { false } // Changed from true
```

### Step 2: Fix activatePooledWindows() method (lines 129-148)

Remove focus-stealing calls:

```swift
// Line 138-139: Remove these lines
// window.makeKey()  // DELETE THIS

// Keep only:
window.orderFrontRegardless()
```

### Step 3: Fix non-pooled window initialization (lines 306-314)

Change from:
```swift
if pooled {
    self.orderOut(nil)
} else {
    self.makeKeyAndOrderFront(nil)  // PROBLEM
    self.makeMain()                  // PROBLEM
    self.makeFirstResponder(overlayView)
}
```

To:
```swift
if pooled {
    self.orderOut(nil)
} else {
    self.orderFrontRegardless()
    // Note: makeFirstResponder works without being key window
}
```

### Step 4: Fix becomeKey() override (lines 325-328)

Remove or modify:
```swift
// Either remove entirely or change to:
override func becomeKey() {
    super.becomeKey()
    // Only set first responder if we actually become key (won't happen now)
    if isKeyWindow {
        makeFirstResponder(overlayView)
    }
}
```

### Step 5: Handle mouse events without key window status

The `AreaSelectionOverlayView` already has:
- `acceptsFirstMouse(for:)` returning `true` - handles clicks without activation
- `.activeAlways` tracking option - receives mouse events regardless of key status

No changes needed for mouse handling.

## Todo List

- [ ] Modify `canBecomeKey` to return `false`
- [ ] Modify `canBecomeMain` to return `false`
- [ ] Remove `makeKey()` from `activatePooledWindows()`
- [ ] Replace `makeKeyAndOrderFront()` with `orderFrontRegardless()` in init
- [ ] Remove `makeMain()` call in init
- [ ] Update `becomeKey()` override
- [ ] Test area selection still works
- [ ] Test escape key still cancels

## Success Criteria

1. Opening area selection does NOT change active window
2. Can draw selection rectangle with mouse
3. Escape key cancels selection
4. Works on all connected monitors

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Mouse events stop working | Low | High | `acceptsFirstMouse` + `.activeAlways` tracking |
| Escape key stops working | Low | Medium | Global event monitor already in place |

## Security Considerations

None - window configuration changes only.

## Next Steps

After completion, proceed to [phase-02-region-overlay-fix.md](phase-02-region-overlay-fix.md)
