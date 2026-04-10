# Capture Flow

Documentation of Snapzy's screenshot + screen-recording pipelines — from keyboard shortcut trigger to saved file and post-capture/editor actions.

## Architecture Overview

```mermaid
flowchart TD
    subgraph Trigger["Trigger (Global Shortcut)"]
        A1["Cmd+Shift+3 (Fullscreen)"]
        A2["Cmd+Shift+4 (Area Select)"]
    end

    subgraph VM["CaptureViewModel"]
        B1["captureFullscreen()"]
        B2["captureArea()"]
        B3["Resolve save directory"]
        B4["Prefetch SCShareableContent"]
    end

    subgraph Selection["Area Selection"]
        C1["AreaSelectionController.startSelection()"]
        C2["User drags rect (NSScreen coords)"]
        C3["Returns CGRect"]
    end

    subgraph Engine["ScreenCaptureManager"]
        D1["loadShareableContent()"]
        D2["Find target SCDisplay"]
        D3["buildFilter() (exclude icons/widgets/self)"]
        D4["Configure SCStreamConfiguration"]
        D5["captureImageCompat()"]
        D6["macOS 14+: SCScreenshotManager | macOS 13: SCStream"]
        D7["Returns CGImage"]
    end

    subgraph Save["Image Saving"]
        F1["saveImage()"]
        F2{"Format?"}
        F3["PNG/JPEG: CGImageDestination"]
        F4["WebP: WebPEncoderService"]
        F5["verifyFileWritten()"]
        F6["captureCompletedSubject"]
    end

    subgraph Post["PostCaptureActionHandler"]
        G1["Show QuickAccess Card"]
        G2["Copy to Clipboard"]
        G3["Open Annotate Editor"]
    end

    subgraph Annotate["Annotate Pipeline"]
        H1["loadImageWithCorrectScale()"]
        H2["AnnotateCanvasView (preview)"]
        H3["renderFinalImage() (export)"]
        H4["imageData() → save to disk"]
    end

    A1 --> B1
    A2 --> B2 --> C1 --> C2 --> C3

    B1 & B2 --> B3 & B4 --> D1
    C3 --> D1

    D1 --> D2 --> D3 --> D4 --> D5 --> D6 --> D7
    D7 --> F1 --> F2
    F2 -->|PNG/JPEG| F3
    F2 -->|WebP| F4
    F3 & F4 --> F5 --> F6

    F6 --> G1 & G2 & G3
    G3 --> H1 --> H2 -->|Save/Export| H3 --> H4
```

## Recording + Smart Camera (Follow Mouse)

```mermaid
flowchart TD
    subgraph Trigger["Trigger (Global Shortcut)"]
        A1["Start recording"]
    end

    subgraph VM["CaptureViewModel"]
        B1["Resolve save directory"]
        B2["ScreenRecordingManager.prepareRecording(rect, fps, format)"]
        B3["setupAssetWriter + setupStream"]
        B4["RecordingMouseTracker(recordingRect, fps) created"]
    end

    subgraph Stream["ScreenRecordingManager.startRecording()"]
        C1["AVAssetWriter.startWriting()"]
        C2["SCStream.startCapture()"]
        C3["RecordingSession waits first complete video frame"]
        C4["writer.startSession(atSourceTime:firstVideoTimestamp)"]
        C5["onFirstVideoFrame callback -> mouseTracker.start()"]
    end

    subgraph Track["Mouse Tracking"]
        D1["Global event monitor: moved/dragged"]
        D2["Timer fallback sampling"]
        D3["Sample point normalized to top-left space"]
        D4["Pause/Resume aware elapsed-time timeline"]
    end

    subgraph Stop["Stop Recording"]
        E1["mouseTracker.stop()"]
        E2["Build RecordingMetadata(version=2, coordinateSpace=topLeftNormalized)"]
        E3["RecordingMetadataStore.save()"]
        E4["VideoEditorState.loadRecordingMetadata()"]
        E5["VideoEditorAutoFocusEngine.buildPath() + evaluatePathQuality()"]
    end

    subgraph Store["App Support Storage"]
        F1["~/Library/Application Support/Snapzy/Captures/"]
        F2["RecordingMetadata/index.json"]
        F3["RecordingMetadata/Entries/<uuid>.json"]
    end

    A1 --> B1 --> B2 --> B3 --> B4
    B4 --> C1 --> C2 --> C3 --> C4 --> C5
    C5 --> D1
    C5 --> D2
    D1 --> D3 --> D4
    D2 --> D3
    D4 --> E1 --> E2 --> E3 --> F2
    E3 --> F3
    E3 --> E4 --> E5
    F1 --> F2
    F1 --> F3
```

