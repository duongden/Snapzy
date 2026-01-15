//
//  AnnotateWindowController.swift
//  ZapShot
//
//  Controller managing annotation window lifecycle
//

import AppKit
import SwiftUI

/// Manages annotation window lifecycle and content
@MainActor
final class AnnotateWindowController: NSWindowController {

  private let state: AnnotateState

  init(item: ScreenshotItem) {
    // Load full image from URL and adjust for Retina scaling
    let image = Self.loadImageWithCorrectScale(from: item.url) ?? item.thumbnail

    self.state = AnnotateState(image: image, url: item.url)

    // Calculate window size based on image
    let screen = NSScreen.main ?? NSScreen.screens.first!
    let maxWidth = screen.frame.width * 0.8
    let maxHeight = screen.frame.height * 0.8
    let imageSize = image.size

    // Scale to fit screen while maintaining aspect ratio
    let scale = min(maxWidth / imageSize.width, maxHeight / imageSize.height, 1.0)
    let windowWidth = max(800, imageSize.width * scale + 280) // 280 for sidebar + padding
    let windowHeight = max(600, imageSize.height * scale + 120) // 120 for toolbar + bottom

    let origin = NSPoint(
      x: (screen.frame.width - windowWidth) / 2,
      y: (screen.frame.height - windowHeight) / 2
    )

    let window = AnnotateWindow(
      contentRect: NSRect(origin: origin, size: NSSize(width: windowWidth, height: windowHeight))
    )

    super.init(window: window)

    setupContent()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupContent() {
    let capturedState = self.state
    let mainView = AnnotateMainView(state: capturedState)
    window?.contentView = NSHostingView(rootView: mainView)
  }

  func showWindow() {
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  // MARK: - Image Loading

  /// Load image and adjust size for Retina displays
  /// Captured images are at 2x pixel resolution but should display at 1x point size
  private static func loadImageWithCorrectScale(from url: URL) -> NSImage? {
    guard let image = NSImage(contentsOf: url) else { return nil }

    // Get the actual pixel dimensions from the bitmap representation
    guard let bitmapRep = image.representations.first as? NSBitmapImageRep else {
      // If no bitmap rep, try to get pixel size from any representation
      if let rep = image.representations.first {
        let pixelWidth = rep.pixelsWide
        let pixelHeight = rep.pixelsHigh
        if pixelWidth > 0 && pixelHeight > 0 {
          // Assume Retina (2x) - divide by main screen's backing scale
          let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
          image.size = NSSize(
            width: CGFloat(pixelWidth) / scaleFactor,
            height: CGFloat(pixelHeight) / scaleFactor
          )
        }
      }
      return image
    }

    let pixelWidth = bitmapRep.pixelsWide
    let pixelHeight = bitmapRep.pixelsHigh

    // Get the screen's backing scale factor (2.0 for Retina)
    let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0

    // Set the image size to point dimensions (pixels / scale factor)
    // This ensures the image displays at the correct size while retaining full resolution
    image.size = NSSize(
      width: CGFloat(pixelWidth) / scaleFactor,
      height: CGFloat(pixelHeight) / scaleFactor
    )

    return image
  }
}
