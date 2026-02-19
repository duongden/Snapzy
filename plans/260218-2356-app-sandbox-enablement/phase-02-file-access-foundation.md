# Phase 02: Sandbox File Access Foundation

**Parent:** [plan.md](./plan.md)
**Date:** 2026-02-18
**Priority:** Critical
**Implementation Status:** COMPLETED
**Review Status:** IMPLEMENTED, BUILD-VERIFIED

## Goal

Replace path-based persistence with sandbox-safe bookmark/scoped access primitives.

## Current references

- `Snapzy/Features/Preferences/Components/PreferencesGeneralSettingsView.swift`
- `Snapzy/Features/Capture/CaptureViewModel.swift`
- `Snapzy/Features/Recording/RecordingCoordinator.swift`

## Problem

Current save location is persisted as plain path string (`exportLocation`). Sandbox needs user-granted URLs with security-scoped bookmark restore on relaunch.

## Requirements

1. Add bookmark-backed storage for export directory
2. Add helper to resolve bookmark + call `startAccessingSecurityScopedResource()`
3. Keep compatibility with existing `exportLocation` path key during migration
4. Fail closed with user prompt when access expired or invalid
5. Onboarding flow must request export directory access with Desktop/Snapzy default preselected

## Tasks

- [x] Create `SandboxFileAccessManager` service (bookmark save/load/resolve helpers)
- [x] Add new preference key for bookmark data (keep legacy path key temporarily)
- [x] Update folder picker flow to store bookmark, not only path
- [x] Add migration logic: if legacy path exists and bookmark missing, request re-pick once
- [x] Add safe wrapper utility for scoped export-directory access
- [x] Integrate onboarding step to request folder access upfront (default Desktop/Snapzy)

## Success criteria

1. App restart preserves writable export directory in sandbox
2. Saving capture/recording works without repeated picker prompts
3. Legacy users are migrated with minimal friction

## Risk

- Bookmark staleness and bad migration can break all file writes

## Notes

1. Migration path is compatibility-first: legacy path is still read, but bookmark-backed access is required for durable writes.