## Scrolling Capture

```mermaid
flowchart TD
    subgraph Trigger["Trigger (Scrolling Capture)"]
        A1["CaptureViewModel.captureScrolling()"]
        A2["AreaSelectionController.startSelection(mode: .scrollingCapture)"]
        A3["User selects only the moving content"]
    end

    subgraph Session["ScrollingCaptureCoordinator"]
        B1["beginSession(rect, saveDirectory, format, prefetchedContentTask)"]
        B2["Prewarm prepared area capture context"]
        B3["Prepare AX auto-scroll engine if enabled"]
        B4["Show HUD + live preview"]
    end

    subgraph FirstFrame["Start Capture"]
        C1["startCapture()"]
        C2["Capture first visible frame"]
        C3["ScrollingCaptureStitcher initializes stitched canvas"]
        C4{"AX auto-scroll ready?"}
    end

    subgraph Auto["AX Auto-scroll Loop"]
        D1["Resolve best AX scroll target from selected rect"]
        D2["Post pixel wheel event to target pid"]
        D3["Wait short settle delay"]
        D4["Capture next frame"]
        D5["Vision + consensus alignment"]
        D6["Adapt next step size from accepted delta"]
        D7{"Boundary / no movement / misses?"}
    end

    subgraph Manual["Manual Scroll Loop"]
        E1["Global scroll monitor accumulates wheel deltas"]
        E2["Throttle refresh until gesture settles"]
        E3["Capture next frame"]
        E4["Guided + recovery alignment"]
        E5{"Append / ignore / pause"}
    end

    subgraph Finish["Finish"]
        F1["finish() flushes final frame if needed"]
        F2["saveProcessedImage(latestImage, directory, format)"]
        F3["PostCaptureActionHandler"]
    end

    A1 --> A2 --> A3 --> B1 --> B2 --> B3 --> B4
    B4 --> C1 --> C2 --> C3 --> C4
    C4 -->|Yes| D1 --> D2 --> D3 --> D4 --> D5 --> D6 --> D7
    C4 -->|No| E1 --> E2 --> E3 --> E4 --> E5
    D7 -->|Continue| D2
    D7 -->|Fallback to manual| E1
    D7 -->|Reached boundary| F1
    E5 -->|Continue| E1
    E5 -->|Done / limit| F1 --> F2 --> F3
```

## Key Files

