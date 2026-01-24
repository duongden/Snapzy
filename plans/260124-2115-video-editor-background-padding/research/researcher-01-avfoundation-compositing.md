# AVFoundation Video Background/Padding Research

## Overview
Research on adding background/padding to video export in AVFoundation for macOS, covering three main approaches: AVVideoComposition custom compositing, CIFilter-based processing, and CALayer-based composition.

---

## 1. AVVideoComposition & Custom Compositing

### Core Concepts
- **AVVideoCompositing Protocol**: Enables custom video compositor with fine-grained control over frame rendering
- **Pixel Buffer Processing**: System provides pixel buffers for each source; compositor performs arbitrary graphical operations
- **Not Direct "Padding"**: Achieve effect by rendering source video within larger canvas with background

### Implementation Pattern
```swift
// Custom compositor conforming to AVVideoCompositing
class CustomVideoCompositor: NSObject, AVVideoCompositing {
    var sourcePixelBufferAttributes: [String : Any]? {
        return [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    }

    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
        return [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    }

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        // Get source pixel buffer
        guard let sourceBuffer = request.sourceFrame(byTrackID: trackID) else {
            request.finish(with: NSError(...))
            return
        }

        // Create output buffer with desired size (includes padding)
        let outputBuffer = request.renderContext.newPixelBuffer()

        // Render source into output with offset/scaling for padding
        // Use CIContext, Metal, or CoreGraphics for rendering

        request.finish(withComposedVideoFrame: outputBuffer)
    }
}
```

### Key Points
- Full control over pixel manipulation
- Can combine with additional tracks or layers
- Export via AVAssetExportSession with custom videoComposition
- Higher complexity but maximum flexibility

---

## 2. CIFilter-Based Approach

### Modern API (macOS 13.0+)
```swift
// Streamlined approach using AVAsset extension
asset.videoComposition(
    with: asset,
    applyingCIFiltersWithHandler: { request in
        let sourceImage = request.sourceImage

        // Create background with padding
        let outputSize = CGSize(width: 1920, height: 1080)
        let backgroundColor = CIColor(red: 0, green: 0, blue: 0)
        let background = CIImage(color: backgroundColor)
            .cropped(to: CGRect(origin: .zero, size: outputSize))

        // Scale and position source video
        let scale = min(
            outputSize.width / sourceImage.extent.width,
            outputSize.height / sourceImage.extent.height
        )
        let scaledImage = sourceImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Center in background
        let x = (outputSize.width - scaledImage.extent.width) / 2
        let y = (outputSize.height - scaledImage.extent.height) / 2
        let positioned = scaledImage.transformed(by: CGAffineTransform(translationX: x, y: y))

        // Composite
        let output = positioned.composited(over: background)

        request.finish(with: output, context: nil)
    },
    completionHandler: { composition, error in
        // Use composition for export
    }
)
```

### Legacy Approach
```swift
// Custom compositor with AVAsynchronousVideoCompositionRequest
class CIFilterCompositor: NSObject, AVVideoCompositing {
    let ciContext = CIContext(options: [.useSoftwareRenderer: false]) // GPU rendering

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        guard let sourceBuffer = request.sourceFrame(byTrackID: trackID),
              let outputBuffer = request.renderContext.newPixelBuffer() else {
            request.finish(with: NSError(...))
            return
        }

        let sourceImage = CIImage(cvPixelBuffer: sourceBuffer)
        // Apply filters, scaling, compositing...
        let filteredImage = // ... process sourceImage

        ciContext.render(filteredImage, to: outputBuffer)
        request.finish(withComposedVideoFrame: outputBuffer)
    }
}
```

### Key Points
- Flexible filter pipeline
- GPU-accelerated when configured properly (`useSoftwareRenderer: false`)
- Works well for borders via crop + background color
- Can handle aspect ratio transformations

---

## 3. CALayer-Based with AVVideoCompositionCoreAnimationTool

### Architecture
```swift
// Setup layer hierarchy
let parentLayer = CALayer()
parentLayer.frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
parentLayer.backgroundColor = NSColor.black.cgColor // Background padding color

let videoLayer = CALayer()
videoLayer.frame = CGRect(x: 100, y: 100, width: 1720, height: 880) // Inset for padding
parentLayer.addSublayer(videoLayer)

// Create animation tool
let animationTool = AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer,
    in: parentLayer
)

// Apply to composition
let videoComposition = AVMutableVideoComposition()
videoComposition.renderSize = CGSize(width: 1920, height: 1080)
videoComposition.animationTool = animationTool
```

