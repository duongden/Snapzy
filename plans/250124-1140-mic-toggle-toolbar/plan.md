# Mic Toggle Button for Recording Toolbar

**Created:** 2025-01-24
**Status:** 📋 Planning
**Priority:** Medium
**Complexity:** Low

## Overview

Add a microphone toggle button to the recording toolbar, positioned near the Record button. Users can quickly mute/unmute audio capture without opening the Options menu.

## Current State

- `RecordingToolbarView.swift` has `@Binding var captureAudio: Bool`
- `ToolbarIconButton.swift` provides reusable icon button pattern
- Current layout: `[Close] | [Options] | [Record]`

## Target State

- New layout: `[Close] | [Options] | [MicToggle] | [Record]`
- Visual toggle with `mic.fill` / `mic.slash.fill` icons
- Consistent styling with existing toolbar components

## Implementation Phases

| Phase | Description | Status | File |
|-------|-------------|--------|------|
| 01 | Create ToolbarMicToggleButton component | ⬜ Pending | [phase-01-mic-toggle-component.md](./phase-01-mic-toggle-component.md) |
| 02 | Integrate into RecordingToolbarView | ⬜ Pending | [phase-02-toolbar-integration.md](./phase-02-toolbar-integration.md) |

## Files to Modify

| File | Action |
|------|--------|
| `ClaudeShot/Features/Recording/Components/ToolbarMicToggleButton.swift` | CREATE |
| `ClaudeShot/Features/Recording/RecordingToolbarView.swift` | EDIT |

## Success Criteria

- [ ] Mic toggle button visible in toolbar
- [ ] Toggle correctly updates `captureAudio` state
- [ ] Visual feedback shows current state (icon changes)
- [ ] Hover state matches existing buttons
- [ ] Accessibility labels present
- [ ] Preview renders correctly

## Dependencies

- None (uses existing bindings and patterns)

## Risks

- None identified (simple UI addition)
