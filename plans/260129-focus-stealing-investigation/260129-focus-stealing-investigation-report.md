# Focus Stealing Investigation Report

**Date:** 2026-01-29
**Investigator:** Antigravity Agent
**Status:** ROOT CAUSE IDENTIFIED

## Executive Summary

**Issue:** After area selection completes, focus jumps from user's current window to app's main window (window 1).

**Root Cause:** `RecordingToolbarWindow` uses `orderFrontRegardless()` without focus prevention mechanisms, causing implicit app activation.

**Impact:** Disrupts user workflow by stealing focus from active application during recording preparation.

**Priority:** HIGH - Degrades user experience

---

## Technical Analysis

### Flow Timeline

```
1. User completes area selection
2. AreaSelectionController.completeSelection() [Line 215]
3. deactivatePooledWindows() hides overlays [Line 217]
4. RecordingCoordinator.showToolbar() creates RecordingToolbarWindow [Line 36]
5. RecordingToolbarWindow.init() → configureWindow() [Line 68-69]
6. showPreRecordToolbar() → positionBelowRect() [Line 82-112]
7. orderFrontRegardless() [Line 157]
8. ⚠️ FOCUS STOLEN HERE
```

### Root Cause Details

**File:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Recording/RecordingToolbarWindow.swift`

**Lines 157:**
```swift
setFrameOrigin(CGPoint(x: safeX, y: safeY))
orderFrontRegardless()  // ⚠️ PROBLEM: Activates app without prevention
```

**Lines 72-80 (Window Configuration):**
```swift
private func configureWindow() {
    isOpaque = false
    backgroundColor = .clear
    level = .popUpMenu  // ⚠️ High window level
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    hasShadow = false
    isReleasedWhenClosed = false
    // ❌ MISSING: canBecomeKey and canBecomeMain overrides
}
```

### Evidence from Codebase

**1. AreaSelectionWindow (CORRECTLY IMPLEMENTED):**
- Lines 320-321: Prevents focus stealing
```swift
override var canBecomeKey: Bool { false }
override var canBecomeMain: Bool { false }
```

**2. RecordingRegionOverlayWindow (CORRECTLY IMPLEMENTED):**
- Lines 95-97: Prevents focus stealing
```swift
override var canBecomeKey: Bool { false }
override var canBecomeMain: Bool { false }
```

**3. RecordingToolbarWindow (MISSING PREVENTION):**
- ❌ No `canBecomeKey` override
- ❌ No `canBecomeMain` override
- Uses `.popUpMenu` level which can trigger app activation
- Uses `orderFrontRegardless()` which shows window immediately

### Why Focus Is Stolen

1. **Window Level:** `.popUpMenu` is high-priority level (above `.floating`)
2. **No Prevention:** Missing `canBecomeKey`/`canBecomeMain` overrides
3. **Implicit Activation:** `orderFrontRegardless()` on high-level window can activate app
4. **Window Lifecycle:** New window creation may trigger `NSApp.activate()` internally

### Comparison with Working Code

**AreaSelectionWindow (Line 138-139):**
```swift
// Activate pooled windows (instant show)
window.orderFrontRegardless()
// Removed makeKey() - prevents focus stealing from user's active window
```

Comment explicitly references previous focus-stealing fix.

---

## Supporting Evidence

### Grep Results Summary

Found 51 instances of focus-related calls across codebase:

**Intentional Activation (User-Initiated):**
- `ClaudeShotApp.swift:83-86` - Opening main window
- `StatusBarController.swift:341` - Menu bar activation
- `VideoEditorWindowController.swift:108-109` - Editor window
- `AnnotateWindowController.swift:105-106` - Annotate window

**Unintentional Activation (Bug Fixed Previously):**
- `AreaSelectionWindow.swift:139` - Comment: "Removed makeKey() - prevents focus stealing"

**Current Bug:**
- `RecordingToolbarWindow.swift:157` - Missing prevention, uses `orderFrontRegardless()`

---

## Solution

Add focus prevention overrides to `RecordingToolbarWindow`:

```swift
// Add after line 80 in configureWindow() or as class-level overrides
override var canBecomeKey: Bool { false }
override var canBecomeMain: Bool { false }
```

**Location:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Recording/RecordingToolbarWindow.swift`

**Lines to modify:** After line 80 (in class definition) or in `configureWindow()`

---

## Verification Steps

1. Start screen recording flow
2. Complete area selection while another app is focused
3. Verify focus remains on other app (not stolen by ClaudeShot)
4. Verify toolbar still appears correctly
5. Verify toolbar interactions still work

---

## Related Files

| File | Role | Focus Prevention |
|------|------|-----------------|
| `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/AreaSelectionWindow.swift` | Area selection overlay | ✅ Lines 320-321 |
| `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Recording/RecordingRegionOverlayWindow.swift` | Recording region overlay | ✅ Lines 95-97 |
| `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Recording/RecordingToolbarWindow.swift` | Recording toolbar | ❌ MISSING |
| `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Recording/RecordingCoordinator.swift` | Flow coordinator | N/A |

---

## Additional Notes

- Previous fix applied to `AreaSelectionWindow` (line 139 comment)
- Pattern established: overlay windows should not become key/main
- `RecordingToolbarWindow` follows different pattern (uses NSPanel level)
- Solution aligns with existing codebase conventions

---

## Unresolved Questions

None. Root cause definitively identified with clear solution.
