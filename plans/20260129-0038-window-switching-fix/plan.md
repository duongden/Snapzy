# Window Switching Fix Implementation Plan

**Date:** 2026-01-29
**Status:** Draft
**Priority:** High

## Problem Summary

When starting screen recording and selecting a region, the app unexpectedly switches focus to another window (e.g., from window 2 to window 1). This disrupts user workflow.

## Root Cause Analysis

After code analysis, identified 3 locations causing focus stealing:

| File | Line | Issue |
|------|------|-------|
| [AreaSelectionWindow.swift](../../ClaudeShot/Core/AreaSelectionWindow.swift#L138-L139) | 138-139 | `makeKey()` steals focus when activating pooled windows |
| [AreaSelectionWindow.swift](../../ClaudeShot/Core/AreaSelectionWindow.swift#L311-L313) | 311-313 | `makeKeyAndOrderFront()` + `makeMain()` steal focus |
| [RecordingRegionOverlayWindow.swift](../../ClaudeShot/Features/Recording/RecordingRegionOverlayWindow.swift#L95) | 95 | `canBecomeKey = true` allows focus stealing |

## Solution Overview

Convert overlay windows to non-activating behavior using macOS window management best practices:
1. Use `NSPanel` with `nonactivatingPanel` style instead of `NSWindow`
2. Remove all `makeKey()`, `makeMain()`, `makeKeyAndOrderFront()` calls from overlay windows
3. Configure `canBecomeKey = false` for passive overlays

## Implementation Phases

| Phase | Name | Status | Link |
|-------|------|--------|------|
| 01 | AreaSelectionWindow Non-Activating Fix | Pending | [phase-01-area-selection-fix.md](phase-01-area-selection-fix.md) |
| 02 | RecordingRegionOverlayWindow Fix | Pending | [phase-02-region-overlay-fix.md](phase-02-region-overlay-fix.md) |
| 03 | Testing & Validation | Pending | [phase-03-testing.md](phase-03-testing.md) |

## Research References

- [researcher-01-macos-window-focus.md](research/researcher-01-macos-window-focus.md)
- [researcher-02-swiftui-window-management.md](research/researcher-02-swiftui-window-management.md)
- [scout-01-recording-window-files.md](scout/scout-01-recording-window-files.md)

## Risk Assessment

- **Low Risk:** Changes are isolated to window configuration
- **Mitigation:** Focus testing on multi-monitor setups and various window arrangements

## Estimated Impact

- Zero focus stealing during area selection
- User's active window preserved throughout recording flow
