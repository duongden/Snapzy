# Real Microphone Audio Capture & Volume Control

**Created:** 2025-01-24
**Status:** 🔄 In Progress
**Priority:** High
**Complexity:** Medium-High

## Problem Statement

Current recording ignores microphone input - `SCStreamOutputType.microphone` case has `break` statement. No volume control exists for mic or system audio.

## Root Causes

1. `.microphone` case ignored in SCStreamOutput delegate
2. No `.microphone` stream output added to SCStream
3. Missing `config.capturesMicrophone = true`
4. No microphone permission in Info.plist
5. Single audioInput cannot mix mic + system audio

## Solution Strategy

**Approach:** Two separate audio tracks (mic + system) for MVP
- Simpler implementation, reliable
- Volume control via sample scaling before write
- Can enhance to mixed single track later

## Implementation Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Add microphone permission to Info.plist | ⬜ Pending |
| 02 | Update ScreenRecordingManager for mic capture | ⬜ Pending |
| 03 | Update RecordingSession for mic audio track | ⬜ Pending |
| 04 | Update UI bindings and toolbar | ⬜ Pending |
| 05 | Build verification | ⬜ Pending |

## Files to Modify

| File | Action |
|------|--------|
| `ClaudeShot/Info.plist` | ADD mic permission |
| `ClaudeShot/Core/ScreenRecordingManager.swift` | EDIT - mic capture |
| `ClaudeShot/Core/RecordingSession.swift` | EDIT - mic audio input |
| `ClaudeShot/Features/Recording/RecordingToolbarView.swift` | EDIT - bindings |
| `ClaudeShot/Features/Recording/Components/ToolbarMicToggleButton.swift` | EDIT - rename binding |
| `ClaudeShot/Features/Recording/Components/ToolbarOptionsMenu.swift` | EDIT - separate toggles |
| `ClaudeShot/Features/Recording/RecordingCoordinator.swift` | EDIT - pass mic param |

## Success Criteria

- [ ] Microphone audio recorded in output video
- [ ] Mic toggle controls microphone capture (not system audio)
- [ ] System audio toggle separate from mic
- [ ] No build errors
- [ ] Permission prompt appears on first mic use
