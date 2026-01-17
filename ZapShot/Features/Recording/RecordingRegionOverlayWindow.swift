//
//  RecordingRegionOverlayWindow.swift
//  ZapShot
//
//  Persistent overlay window showing the recording region highlight
//

import AppKit

/// Overlay window showing the recording region highlight during recording
@MainActor
final class RecordingRegionOverlayWindow: NSWindow {

  private let overlayView: RecordingRegionOverlayView

  init(screen: NSScreen, highlightRect: CGRect) {
    self.overlayView = RecordingRegionOverlayView(
      frame: screen.frame,
      highlightRect: highlightRect
    )

    super.init(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    configureWindow()
    contentView = overlayView
  }

  private func configureWindow() {
    isOpaque = false
    backgroundColor = .clear
    level = .floating
    ignoresMouseEvents = true
    hasShadow = false
    isReleasedWhenClosed = false
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
  }

  func updateHighlightRect(_ rect: CGRect) {
    overlayView.highlightRect = rect
    overlayView.needsDisplay = true
  }

  /// Hide the border when recording starts (border would appear in video)
  func hideBorder() {
    overlayView.showBorder = false
    overlayView.needsDisplay = true
  }

  /// Show the border (for pre-record phase)
  func showBorder() {
    overlayView.showBorder = true
    overlayView.needsDisplay = true
  }
}

// MARK: - RecordingRegionOverlayView

/// View that draws the dimmed overlay with highlighted recording region
final class RecordingRegionOverlayView: NSView {

  var highlightRect: CGRect
  var showBorder: Bool = true

  private let dimColor = NSColor.black.withAlphaComponent(0.4)
  private let borderColor = NSColor.white
  private let borderWidth: CGFloat = 2.0

  init(frame: CGRect, highlightRect: CGRect) {
    self.highlightRect = highlightRect
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // Draw dim overlay
    dimColor.setFill()
    bounds.fill()

    // Convert screen coords to view coords
    guard let window = window else { return }
    let windowFrame = window.frame
    let localRect = CGRect(
      x: highlightRect.origin.x - windowFrame.origin.x,
      y: highlightRect.origin.y - windowFrame.origin.y,
      width: highlightRect.width,
      height: highlightRect.height
    )

    // Only draw highlight if rect intersects this screen
    guard localRect.intersects(bounds) else { return }

    // Clamp to bounds
    let clampedRect = localRect.intersection(bounds)

    // Clear the highlight area
    NSColor.clear.setFill()
    clampedRect.fill(using: .copy)

    // Draw border around highlight (only in pre-record phase)
    if showBorder {
      let borderPath = NSBezierPath(rect: clampedRect)
      borderPath.lineWidth = borderWidth
      borderColor.setStroke()
      borderPath.stroke()
    }
  }
}
