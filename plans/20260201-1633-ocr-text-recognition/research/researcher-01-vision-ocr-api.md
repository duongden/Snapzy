# Vision Framework OCR Research - VNRecognizeTextRequest

## 1. VNRecognizeTextRequest API Overview

### Initialization & Configuration

```swift
import Vision

// Basic initialization with completion handler
let textRequest = VNRecognizeTextRequest { (request, error) in
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
        return
    }

    for observation in observations {
        guard let topCandidate = observation.topCandidates(1).first else { continue }
        print("Text: \(topCandidate.string)")
    }
}
```

### Recognition Levels

```swift
// Configure recognition level
textRequest.recognitionLevel = .accurate  // Slower, higher accuracy (neural network)
// OR
textRequest.recognitionLevel = .fast      // Faster, lower accuracy (traditional OCR)
```

**Differences:**
- `.accurate` - Uses neural network for comprehensive text analysis (human-like reading)
- `.fast` - Uses character detection + small ML model (traditional OCR approach)

### Key Configuration Options

```swift
textRequest.usesLanguageCorrection = true  // Enable NLP language correction
textRequest.recognitionLanguages = ["en-US", "zh-Hans"]  // Specify languages
textRequest.automaticallyDetectsLanguage = true  // Auto-detect language
```

## 2. Language Support (macOS 13+)

### Supported Languages (Accurate Mode)

As of macOS 13 (Ventura) with Xcode 14, supported languages expanded to:

- English (en-US)
- French (fr-FR)
- Italian (it-IT)
- German (de-DE)
- Spanish (es-ES)
- Portuguese (pt-BR)
- Simplified Chinese (zh-Hans)
- Traditional Chinese (zh-Hant)
- Cantonese Simplified (yue-Hans)
- Cantonese Traditional (yue-Hant)
- Korean (ko-KR)
- Japanese (ja-JP)
- Russian (ru-RU)
- Ukrainian (uk-UA)

### Query Supported Languages

```swift
// Check supported languages for current revision
let supportedLanguages = try? VNRecognizeTextRequest.supportedRecognitionLanguages()
```

**Note:** Fast mode may support fewer languages than accurate mode.

## 3. Processing Images with VNImageRequestHandler

### Handler Initialization Options

```swift
// With CGImage
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

// With NSImage (macOS)
let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

// With CIImage
let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

// With Data
let handler = VNImageRequestHandler(data: imageData, options: [:])

// With URL
let handler = VNImageRequestHandler(url: imageURL, options: [:])
```

### Complete Usage Pattern

```swift
func recognizeText(in image: CGImage) {
    let request = VNRecognizeTextRequest { request, error in
        if let error = error {
            print("Request error: \(error.localizedDescription)")
            return
        }

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }

        let recognizedStrings = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        print("Recognized: \(recognizedStrings.joined(separator: "\n"))")
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: image, options: [:])

    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform: \(error.localizedDescription)")
    }
}
```

**Important:** Handler is single-use - create new handler for each image.

## 4. VNRecognizedTextObservation Results

### Extracting Text & Confidence

```swift
for observation in observations {
    // Get top N candidates
    let candidates = observation.topCandidates(3)

    for candidate in candidates {
        let text = candidate.string
        let confidence = candidate.confidence  // Float 0.0 to 1.0
        print("Text: \(text), Confidence: \(confidence)")
    }
}
```

### Bounding Boxes

```swift
for observation in observations {
    // Normalized coordinates (0.0 to 1.0)
    let boundingBox = observation.boundingBox

    // Convert to image coordinates
    let imageWidth = cgImage.width
    let imageHeight = cgImage.height

    let x = boundingBox.origin.x * CGFloat(imageWidth)
    let y = (1 - boundingBox.origin.y - boundingBox.height) * CGFloat(imageHeight)
    let width = boundingBox.width * CGFloat(imageWidth)
    let height = boundingBox.height * CGFloat(imageHeight)

    let imageRect = CGRect(x: x, y: y, width: width, height: height)
}
```

**Note:** Vision uses bottom-left origin, may need coordinate conversion for top-left systems.

## 5. macOS 13+ Specific Notes

### API Changes
- Deprecated: `supportedRecognitionLanguages(for:revision:)` (macOS 10.15-12.0)
- Use instead: `supportedRecognitionLanguages()`

### No Major Deprecations
No significant Vision OCR API deprecations identified for macOS 13-15 or 2026.

### Processing Characteristics
- **On-device processing** - All OCR runs locally (privacy + performance)
- **Asynchronous** - Request completion handlers run async
- **Two-stage pipeline** - Recognition + optional NLP language correction

## Unresolved Questions

1. Performance benchmarks - .accurate vs .fast mode on different hardware?
2. Maximum image size limitations for VNImageRequestHandler?
3. Batch processing optimization - can multiple requests share handler?
4. Memory usage patterns for large images or continuous OCR?

## Sources

- [Apple Vision Framework Documentation](https://developer.apple.com/documentation/vision)
- [VNRecognizeTextRequest Language Support](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Vision OCR Technical Details](https://developer.apple.com/documentation/vision)
