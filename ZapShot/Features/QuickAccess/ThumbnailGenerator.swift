//
//  ThumbnailGenerator.swift
//  ZapShot
//
//  Efficient thumbnail generation from screenshot files
//

import AppKit
import Foundation

/// Utility for generating thumbnails from screenshot files
enum ThumbnailGenerator {

  /// Generate a downscaled thumbnail from an image URL
  /// - Parameters:
  ///   - url: Source image file URL
  ///   - maxSize: Maximum dimension (width or height) for thumbnail
  /// - Returns: Downscaled NSImage or nil if generation fails
  static func generate(from url: URL, maxSize: CGFloat = 200) async -> NSImage? {
    guard let image = NSImage(contentsOf: url) else { return nil }

    let originalSize = image.size
    guard originalSize.width > 0, originalSize.height > 0 else { return nil }

    // Calculate scaled size maintaining aspect ratio
    let scale: CGFloat
    if originalSize.width > originalSize.height {
      scale = min(maxSize / originalSize.width, 1.0)
    } else {
      scale = min(maxSize / originalSize.height, 1.0)
    }

    // If image is already small enough, return as-is
    if scale >= 1.0 {
      return image
    }

    let newSize = CGSize(
      width: originalSize.width * scale,
      height: originalSize.height * scale
    )

    // Create thumbnail
    let thumbnail = NSImage(size: newSize)
    thumbnail.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(
      in: NSRect(origin: .zero, size: newSize),
      from: NSRect(origin: .zero, size: originalSize),
      operation: .copy,
      fraction: 1.0
    )
    thumbnail.unlockFocus()

    return thumbnail
  }
}
