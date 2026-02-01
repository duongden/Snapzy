# Phase 01: OCR Service Implementation

**Parent:** [plan.md](./plan.md)
**Dependencies:** None
**Date:** 2026-02-01
**Priority:** High
**Status:** Pending

## Overview

Create `OCRService` using Vision framework's `VNRecognizeTextRequest` to extract text from CGImage. Follows singleton pattern consistent with existing services.

## Key Insights

- Vision OCR runs on-device (privacy + no network required)
- `.accurate` mode uses neural network for best results
- `usesLanguageCorrection = true` improves recognition quality
- Handler is single-use; create new handler per image
- Supports 14+ languages including CJK

## Requirements

1. Accept CGImage input (from screen capture)
2. Return recognized text as String
3. Handle errors gracefully
4. Use async/await pattern
5. Configure for accurate recognition with language correction

## Architecture

```
OCRService (singleton)
├── recognizeText(from: CGImage) async throws -> String
├── recognizeText(from: NSImage) async throws -> String
└── Private: configureRequest() -> VNRecognizeTextRequest
```

## Related Files

- `/Snapzy/Core/Services/` - Service location
- `/Snapzy/Core/Services/PostCaptureActionHandler.swift` - Pattern reference

## Implementation Steps

### Step 1: Create OCRService.swift

**Location:** `/Snapzy/Core/Services/OCRService.swift`

```swift
//
//  OCRService.swift
//  Snapzy
//
//  Provides OCR text recognition using Vision framework
//

import AppKit
import Vision

/// Errors that can occur during OCR processing
enum OCRError: LocalizedError {
  case imageConversionFailed
  case noTextFound
  case recognitionFailed(Error)

  var errorDescription: String? {
    switch self {
    case .imageConversionFailed:
      return "Failed to convert image for OCR processing"
    case .noTextFound:
      return "No text found in the selected area"
    case .recognitionFailed(let error):
      return "OCR recognition failed: \(error.localizedDescription)"
    }
  }
}

/// Service for performing OCR text recognition on images
@MainActor
final class OCRService {

  static let shared = OCRService()

  private init() {}

  // MARK: - Public API

  /// Recognize text from a CGImage
  /// - Parameter image: The image to extract text from
  /// - Returns: Recognized text joined by newlines
  func recognizeText(from image: CGImage) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          continuation.resume(throwing: OCRError.recognitionFailed(error))
          return
        }

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
          continuation.resume(throwing: OCRError.noTextFound)
          return
        }

        let recognizedStrings = observations.compactMap { observation in
          observation.topCandidates(1).first?.string
        }

        if recognizedStrings.isEmpty {
          continuation.resume(throwing: OCRError.noTextFound)
        } else {
          continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
        }
      }

      // Configure for best accuracy
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true

      let handler = VNImageRequestHandler(cgImage: image, options: [:])

      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: OCRError.recognitionFailed(error))
      }
    }
  }

  /// Recognize text from an NSImage
  /// - Parameter image: The NSImage to extract text from
  /// - Returns: Recognized text joined by newlines
  func recognizeText(from image: NSImage) async throws -> String {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      throw OCRError.imageConversionFailed
    }
    return try await recognizeText(from: cgImage)
  }
}
```

### Step 2: Add OCRService to Xcode Project

Add `OCRService.swift` to the `Snapzy/Core/Services` group in Xcode project.

## Todo List

- [ ] Create OCRService.swift file
- [ ] Add to Xcode project
- [ ] Write unit tests for OCR recognition
- [ ] Test with various image types (screenshots, photos)
- [ ] Verify error handling works correctly

## Success Criteria

1. `OCRService.shared.recognizeText(from:)` returns extracted text
2. Handles images with no text gracefully (throws `.noTextFound`)
3. Works with both CGImage and NSImage inputs
4. Recognition completes in < 2 seconds for typical screenshots

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Poor accuracy on stylized text | Medium | Low | Document limitation; `.accurate` mode helps |
| Large image processing time | Low | Medium | Vision optimized; could add size limits |
| Memory pressure on huge screens | Low | Low | macOS handles well; region selection limits size |

## Security Considerations

- All OCR processing happens on-device (no data leaves machine)
- No network requests required
- Recognized text only stored in clipboard (user-controlled)

## Next Steps

After completion, proceed to [Phase 02: Shortcut Integration](./phase-02-shortcut-integration.md)
