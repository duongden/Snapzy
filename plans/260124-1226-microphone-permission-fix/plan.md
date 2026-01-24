# Microphone Permission Fix Plan

**Date:** 260124
**Priority:** High
**Status:** In Progress

## Overview

Fix TCC error when enabling microphone capture in screen recording. The app attempts to use ScreenCaptureKit's microphone API without requesting microphone permission first.

**Root Cause:** Missing `AVCaptureDevice.requestAccess(for: .audio)` call before configuring microphone capture.

## Phases

| Phase | Description | Status |
|-------|-------------|--------|
| [Phase 01](./phase-01-permission-request.md) | Add microphone permission request | Pending |
| [Phase 02](./phase-02-fallback-ui.md) | Add fallback UI when permission denied | Pending |
| [Phase 03](./phase-03-macos14-compat.md) | Handle macOS 14.x compatibility | Pending |

## Key Files

- `ClaudeShot/Core/ScreenRecordingManager.swift` - Add permission check
- `ClaudeShot/Features/Recording/Components/ToolbarMicToggleButton.swift` - Add permission request on toggle
- `ClaudeShot/Features/Recording/RecordingCoordinator.swift` - Handle permission denied error

## Success Criteria

1. Microphone permission dialog appears when user enables mic toggle
2. Clear error message shown when permission denied
3. Option to open System Settings provided
4. App works on macOS 14.6+ (mic feature disabled on < 15.0)
