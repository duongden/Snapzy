# Blur Implementation Research - ClaudeShot

## Overview
ClaudeShot implements **pixelated blur** (mosaic effect) for sensitive content redaction in annotation tools.

## Core Components

### 1. BlurEffectRenderer.swift
**Location**: `/ClaudeShot/Features/Annotate/Canvas/BlurEffectRenderer.swift`

**Algorithm**: Pixelated/Mosaic Blur
- Default pixel block size: 12pt (`defaultPixelSize`)
- Samples colors from source image at grid positions
- Fills rectangular blocks with sampled average colors
- NOT Gaussian blur - uses discrete pixel blocks

**Key Methods**:
- `drawPixelatedRegion()` - Main render path for blur annotations
- `drawPixelated()` - Grid-based pixel block drawing
- `drawBlurPreview()` - Fast preview during drag (semi-transparent overlay + dashed border)
- `drawFallbackBlur()` - Gray overlay when image sampling fails

**Performance Path**:
1. Convert region to pixel coordinates with scale calculation
2. Crop source CGImage to blur region
3. Access raw pixel data via `CFDataGetBytePtr()`
4. Sample center of each grid cell (col+0.5, row+0.5)
5. Fill block rects with sampled RGBA values

**Critical Sections**:
- Lines 82-132: Nested loops iterate cols×rows grid
- Lines 92-97: Raw pixel data access (potential bottleneck)
- Lines 103-132: Per-block sampling and filling (O(cols×rows))

### 2. BlurCacheManager.swift
**Location**: `/ClaudeShot/Features/Annotate/Canvas/BlurCacheManager.swift`

**Purpose**: Performance optimization via CGImage caching

**Caching Strategy**:
- Cache key: annotation UUID
- Cache value: `CacheEntry(image: CGImage, bounds: CGRect)`
- Validates bounds match before returning cached image
- Renders to offscreen bitmap context once, reuses CGImage

**Cache Lifecycle**:
- `getCachedBlur()` - Get or create cached blur image
- `invalidate(id:)` - Clear cache on bounds change (resize)
- `clearAll()` - Purge all on source image change
- Cache invalidation on resize: `CanvasDrawingView.swift:415`

**Optimization Impact**:
- Avoids per-frame recomputation during canvas redraws
- Duplicates pixelation logic from BlurEffectRenderer (lines 102-211)
- Offscreen rendering: 8-bit RGBA premultiplied bitmap context

### 3. AnnotationRenderer.swift
**Location**: `/ClaudeShot/Features/Annotate/Canvas/AnnotationRenderer.swift`

**Blur Render Path** (lines 221-249):
1. Check for source image availability
2. Try cache manager first (`getCachedBlur()`)
3. Fallback to direct `BlurEffectRenderer.drawPixelatedRegion()`
4. Preview mode uses semi-transparent overlay + border

**Integration**:
- Receives `BlurCacheManager` instance from `CanvasDrawingView`
- Handles both finalized blur and live preview rendering
- Preview during drag: `drawBlurPreview()` (lines 252-272)

### 4. State Management

**AnnotationToolType.swift**:
- Blur tool enum case: `.blur`
- Keyboard shortcut: `b`
- Icon: `aqi.medium`

**AnnotationItem.swift**:
- Blur annotation type: `.blur` (enum case, no associated values)
- Hit testing: Simple `bounds.contains(point)` (line 75-76)
- No blur-specific properties (uses default AnnotationProperties)

**AnnotateState.swift**:
- No blur-specific state variables
- Standard annotation lifecycle (add, select, delete, undo/redo)
- Cache cleared on image load/change (implicit via new CanvasDrawingView instance)

**CanvasDrawingView.swift**:
- Blur cache manager initialized: line 59
- Cache invalidation on resize: lines 411-416
- Blur preview during drag: lines 554-559

## Performance Characteristics

**Bottlenecks**:
1. **Grid iteration**: O(cols × rows) where cols/rows ≈ bounds/pixelSize
   - 200×200px region @ 12px blocks = 17×17 = 289 iterations
   - 1000×1000px region @ 12px blocks = 84×84 = 7,056 iterations

2. **Raw pixel access**: `CFDataGetBytePtr()` per annotation render
   - Requires cropping CGImage for each blur region
   - Reads bytesPerRow × height memory range

3. **Code duplication**: BlurCacheManager duplicates pixelation logic
   - Lines 102-211 mirror BlurEffectRenderer.swift:75-133

**Optimizations in Place**:
- CGImage caching eliminates recomputation on redraws
- Cache invalidation only on bounds change (smart invalidation)
- Single pixel sample per block (center point, not average)
- Direct pixel buffer access (no high-level API overhead)

**Missing Optimizations**:
- No configurable pixelSize (hardcoded 12pt default)
- No blur intensity/strength parameter
- No alternative blur algorithms (Gaussian, box blur)
- No Metal/GPU acceleration
- Synchronous rendering (blocks main thread)

## Code Paths

**Creation Flow**:
1. User selects blur tool (`AnnotationToolType.blur`)
2. Mouse drag creates preview (`AnnotationRenderer.drawBlurPreview()`)
3. Mouse up creates annotation (`AnnotationFactory.createAnnotation()`)
4. Annotation added to state, cache empty

**Render Flow**:
1. Canvas redraw triggered (`CanvasDrawingView.draw()`)
2. Renderer iterates annotations
3. Blur case: Check cache → render if miss → draw cached CGImage
4. Cache hit: `context.draw(cachedImage, in: bounds)`

**Resize Flow**:
1. User drags resize handle
2. Bounds updated via `updateAnnotationBounds()`
3. Cache invalidated (`blurCacheManager.invalidate(id:)`)
4. Next redraw regenerates cached blur with new bounds

## Unresolved Questions
- Why duplicate pixelation logic instead of shared implementation?
- Should pixelSize be user-configurable or annotation-specific property?
- Would Metal/Core Image filters provide better performance?
- Is synchronous rendering acceptable for large blur regions?

**File Path**: `/Users/duongductrong/Developer/ZapShot/plans/20260127-0022-blur-enhancement/research/researcher-01-blur-implementation.md`
