# Scout Report: Annotate Feature Structure

## Blur-Related Files

### Canvas Directory
- `BlurEffectRenderer.swift` - Core pixelation algorithm (12pt blocks, CPU-based)
- `BlurCacheManager.swift` - CGImage caching (duplicates rendering logic)
- `AnnotationRenderer.swift` - Render orchestration
- `CanvasDrawingView.swift` - Canvas integration, cache lifecycle
- `AnnotationFactory.swift` - Annotation creation

### State Directory
- `AnnotateState.swift` - Main state container
- `AnnotationToolType.swift` - Tool type enum (includes `.blur`)
- `AnnotationItem.swift` - Annotation data model

### Views Directory
- `AnnotateToolbarView.swift` - Main toolbar (blur tool at line 92)
- `AnnotateSidebarView.swift` - Sidebar for tool options
- `AnnotateSidebarSections.swift` - Sidebar sections
- `AnnotateSidebarComponents.swift` - Reusable UI components
- `AnnotationPropertiesSection.swift` - Tool property controls

### Export Directory
- `AnnotateExporter.swift` - Export with blur placeholder at line 353

## Key Patterns

### Tool Options UI
- Sidebar sections handle tool-specific options
- `AnnotationPropertiesSection.swift` for property controls
- `TextStylingSection.swift` as example of tool-specific section

### Caching
- `BlurCacheManager.swift` - CGImage cache for blur regions
- Cache invalidation on resize/bounds change
- No GPU texture caching currently

## Critical Findings

1. **Tools/ directory is empty** - Tool logic embedded in Canvas/State
2. **Blur export incomplete** - Line 353 has placeholder comment for CIFilter
3. **No blur type option** - Single pixelate implementation only
4. **CPU-bound rendering** - No GPU acceleration

## Files to Modify

1. `AnnotationToolType.swift` - Add blur type enum
2. `AnnotateState.swift` - Add blurType property
3. `BlurEffectRenderer.swift` - Add Gaussian blur option
4. `AnnotateSidebarSections.swift` - Add blur type picker UI
5. `BlurCacheManager.swift` - Optimize caching strategy
6. `AnnotateExporter.swift` - Implement blur in export
