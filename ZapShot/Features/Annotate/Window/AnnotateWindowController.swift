//
//  AnnotateWindowController.swift
//  ZapShot
//
//  Controller managing annotation window lifecycle
//

import AppKit
import Combine
import SwiftUI

/// Manages annotation window lifecycle and content
@MainActor
final class AnnotateWindowController: NSWindowController {

  private let state: AnnotateState
  private var cancellables = Set<AnyCancellable>()

  init(item: QuickAccessItem) {
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

  /// Empty initializer for drag-drop workflow
  init() {
    self.state = AnnotateState()

    // Default window size for empty canvas
    let screen = NSScreen.main ?? NSScreen.screens.first!
    let defaultWidth: CGFloat = 900
    let defaultHeight: CGFloat = 700

    let origin = NSPoint(
      x: (screen.frame.width - defaultWidth) / 2,
      y: (screen.frame.height - defaultHeight) / 2
    )

    let window = AnnotateWindow(
      contentRect: NSRect(origin: origin, size: NSSize(width: defaultWidth, height: defaultHeight))
    )

    super.init(window: window)

    setupContent()
    setupImageObserver()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    cancellables.removeAll()
  }

  private func setupContent() {
    let capturedState = self.state
    let mainView = AnnotateMainView(state: capturedState)
    window?.contentView = NSHostingView(rootView: mainView)
  }

  /// Observe image changes to resize window when image is loaded
  private func setupImageObserver() {
    state.$sourceImage
      .dropFirst()
      .compactMap { $0 }
      .first()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.resizeToFitImage()
      }
      .store(in: &cancellables)
  }

  /// Resize window to fit loaded image
  private func resizeToFitImage() {
    guard let image = state.sourceImage,
          let window = window,
          let screen = window.screen ?? NSScreen.main else { return }

    let maxWidth = screen.frame.width * 0.8
    let maxHeight = screen.frame.height * 0.8
    let imageSize = image.size

    let scale = min(maxWidth / imageSize.width, maxHeight / imageSize.height, 1.0)
    let windowWidth = max(800, imageSize.width * scale + 280)
    let windowHeight = max(600, imageSize.height * scale + 120)

    let newFrame = NSRect(
      x: window.frame.midX - windowWidth / 2,
      y: window.frame.midY - windowHeight / 2,
      width: windowWidth,
      height: windowHeight
    )

    window.setFrame(newFrame, display: true, animate: true)
  }

  func showWindow() {
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  // MARK: - Image Loading

  /// Load image and adjust size for Retina displays
  private static func loadImageWithCorrectScale(from url: URL) -> NSImage? {
    guard let image = NSImage(contentsOf: url) else { return nil }

    guard let bitmapRep = image.representations.first as? NSBitmapImageRep else {
      if let rep = image.representations.first {
        let pixelWidth = rep.pixelsWide
        let pixelHeight = rep.pixelsHigh
        if pixelWidth > 0 && pixelHeight > 0 {
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
    let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0

    image.size = NSSize(
      width: CGFloat(pixelWidth) / scaleFactor,
      height: CGFloat(pixelHeight) / scaleFactor
    )

    return image
  }
}
