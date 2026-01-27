# Annotate Sidebar UX Improvement Plan

**Date:** 2026-01-27
**Version:** 1.0
**Status:** Draft

## Executive Summary

Comprehensive UX/UI overhaul of the Annotate sidebar to establish consistent design patterns, improve interaction states, and enhance accessibility. The plan follows an 8pt grid system and implements unified component styling.

## Current State

The sidebar currently has inconsistent spacing (6/8/10/12px gaps), varying item sizes (24/28/44px), missing hover states on most components, and no expandable section pattern.

## Target State

- Unified 8pt grid system
- Consistent 48px grid items, 32px color circles
- Hover/focus states on all interactive elements
- Collapsible sections with "Show more" pattern
- WCAG 2.1 AA accessibility compliance

## Phases Overview

| Phase | Focus | Effort | Files Modified |
|-------|-------|--------|----------------|
| 1 | Design System Foundation | 4h | New: Core/Theme/DesignTokens.swift |
| 2 | Grid and Spacing | 6h | 3 files |
| 3 | Interaction States | 4h | 3 files |
| 4 | Polish and Accessibility | 3h | 4 files |

**Total Estimated Effort:** 17 hours

## Success Metrics

1. Visual consistency score (manual audit): 100%
2. All interactive elements have hover states
3. Keyboard navigation works for all controls
4. VoiceOver announces all buttons correctly

## File Change Summary

### New Files
- `ClaudeShot/Core/Theme/DesignTokens.swift` (shared app-wide)

### Modified Files
- `AnnotateSidebarView.swift`
- `AnnotateSidebarComponents.swift`
- `AnnotateSidebarSections.swift`
- `AnnotationPropertiesSection.swift`

## Dependencies

- None (self-contained UI changes)

## Risks

| Risk | Mitigation |
|------|------------|
| Breaking existing layout | Incremental changes with preview testing |
| Color contrast issues | Test with System Preferences accessibility |

## Phase Documents

1. [Phase 1: Design System Foundation](./phase-01-design-system-foundation.md)
2. [Phase 2: Grid and Spacing](./phase-02-grid-and-spacing.md)
3. [Phase 3: Interaction States](./phase-03-interaction-states.md)
4. [Phase 4: Polish and Accessibility](./phase-04-polish-and-accessibility.md)

## Appendix

- [Codebase Analysis Report](./reports/01-codebase-analysis.md)
