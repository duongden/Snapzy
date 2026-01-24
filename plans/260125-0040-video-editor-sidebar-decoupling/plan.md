# Video Editor Sidebar Decoupling

## Overview
- **Date**: 2026-01-25
- **Priority**: Medium
- **Status**: Planning
- **Scope**: Create dedicated sidebar components for VideoEditor, decoupled from Annotate

## Problem Statement
VideoBackgroundSidebarView currently imports shared components from AnnotateSidebarComponents.swift and AnnotateSidebarView.swift. This creates coupling that prevents independent evolution of both features.

## Current Shared Components

| Component | Source File | Used In VideoEditor |
|-----------|-------------|---------------------|
| SidebarSectionHeader | AnnotateSidebarComponents.swift:12-21 | Yes |
| GradientPresetButton | AnnotateSidebarComponents.swift:25-42 | Yes |
| CompactColorSwatchGrid | AnnotateSidebarView.swift:168-193 | Yes |
| CompactSliderRow | AnnotateSidebarView.swift:195-215 | Yes |

## Solution
Create new file `VideoEditorSidebarComponents.swift` containing VideoEditor-specific copies of these components with "Video" prefix. Additionally, standardize spacing to be consistent (4px for both horizontal and vertical).

## Implementation Phases

| Phase | Description | Status | File |
|-------|-------------|--------|------|
| 01 | Create VideoEditor sidebar components | Pending | [phase-01-create-components.md](./phase-01-create-components.md) |

## Files to Create
1. `ClaudeShot/Features/VideoEditor/Views/VideoEditorSidebarComponents.swift`

## Files to Modify
1. `ClaudeShot/Features/VideoEditor/Views/VideoBackgroundSidebarView.swift`

## Success Criteria
- [ ] New VideoEditorSidebarComponents.swift created
- [ ] VideoBackgroundSidebarView uses local components
- [ ] Consistent spacing (4px h/v) across all grids
- [ ] Build succeeds with no errors
- [ ] Annotate sidebar unaffected

## Risk Assessment
- **Low**: Simple copy/rename, no logic changes
- **Testing**: Visual verification only
