# OS Wallpaper Loader Implementation Plan

## Overview

**Date**: 2026-01-27
**Priority**: Medium
**Complexity**: Moderate
**Status**: Planning

Load and display macOS system wallpapers from OS directories in the annotation sidebar.

## Problem Statement

Current wallpaper section only shows 3 gradient presets and requires manual file selection. Users want quick access to their OS-installed wallpapers.

## Solution

Create `SystemWallpaperManager` service to enumerate system wallpaper directories and display them in a new sidebar section with async thumbnail loading.

## Implementation Phases

| Phase | Description | Status | File |
|-------|-------------|--------|------|
| 01 | SystemWallpaperManager Service | In Progress | [phase-01](phase-01-wallpaper-manager.md) |
| 02 | UI Integration & Components | Pending | [phase-02-ui-integration.md](phase-02-ui-integration.md) |
| 03 | Sandbox Compatibility | Pending | [phase-03-sandbox-compatibility.md](phase-03-sandbox-compatibility.md) |

## Key Decisions

1. **Thumbnail Strategy**: Use `/System/Library/Desktop Pictures/.thumbnails/` for grid display
2. **Section Placement**: New "System Wallpapers" section below existing wallpapers
3. **Loading Strategy**: Async enumeration + lazy image loading
4. **File Types**: `.heic`, `.jpg`, `.png` (exclude `.madesktop`)

## Target Files

| File | Action |
|------|--------|
| `ClaudeShot/Core/Services/SystemWallpaperManager.swift` | Create |
| `ClaudeShot/Features/Annotate/Views/AnnotateSidebarSections.swift` | Modify |
| `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift` | Modify |

## Reports

- [01-codebase-analysis.md](reports/01-codebase-analysis.md)

## Success Criteria

- [ ] System wallpapers load from `/System/Library/Desktop Pictures/`
- [ ] Thumbnails display in grid without UI blocking
- [ ] Selection applies wallpaper to canvas background
- [ ] Graceful handling when directories don't exist
