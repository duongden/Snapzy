//
//  ExportSettings.swift
//  Snapzy
//
//  Export configuration models for video editor
//

import AVFoundation
import Foundation

enum VideoEditorExportLayout {
  private static let minimumEvenDimension = 2

  static func evenSize(_ size: CGSize) -> CGSize {
    CGSize(
      width: CGFloat(evenDimension(for: size.width)),
      height: CGFloat(evenDimension(for: size.height))
    )
  }

  static func aspectRatioCanvasSize(for naturalSize: CGSize, aspectRatio: CGSize) -> CGSize {
    guard naturalSize.width > 0,
          naturalSize.height > 0,
          aspectRatio.width > 0,
          aspectRatio.height > 0
    else {
      return .zero
    }

    let naturalShortEdge = min(naturalSize.width, naturalSize.height)
    let ratioShortEdge = min(aspectRatio.width, aspectRatio.height)
    let scale = naturalShortEdge / ratioShortEdge

    return evenSize(
      CGSize(
        width: aspectRatio.width * scale,
        height: aspectRatio.height * scale
      )
    )
  }

  static func aspectFitRect(sourceSize: CGSize, in canvasSize: CGSize) -> CGRect {
    guard sourceSize.width > 0,
          sourceSize.height > 0,
          canvasSize.width > 0,
          canvasSize.height > 0
    else {
      return CGRect(origin: .zero, size: canvasSize)
    }

    let scale = min(canvasSize.width / sourceSize.width, canvasSize.height / sourceSize.height)
    let fittedSize = CGSize(
      width: sourceSize.width * scale,
      height: sourceSize.height * scale
    )

    return CGRect(
      x: (canvasSize.width - fittedSize.width) / 2,
      y: (canvasSize.height - fittedSize.height) / 2,
      width: fittedSize.width,
      height: fittedSize.height
    )
  }

  static func aspectRatioString(for size: CGSize) -> String? {
    let width = Int(size.width.rounded())
    let height = Int(size.height.rounded())
    guard width > 0, height > 0 else { return nil }

    let divisor = gcd(width, height)
    guard divisor > 0 else { return nil }

    return "\(width / divisor):\(height / divisor)"
  }

  private static func evenDimension(for value: CGFloat) -> Int {
    let rounded = max(Int(value.rounded()), minimumEvenDimension)
    let evenValue = rounded - (rounded % 2)
    return max(evenValue, minimumEvenDimension)
  }

  private static func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a)
    var y = abs(b)

    while y != 0 {
      let remainder = x % y
      x = y
      y = remainder
    }

    return max(x, 1)
  }
}

// MARK: - Export Quality

enum ExportQuality: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .low: return L10n.Common.low
        case .medium: return L10n.Common.medium
        case .high: return L10n.Common.high
        }
    }

    /// Maps to AVAssetExportSession preset
    var exportPreset: String {
        switch self {
        case .low: return AVAssetExportPresetMediumQuality
        case .medium: return AVAssetExportPresetHighestQuality
        case .high: return AVAssetExportPresetHighestQuality
        }
    }

    /// Bitrate multiplier for file size estimation
    var bitrateMultiplier: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        }
    }
}

// MARK: - Audio Export Mode

