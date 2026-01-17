//
//  QuickAccessItem.swift
//  ZapShot
//
//  Data model for a captured screenshot in the quick access stack
//

import AppKit
import Foundation

/// Represents a single screenshot in the quick access preview stack
struct QuickAccessItem: Identifiable, Equatable {
  let id: UUID
  let url: URL
  let thumbnail: NSImage
  let capturedAt: Date

  init(url: URL, thumbnail: NSImage) {
    self.id = UUID()
    self.url = url
    self.thumbnail = thumbnail
    self.capturedAt = Date()
  }

  static func == (lhs: QuickAccessItem, rhs: QuickAccessItem) -> Bool {
    lhs.id == rhs.id
  }
}
