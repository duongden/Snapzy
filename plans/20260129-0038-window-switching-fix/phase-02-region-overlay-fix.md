# Phase 02: RecordingRegionOverlayWindow Fix

## Context

- **Parent Plan:** [plan.md](plan.md)
- **Dependencies:** Phase 01 (optional, can be done in parallel)
- **Related Docs:** [researcher-02-swiftui-window-management.md](research/researcher-02-swiftui-window-management.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Description | Fix RecordingRegionOverlayWindow to prevent focus stealing |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

## Key Insights

1. `RecordingRegionOverlayWindow` has `canBecomeKey = true` which allows focus stealing
2. Window is shown with `orderFrontRegardless()` which is correct
3. But `ignoresMouseEvents` toggles between `true/false` for interaction - when `false`, the window can steal focus

## Requirements

- [ ] Region overlay must NOT steal focus when interaction is enabled
- [ ] Dragging/resizing region must still work
- [ ] Recording flow must not be affected

## Architecture

**Current Flow:**
```
setInteractionEnabled(true) → ignoresMouseEvents = false → canBecomeKey = true → FOCUS CAN BE STOLEN
```

**Fixed Flow:**
```
setInteractionEnabled(true) → ignoresMouseEvents = false → canBecomeKey = false → FOCUS PRESERVED
```

## Related Code Files

| File | Purpose |
|------|---------|
| [RecordingRegionOverlayWindow.swift](../../ClaudeShot/Features/Recording/RecordingRegionOverlayWindow.swift) | Main file to modify |
| [RecordingCoordinator.swift](../../ClaudeShot/Features/Recording/RecordingCoordinator.swift) | Uses the overlay window |

## Implementation Steps

### Step 1: Modify canBecomeKey (line 95)

Change from:
```swift
override var canBecomeKey: Bool { true }
```

To:
```swift
override var canBecomeKey: Bool { false }
```

### Step 2: Add canBecomeMain override

Add after line 95:
```swift
override var canBecomeMain: Bool { false }
```

### Step 3: Verify RecordingRegionOverlayView mouse handling

The view already has proper mouse handling:
- `acceptsFirstMouse(for:)` returns `true` (line 160-162)
- Tracking area uses `.activeAlways` (line 144)

No changes needed.

### Step 4: Review RecordingCoordinator (optional improvement)

In `showRegionOverlay()` (lines 171-179), the current code is fine:
```swift
overlay.orderFrontRegardless()  // Correct - no activation
```

No changes needed.

## Todo List

- [ ] Change `canBecomeKey` to return `false`
- [ ] Add `canBecomeMain` returning `false`
- [ ] Test region dragging still works
- [ ] Test region resizing still works
- [ ] Test recording flow unaffected

## Success Criteria

1. Showing recording overlay does NOT change active window
2. Can drag region to reposition
3. Can resize region with handles
4. Recording starts/stops correctly

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Drag/resize breaks | Low | Medium | `acceptsFirstMouse` already configured |
| Cursor changes stop | Very Low | Low | Cursor is set programmatically |

## Security Considerations

None - window configuration changes only.

## Next Steps

After completion, proceed to [phase-03-testing.md](phase-03-testing.md)
