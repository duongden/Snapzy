//
//  QuickAccessItem.swift
//  Snapzy
//
//  Data model for a captured item (screenshot or video) in the quick access stack
//

import AppKit
import Foundation

/// Type of quick access item
enum QuickAccessItemType: Equatable {
  case screenshot
  case video
}

/// Processing state for quick access item (annotation, conversion, etc.)
enum QuickAccessProcessingState: Equatable {
  case idle
  case processing(progress: Double?)  // nil = indeterminate
  case complete
  case failed

  var isProcessing: Bool {
    if case .processing = self { return true }
    return false
  }
}

/// Represents a single item (screenshot or video) in the quick access preview stack
struct QuickAccessItem: Identifiable, Equatable {
  let id: UUID
  let url: URL
  let thumbnail: NSImage
  let capturedAt: Date
  let itemType: QuickAccessItemType
  let duration: TimeInterval?
  var processingState: QuickAccessProcessingState = .idle
  /// Incremented when thumbnail changes — used by SwiftUI to detect visual updates
  let thumbnailVersion: UUID

  /// Initializer for screenshots (backward compatible)
  init(url: URL, thumbnail: NSImage) {
    self.id = UUID()
    self.url = url
    self.thumbnail = thumbnail
    self.capturedAt = Date()
    self.itemType = .screenshot
    self.duration = nil
    self.thumbnailVersion = UUID()
  }

  /// Initializer for videos with duration
  init(url: URL, thumbnail: NSImage, duration: TimeInterval) {
    self.id = UUID()
    self.url = url
    self.thumbnail = thumbnail
    self.capturedAt = Date()
    self.itemType = .video
    self.duration = duration
    self.thumbnailVersion = UUID()
  }

  /// Initializer with explicit id (used for thumbnail retry updates)
  init(id: UUID, url: URL, thumbnail: NSImage, capturedAt: Date, itemType: QuickAccessItemType, duration: TimeInterval?, thumbnailVersion: UUID = UUID()) {
    self.id = id
    self.url = url
    self.thumbnail = thumbnail
    self.capturedAt = capturedAt
    self.itemType = itemType
    self.duration = duration
    self.thumbnailVersion = thumbnailVersion
  }

  static func == (lhs: QuickAccessItem, rhs: QuickAccessItem) -> Bool {
    lhs.id == rhs.id && lhs.processingState == rhs.processingState && lhs.thumbnailVersion == rhs.thumbnailVersion
  }

  /// Whether this item is a video
  var isVideo: Bool {
    itemType == .video
  }

  /// Formatted duration string for display (e.g., "01:30s")
  var formattedDuration: String? {
    guard let duration = duration, duration.isFinite, duration >= 0 else {
      return nil
    }
    let mins = Int(duration) / 60
    let secs = Int(duration) % 60
    return String(format: "%02d:%02ds", mins, secs)
  }
}