### Transform-Based Scaling
```swift
// Calculate transforms for aspect-fit with padding
let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

let videoSize = videoTrack.naturalSize
let targetSize = CGSize(width: 1720, height: 880) // After padding

let scaleX = targetSize.width / videoSize.width
let scaleY = targetSize.height / videoSize.height
let scale = min(scaleX, scaleY) // Aspect fit

var transform = CGAffineTransform(scaleX: scale, y: scale)

// Center in target area
let scaledWidth = videoSize.width * scale
let scaledHeight = videoSize.height * scale
let tx = (1920 - scaledWidth) / 2
let ty = (1080 - scaledHeight) / 2
transform = transform.translatedBy(x: tx, y: ty)

instruction.setTransform(transform, at: .zero)
```

### Animation Considerations
```swift
// For animated layers
let animation = CABasicAnimation(keyPath: "opacity")
animation.beginTime = AVCoreAnimationBeginTimeAtZero // Critical for video timeline
animation.isRemovedOnCompletion = false
layer.add(animation, forKey: "opacity")
```

### Key Points
- Best for static backgrounds, overlays, watermarks
- Simple API for common use cases
- Transform calculations can be tricky (watch for "bugFixTransform" issues)
- Layer hierarchy: parentLayer contains videoLayer and other sublayers
- VideoLayer receives rendered video content; other layers create padding/background effect

---

## 4. Performance Considerations

### Real-Time Preview vs Export

**Real-Time Preview Challenges:**
- No direct AVMutableComposition real-time preview support
- Complex compositions require intelligent caching
- Professional apps (Final Cut Pro) use lower-level APIs, chunking, incremental rendering
- Consider AVPlayer with AVPlayerItem for basic preview; limited for complex compositions

**Export Performance:**
- AVAssetExportSession standard but can be slow with heavy compositions
- Custom rendering pipeline: AVAssetReader → process frames → AVAssetWriter
- GPU acceleration critical for performance

### Optimization Strategies

**1. GPU Acceleration**
```swift
// CIContext with GPU
let ciContext = CIContext(options: [
    .useSoftwareRenderer: false,
    .priorityRequestLow: false
])

// Or Metal-based rendering
let device = MTLCreateSystemDefaultDevice()
let ciContext = CIContext(mtlDevice: device)
```

**2. Manual Render Pipeline**
```swift
// For complex compositions
let reader = try AVAssetReader(asset: composition)
let writer = try AVAssetWriter(url: outputURL, fileType: .mp4)

// Configure reader output
let readerOutput = AVAssetReaderVideoCompositionOutput(
    videoTracks: videoTracks,
    videoSettings: nil
)
readerOutput.videoComposition = videoComposition
reader.add(readerOutput)

// Configure writer input
let writerInput = AVAssetWriterInput(
    mediaType: .video,
    outputSettings: compressionSettings
)
writer.add(writerInput)

// Process frames
reader.startReading()
writer.startWriting()

while reader.status == .reading {
    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
        // Process if needed
        writerInput.append(sampleBuffer)
    }
}
```

**3. Performance Tips**
- Avoid excessive layer count in CALayer approach
- Batch CIFilter operations when possible
- Use appropriate pixel format (kCVPixelFormatType_32BGRA common)
- Profile with Instruments to identify bottlenecks
- Consider lower resolution preview, full resolution export

### Approach Comparison

| Approach | Complexity | Flexibility | Performance | Best For |
|----------|-----------|-------------|-------------|----------|
| Custom AVVideoCompositing | High | Maximum | Good (with GPU) | Complex custom effects |
| CIFilter | Medium | High | Excellent (GPU) | Filters, transforms, padding |
| CALayer Tool | Low | Medium | Good | Static overlays, simple padding |

---

## Recommendations

**For Simple Padding/Background:**
Use CALayer approach with AVVideoCompositionCoreAnimationTool. Straightforward API, good performance for static backgrounds.

**For Dynamic Effects/Filters:**
Use CIFilter approach (modern API on macOS 13+). Best balance of power and simplicity with excellent GPU performance.

**For Maximum Control:**
Implement custom AVVideoCompositing. Required for pixel-level operations not achievable via CIFilter/CALayer.

**Performance Strategy:**
- Preview: Use AVPlayer with simplified composition or lower resolution
- Export: Full quality with GPU-accelerated rendering
- Profile early to identify bottlenecks before optimization

---

## Sources
- [Apple AVVideoCompositing Documentation](https://apple.com)
- [Apple AVVideoCompositionCoreAnimationTool](https://apple.com)
- [Stack Overflow: Custom Video Compositing](https://stackoverflow.com)
- [Kodeco: Video Composition Tutorial](https://kodeco.com)
- [Medium: AVFoundation Video Processing](https://medium.com)
- [Better Programming: CIFilter Video Effects](https://betterprogramming.pub)
