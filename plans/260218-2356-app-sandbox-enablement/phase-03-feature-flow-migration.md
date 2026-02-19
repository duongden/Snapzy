# Phase 03: Feature Flow Migration

**Parent:** [plan.md](./plan.md)
**Date:** 2026-02-18
**Priority:** High
**Implementation Status:** COMPLETED
**Review Status:** IMPLEMENTED, BUILD-VERIFIED

## Goal

Move concrete features to the new sandbox file-access primitives.

## Scope

- Screenshot save/export
- Recording output save
- Annotate save/replace-original
- Video editor save copy/replace-original
- Wallpaper fallback directory access persistence

## Current references

- `Snapzy/Services/Capture/ScreenCaptureManager.swift`
- `Snapzy/Services/Capture/ScreenRecordingManager.swift`
- `Snapzy/Features/Annotate/Services/AnnotateExporter.swift`
- `Snapzy/Features/VideoEditor/Services/VideoEditorExporter.swift`
- `Snapzy/Services/Wallpaper/SystemWallpaperManager.swift`

## Requirements

1. All write operations use scoped URL wrappers
2. Replace-original flow gracefully handles denied writes
3. Drag/drop-originated files support replace only when scope is valid
4. Wallpaper manual grant can be restored across launches (bookmark)
5. Permission requests are surfaced in onboarding first (including any newly introduced permissions), with runtime fallback only when needed

## Tasks

- [x] Update capture + recording save path resolution to scoped access manager
- [x] Wrap annotate/video replace-original writes in scoped access blocks
- [x] Add fallback path: if replace-original denied, show "Save as Copy" prompt
- [x] Persist wallpaper directory grant as bookmark after panel selection
- [x] Ensure temporary working-copy behavior still works in video editor
- [x] Audit runtime permission prompts and move first-time ask into onboarding where feasible

## Success criteria

1. No sandbox write-denied errors in normal save flows
2. Replace-original works for user-granted files
3. Fallback UX works when write access is unavailable

## Risk

- Replace-original is highest risk regression point due to external file locations

## Notes

1. Replace-original stays available, with graceful fallback to "Save as Copy" on permission-denied writes.
