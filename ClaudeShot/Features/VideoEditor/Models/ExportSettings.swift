//
//  ExportSettings.swift
//  ClaudeShot
//
//  Export configuration models for video editor
//

import AVFoundation
import Foundation

// MARK: - Export Quality

enum ExportQuality: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

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
    case hd1080 = "1080p"
    case hd720 = "720p"
    case sd480 = "480p"
    case custom = "Custom"

    var id: String { rawValue }

    /// Returns target height (width calculated from aspect ratio)
    var targetHeight: Int? {
        switch self {
        case .original: return nil
        case .hd1080: return 1080
        case .hd720: return 720
        case .sd480: return 480
        case .custom: return nil
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

    /// Compute actual export dimensions
    func exportSize(from naturalSize: CGSize) -> CGSize {
        switch dimensionPreset {
        case .original:
            return naturalSize
        case .custom:
            // Ensure even dimensions for video encoding
            let evenWidth = customWidth - (customWidth % 2)
            let evenHeight = customHeight - (customHeight % 2)
            return CGSize(width: evenWidth, height: evenHeight)
        default:
            guard let targetHeight = dimensionPreset.targetHeight else {
                return naturalSize
            }
            let aspectRatio = naturalSize.width / naturalSize.height
            var targetWidth = Int(CGFloat(targetHeight) * aspectRatio)
            // Ensure even dimensions for video encoding
            targetWidth = targetWidth - (targetWidth % 2)
            let evenHeight = targetHeight - (targetHeight % 2)
            return CGSize(width: targetWidth, height: evenHeight)
        }
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
