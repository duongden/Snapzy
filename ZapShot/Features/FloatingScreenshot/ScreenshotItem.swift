//
//  ScreenshotItem.swift
//  ZapShot
//
//  Data model for a captured screenshot in the floating stack
//

import AppKit
import Foundation

/// Represents a single screenshot in the floating preview stack
struct ScreenshotItem: Identifiable, Equatable {
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

  static func == (lhs: ScreenshotItem, rhs: ScreenshotItem) -> Bool {
    lhs.id == rhs.id
  }
}