| File | Responsibility |
|------|----------------|
| `Features/Capture/CaptureViewModel.swift` | Orchestrates capture from UI. Resolves save directory, prefetches content, calls ScreenCaptureManager. |
| `Services/Capture/ScreenCaptureManager.swift` | Core capture engine. Configures SCStreamConfiguration, builds content filters, captures via SCScreenshotManager (14+) or SCStream (13). |
| `Services/Capture/PostCaptureActionHandler.swift` | Executes post-capture actions: Quick Access card, clipboard copy, open Annotate. |
| `Features/Annotate/AnnotateState.swift` | Manages annotation state. `loadImageWithCorrectScale()` loads images at correct Retina scale. |
| `Features/Annotate/Components/AnnotateCanvasView.swift` | Displays image + annotations on canvas with scale-to-fit, zoom, pan. |
| `Features/Annotate/Services/AnnotateExporter.swift` | Exports annotated images. `renderFinalImage()` combines source image + annotations + background at pixel resolution. |
| `Services/Shortcuts/KeyboardShortcutManager.swift` | Global shortcut registration lifecycle, including app-wide enable state, per-shortcut enable state, and temporary suppression while recorder UI is listening. |
| `Services/Shortcuts/SystemScreenshotShortcutManager.swift` | Detects/manages conflicts with macOS built-in screenshot shortcuts. |
| `Services/Shortcuts/ShortcutValidationService.swift` | Centralized duplicate/conflict validation and warning decisions for editable shortcuts in Preferences. |
| `Services/Capture/ScreenRecordingManager.swift` | Recording pipeline, stream/asset-writer setup, geometry normalization, metadata persistence for Smart Camera. |
| `Services/Capture/RecordingMouseTracker.swift` | Captures dense cursor timeline during recording (global monitor + timer fallback), pause/resume aware timing. |
| `Services/Capture/RecordingMetadata.swift` | Metadata schema + storage in App Support (`Captures/RecordingMetadata`), legacy migration/backward compatibility. |
| `Features/Recording/RecordingSession.swift` | Thread-safe frame append and first-video-frame callback used to align cursor timeline with media timeline. |
| `Features/VideoEditor/Services/VideoEditorAutoFocusEngine.swift` | Rebuilds auto-follow path from metadata and computes quality metrics (lock accuracy/visibility/error). |
| `Services/Capture/ScrollingCapture/ScrollingCaptureCoordinator.swift` | Runs the scrolling-capture session, manages preview cadence, coordinates auto-scroll, and saves the stitched result. |
| `Services/Capture/ScrollingCapture/ScrollingCaptureAutoScrollEngine.swift` | Finds the best AX scroll target inside the selected rect and drives synthetic scroll-wheel events with fallback handling. |
| `Services/Capture/ScrollingCapture/ScrollingCaptureStitcher.swift` | Builds the long image with band trimming, Vision registration, consensus scoring, and guided/recovery alignment. |
| `Services/Capture/ScrollingCapture/ScrollingCaptureHUDView.swift` | Presents capture controls, auto-scroll state, and live guidance during the session. |

## Capture Modes

### Fullscreen (`captureFullscreen`)

1. Prefetch `SCShareableContent`
2. Find target `SCDisplay` by display ID
3. Build `SCContentFilter` (display-level, excludes icons/widgets/self as configured)
4. Configure `SCStreamConfiguration`:
   - `width/height` = display pixel dimensions × `backingScaleFactor`
   - `pixelFormat` = `kCVPixelFormatType_32BGRA`
   - `showsCursor` = user preference `screenshot.showCursor` (default: `false`)
   - `captureResolution = .best` (macOS 14.2+)
5. Capture via `SCScreenshotManager` (macOS 14+) or `SCStream` single-frame (macOS 13)
6. Save via `CGImageDestination` (PNG/JPEG) or `WebPEncoderService` (WebP)

### Area Select (`captureArea`)

1. `AreaSelectionController` shows overlay → user drags selection rect
2. Find matching `NSScreen` and `SCDisplay`
3. Capture **full display** at native pixel resolution
   - `showsCursor` follows user preference `screenshot.showCursor` (default: `false`)
4. **Post-capture crop** using `CGImage.cropping(to:)` with pixel-coordinate rect — avoids `sourceRect` interpolation blur
5. Save cropped image

### OCR Area (`captureAreaAsImage`)

Same as Area Select but returns `CGImage` directly for text recognition instead of saving to disk.

### Scrolling Capture (`captureScrolling`)

1. `CaptureViewModel` switches the area-selection overlay into `.scrollingCapture` mode.
2. `ScrollingCaptureCoordinator.beginSession()` keeps a persistent highlighted region overlay on screen, creates the HUD + preview windows, prewarms a prepared area-capture context, and probes AX auto-scroll when the preference is enabled.
3. `startCapture()` grabs the first visible frame and initializes `ScrollingCaptureStitcher`.
4. The session then follows one of two loops:
   - AX auto-scroll loop: `ScrollingCaptureAutoScrollEngine` resolves the best overlapping AX scroll container, posts pixel wheel events to the target app, falls back to direct AX scrollbar value nudges when wheel delivery stalls, waits a short settle delay, and asks the coordinator to capture the next frame.
   - Manual loop: the coordinator listens for global wheel events, blends raw wheel deltas with the last accepted stitched delta, waits for the gesture to settle, and captures the next frame.
