# Blur Enhancement Implementation Plan

**Date**: 2026-01-27
**Priority**: High
**Status**: Completed

## Overview

Enhance blur annotation tool with Gaussian blur option and GPU acceleration. Current implementation uses CPU-based pixelated blur (~22 FPS). Target: 60+ FPS with CIFilter/Metal.

## Current State

- **Algorithm**: Pixelated mosaic, 12pt hardcoded blocks
- **Performance**: CPU-based O(cols x rows), ~22 FPS estimated
- **Files**: `BlurEffectRenderer.swift`, `BlurCacheManager.swift`
- **Issues**: Code duplication, synchronous main-thread, no GPU

## Target State

- Blur type picker: Pixelated vs Gaussian
- GPU-accelerated rendering (CIFilter + Metal context)
- 60+ FPS during blur operations
- Smart caching with lazy invalidation

## Phases

| Phase | Description | Status | File |
|-------|-------------|--------|------|
| 1 | Blur Type Model | Completed | [phase-01-blur-type-model.md](./phase-01-blur-type-model.md) |
| 2 | Gaussian Blur Renderer | Completed | [phase-02-gaussian-blur-renderer.md](./phase-02-gaussian-blur-renderer.md) |
| 3 | Performance Optimization | Completed | [phase-03-performance-optimization.md](./phase-03-performance-optimization.md) |
| 4 | UI Integration | Completed | [phase-04-ui-integration.md](./phase-04-ui-integration.md) |
| 5 | Export Integration | Completed | [phase-05-export-integration.md](./phase-05-export-integration.md) |

## Key Files

```
ClaudeShot/Features/Annotate/
├── State/
│   ├── AnnotateState.swift          # Add blurType property
│   ├── AnnotationToolType.swift     # Reference only
│   └── AnnotationItem.swift         # Update AnnotationType.blur
├── Canvas/
│   ├── BlurEffectRenderer.swift     # Add Gaussian option
│   ├── BlurCacheManager.swift       # GPU texture cache
│   └── AnnotationRenderer.swift     # Pass blurType
├── Views/
│   └── AnnotateSidebarSections.swift # Add blur picker
└── Export/
    └── AnnotateExporter.swift        # Fix line 353
```

## Success Criteria

- [ ] Blur type picker visible when blur tool active
- [ ] Gaussian blur renders smoothly in canvas
- [ ] Both blur types work in export
- [ ] 60+ FPS during blur drag operations
- [ ] No visual regression in pixelated blur

## Estimated Effort

- Phase 1: 1 hour (model changes)
- Phase 2: 2 hours (GPU renderer)
- Phase 3: 2 hours (optimization)
- Phase 4: 1 hour (UI)
- Phase 5: 1 hour (export)
- **Total**: ~7 hours
