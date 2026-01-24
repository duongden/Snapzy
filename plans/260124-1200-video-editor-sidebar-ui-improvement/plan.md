# Video Editor Sidebar UI Improvement Plan

**Date:** 2026-01-24
**Status:** Draft
**Priority:** Medium

## Overview

Improve the video editor sidebar UI (zoom settings) and zoom block visuals to look more professional using macOS system colors. Replace hardcoded purple/opacity-based styling with native macOS semantic colors.

## Goals

- Use macOS system/asset colors consistently
- Solid colors only - no cheap gradients
- Match professional macOS apps (Final Cut Pro, Motion)
- Maintain all existing functionality

## Files to Modify

| File | Lines | Purpose |
|------|-------|---------|
| `ZoomSettingsPopover.swift` | 265 | Sidebar zoom settings panel |
| `ZoomBlockView.swift` | 289 | Timeline zoom block visuals |
| `ZoomCenterPicker.swift` | 131 | Center picker widget |

## Implementation Phases

| Phase | Description | Status |
|-------|-------------|--------|
| [Phase 01](./phase-01-zoom-colors-refactor.md) | Refactor ZoomColors enum to use system colors | ⬜ Pending |
| [Phase 02](./phase-02-zoom-settings-popover.md) | Redesign ZoomSettingsPopover sidebar | ⬜ Pending |
| [Phase 03](./phase-03-zoom-block-view.md) | Polish ZoomBlockView timeline blocks | ⬜ Pending |
| [Phase 04](./phase-04-zoom-center-picker.md) | Refine ZoomCenterPicker widget | ⬜ Pending |

## Design Principles

1. **System Colors**: `NSColor.controlAccentColor`, `NSColor.separatorColor`, `NSColor.tertiaryLabelColor`
2. **Consistency**: Match toolbar styling (`Color.white.opacity(0.1)` for backgrounds)
3. **Subtle Depth**: Use shadows sparingly, no gradients
4. **Native Feel**: Respect user's accent color preference

## Success Criteria

- [ ] All hardcoded purple replaced with system accent
- [ ] Consistent with VideoEditorToolbarView styling
- [ ] No visual regressions
- [ ] Builds without warnings

## References

- `VideoEditorToolbarView.swift` - Reference for consistent styling
- Apple HIG - macOS design guidelines