5. `ScrollingCaptureStitcher` trims static top/bottom/side bands, estimates translation with Vision, scores multi-band agreement, and either appends, ignores, or pauses when confidence is unsafe.
6. `finish()` flushes any final visible frame, saves the stitched image, and hands the result to the normal post-capture action pipeline.

## Image Quality Pipeline

| Stage | Units | Key Detail |
|-------|-------|------------|
| SCStreamConfiguration `width/height` | Pixels | Set to `display.width × backingScaleFactor` |
| `captureResolution = .best` | — | Hints SCK to use optimal pixel density (macOS 14.2+) |
| `CGImage.cropping(to:)` | Pixels | Post-capture crop, no resampling |
| `CGImageDestination` save | Pixels | Direct pixel data write, no quality loss |
| `loadImageWithCorrectScale()` | Points | Sets `NSImage.size = pixelSize / scaleFactor` (preserves bitmap rep) |
| `AnnotateCanvasView` display | Points | Scale-to-fit within window using `.clipShape()` (no rasterization) |
| `renderFinalImage()` export | Pixels | Uses `NSBitmapImageRep` at `pointSize × sourceImageScale` for Retina output |

## Scrolling Capture Stability Notes

Scrolling capture is intentionally closed-loop rather than trusting raw wheel deltas.

1. Selection hygiene matters: best results come from selecting only the moving content, not sticky headers, sidebars, or oversized scrollbars.
2. AX auto-scroll is opportunistic: Snapzy first looks for a supported scrollable AX element that materially overlaps the selected rect. If that probe fails, the session stays in manual mode.
3. Stitch acceptance is image-driven: wheel deltas only guide the search window. Final acceptance depends on visual alignment, not on the gesture delta alone.
4. Recovery is multi-stage: the stitcher uses trimmed content regions, Vision-based translation estimates, and a wider recovery search before pausing.
5. Auto-scroll is multi-strategy: Snapzy tries wheel-event scrolling first and can fall back to direct AX scrollbar adjustments on native scroll surfaces before giving up.
6. Auto-scroll remains bounded: repeated no-movement or alignment failures fall back to manual mode instead of appending low-confidence frames.

## Post-Capture Actions

Configured in user preferences, handled by `PostCaptureActionHandler`:

- **Quick Access Card** — floating overlay showing thumbnail, drag-to-app, copy/open actions
- **Copy to Clipboard** — `NSPasteboard` with image data
- **Open Annotate** — loads image into annotation editor

## Shortcut Activation Rules

Global shortcut trigger requires all conditions below:

1. App-wide shortcut system is enabled.
2. The specific global shortcut row is enabled.
3. Recorder UI is not actively listening (temporary suppression is released).

Conflict warnings against macOS screenshot hotkeys are evaluated only for currently enabled Snapzy shortcut rows.

## Recording Metadata and Storage

Smart Camera (Auto/Follow Mouse) relies on recording metadata written at stop-recording time.

- Canonical storage root: `~/Library/Application Support/Snapzy/Captures/RecordingMetadata`
- Index file: `index.json` (maps recorded video URL bookmark/path to metadata entry id)
- Entry files: `Entries/<uuid>.json`
- Schema version: `2`
- Coordinate space: `topLeftNormalized` (legacy `bottomLeftNormalized` data is auto-canonicalized when read)
- Temp recording files still live in `~/Library/Application Support/Snapzy/Captures`; metadata is centralized under the same root for easier maintenance.

## Smart Camera Accuracy Notes

Current follow-mouse accuracy improvements are based on:

1. Denser capture cadence: effective tracker cadence increased (up to 120 SPS depending on FPS).
2. Better temporal alignment: tracker starts on first complete video frame callback.
3. Coordinate-space consistency: capture + editor use top-left normalized cursor points.
4. Path robustness: sample dedup, outlier speed clamp, interpolation/resampling, adaptive dead-zone + smoothing.

Editor diagnostics now log per auto segment:

- `lockAccuracy` (target lock ratio)
- `visibilityRate` (cursor inside crop visibility ratio)
- `meanError` (average cursor-to-center distance)
- `sampleCount`