enum AudioExportMode: String, CaseIterable, Identifiable {
    case keep = "Keep Original"
    case mute = "Mute"
    case custom = "Custom Volume"

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .keep: return L10n.VideoEditor.keepOriginal
        case .mute: return L10n.VideoEditor.mute
        case .custom: return L10n.VideoEditor.customVolume
        }
    }

    var icon: String {
        switch self {
        case .keep: return "speaker.wave.2"
        case .mute: return "speaker.slash"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Export Dimensions

enum ExportDimensionPreset: String, CaseIterable, Identifiable {
  case original = "Original"
  case ratio1x1 = "1:1"
  case ratio4x3 = "4:3"
  case ratio3x2 = "3:2"
  case ratio16x9 = "16:9"
  case ratio9x16 = "9:16"
  case percent90 = "90%"
  case percent80 = "80%"
  case percent60 = "60%"
  case percent50 = "50%"
  case percent40 = "40%"
  case percent30 = "30%"
  case percent20 = "20%"
  case custom = "Custom"

  var id: String { rawValue }

  static let aspectRatioPresets: [ExportDimensionPreset] = [
    .ratio1x1,
    .ratio4x3,
    .ratio3x2,
    .ratio16x9,
    .ratio9x16,
  ]

  /// Returns scale factor for percentage-based presets
  var scaleFactor: CGFloat? {
    switch self {
    case .percent90: return 0.90
    case .percent80: return 0.80
    case .percent60: return 0.60
    case .percent50: return 0.50
    case .percent40: return 0.40
    case .percent30: return 0.30
    case .percent20: return 0.20
    default: return nil
    }
  }

  var aspectRatio: CGSize? {
    switch self {
    case .ratio1x1:
      return CGSize(width: 1, height: 1)
    case .ratio4x3:
      return CGSize(width: 4, height: 3)
    case .ratio3x2:
      return CGSize(width: 3, height: 2)
    case .ratio16x9:
      return CGSize(width: 16, height: 9)
    case .ratio9x16:
      return CGSize(width: 9, height: 16)
    default:
      return nil
    }
  }

  var isAspectRatioPreset: Bool {
    aspectRatio != nil
  }

  /// Display label showing dimensions when available
  func displayLabel(for naturalSize: CGSize) -> String {
    // Guard against invalid dimensions (before video loads)
    guard naturalSize.width > 0 && naturalSize.height > 0 else {
      return rawValue
    }

    switch self {
    case .original:
      return L10n.VideoEditor.originalDimensionsLabel(
        Int(naturalSize.width),
        Int(naturalSize.height)
      )
    case .ratio1x1, .ratio4x3, .ratio3x2, .ratio16x9, .ratio9x16:
      guard let aspectRatio else { return rawValue }
      let size = VideoEditorExportLayout.aspectRatioCanvasSize(
        for: naturalSize,
        aspectRatio: aspectRatio
      )
      return "\(rawValue) (\(Int(size.width))×\(Int(size.height)))"
    case .percent90, .percent80, .percent60, .percent50, .percent40, .percent30, .percent20:
      guard let scale = scaleFactor else { return rawValue }
      let size = VideoEditorExportLayout.evenSize(
        CGSize(
          width: naturalSize.width * scale,
          height: naturalSize.height * scale
        )
      )
      return "\(rawValue) (\(Int(size.width))×\(Int(size.height)))"
    case .custom:
      return L10n.Common.custom
    }
  }
}

// MARK: - Export Settings Container

struct ExportSettings: Equatable {
    var quality: ExportQuality = .high
    var dimensionPreset: ExportDimensionPreset = .original
    var customWidth: Int = 1920
    var customHeight: Int = 1080
    var aspectRatioLocked: Bool = true
    var audioMode: AudioExportMode = .keep
    var audioVolume: Float = 1.0 // 0.0 to 2.0 (0% to 200%)

  /// Compute actual export dimensions for VIDEO CONTENT ONLY
  /// Note: Background padding is applied separately during rendering
  func exportSize(from naturalSize: CGSize) -> CGSize {
    switch dimensionPreset {
    case .original:
      return naturalSize

    case .ratio1x1, .ratio4x3, .ratio3x2, .ratio16x9, .ratio9x16:
      guard let aspectRatio = dimensionPreset.aspectRatio else {
        return naturalSize
      }
      return VideoEditorExportLayout.aspectRatioCanvasSize(
        for: naturalSize,
        aspectRatio: aspectRatio
      )

    case .percent90, .percent80, .percent60, .percent50, .percent40, .percent30, .percent20:
      guard let scale = dimensionPreset.scaleFactor else {
        return naturalSize
      }
      return VideoEditorExportLayout.evenSize(
        CGSize(
          width: naturalSize.width * scale,
          height: naturalSize.height * scale
        )
      )

    case .custom:
      return VideoEditorExportLayout.evenSize(
        CGSize(width: customWidth, height: customHeight)
      )
    }
  }

  func videoContentRect(from naturalSize: CGSize) -> CGRect {
    VideoEditorExportLayout.aspectFitRect(
      sourceSize: naturalSize,
      in: exportSize(from: naturalSize)
    )
  }

  func aspectRatioString(from naturalSize: CGSize) -> String? {
    VideoEditorExportLayout.aspectRatioString(for: exportSize(from: naturalSize))
  }

    /// Check if audio should be included in export
    var shouldIncludeAudio: Bool {
        audioMode != .mute
    }

    /// Get effective volume (0.0 to 2.0)
    var effectiveVolume: Float {
        switch audioMode {
        case .keep: return 1.0
        case .mute: return 0.0
        case .custom: return audioVolume
        }
    }
}
