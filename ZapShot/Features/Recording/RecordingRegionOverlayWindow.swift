//
//  RecordingRegionOverlayWindow.swift
//  ZapShot
//
//  Persistent overlay window showing the recording region highlight
//

import AppKit

// MARK: - RecordingRegionOverlayDelegate

/// Delegate protocol for overlay interaction events
@MainActor
protocol RecordingRegionOverlayDelegate: AnyObject {
  func overlayDidRequestReselection(_ overlay: RecordingRegionOverlayWindow)
  func overlay(_ overlay: RecordingRegionOverlayWindow, didMoveRegionTo rect: CGRect)
  func overlayDidFinishMoving(_ overlay: RecordingRegionOverlayWindow)
  func overlay(_ overlay: RecordingRegionOverlayWindow, didReselectWithRect rect: CGRect)
}

// MARK: - RecordingRegionOverlayWindow

/// Overlay window showing the recording region highlight during recording
@MainActor
final class RecordingRegionOverlayWindow: NSWindow {

  weak var interactionDelegate: RecordingRegionOverlayDelegate?

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

  /// Enable or disable mouse interaction (disabled during recording)
  func setInteractionEnabled(_ enabled: Bool) {
    ignoresMouseEvents = !enabled
    overlayView.isInteractionEnabled = enabled
    if enabled {
      overlayView.overlayWindow = self
    }
  }

  override var canBecomeKey: Bool { true }
}

// MARK: - RecordingRegionOverlayView

/// View that draws the dimmed overlay with highlighted recording region
final class RecordingRegionOverlayView: NSView {

  var highlightRect: CGRect
  var showBorder: Bool = true
  var isInteractionEnabled: Bool = false
  weak var overlayWindow: RecordingRegionOverlayWindow?

  // Drag state
  private var isDragging = false
  private var dragOffset: CGPoint = .zero

  // New selection state (for immediate reselection on click outside)
  private var isNewSelecting = false
  private var newSelectionStart: CGPoint = .zero
  private var newSelectionEnd: CGPoint = .zero

  private let dimColor = NSColor.black.withAlphaComponent(0.4)
  private let borderColor = NSColor.white
  private let borderWidth: CGFloat = 2.0

  init(frame: CGRect, highlightRect: CGRect) {
    self.highlightRect = highlightRect
    super.init(frame: frame)
    setupTrackingArea()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupTrackingArea() {
    let trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.activeAlways, .mouseMoved, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea)
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    for area in trackingAreas {
      removeTrackingArea(area)
    }
    setupTrackingArea()
  }

  // Accept first mouse click without requiring window activation
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    return true
  }

  // MARK: - Coordinate Conversion

  private func localHighlightRect() -> CGRect {
    guard let window = window else { return .zero }
    let windowFrame = window.frame
    return CGRect(
      x: highlightRect.origin.x - windowFrame.origin.x,
      y: highlightRect.origin.y - windowFrame.origin.y,
      width: highlightRect.width,
      height: highlightRect.height
    )
  }

  private func convertToScreenCoords(_ localPoint: CGPoint) -> CGPoint {
    guard let window = window else { return localPoint }
    return CGPoint(
      x: localPoint.x + window.frame.origin.x,
      y: localPoint.y + window.frame.origin.y
    )
  }

  // MARK: - Mouse Events

  override func mouseDown(with event: NSEvent) {
    guard isInteractionEnabled, let overlayWindow = overlayWindow else { return }

    let point = convert(event.locationInWindow, from: nil)
    let localRect = localHighlightRect()

    if localRect.contains(point) {
      // Start dragging existing selection
      isDragging = true
      dragOffset = CGPoint(
        x: point.x - localRect.origin.x,
        y: point.y - localRect.origin.y
      )
      NSCursor.closedHand.set()
    } else {
      // Click outside - start new selection immediately
      isNewSelecting = true
      newSelectionStart = point
      newSelectionEnd = point
      NSCursor.crosshair.set()
    }
  }

  override func mouseDragged(with event: NSEvent) {
    guard isInteractionEnabled, let overlayWindow = overlayWindow else { return }

    let point = convert(event.locationInWindow, from: nil)

    if isNewSelecting {
      // Update new selection rect
      newSelectionEnd = point
      needsDisplay = true
    } else if isDragging {
      // Calculate new local origin for dragging
      var newLocalOrigin = CGPoint(
        x: point.x - dragOffset.x,
        y: point.y - dragOffset.y
      )

      // Clamp to screen bounds
      newLocalOrigin.x = max(0, min(newLocalOrigin.x, bounds.width - highlightRect.width))
      newLocalOrigin.y = max(0, min(newLocalOrigin.y, bounds.height - highlightRect.height))

      // Convert to screen coordinates
      let screenOrigin = convertToScreenCoords(newLocalOrigin)
      let newRect = CGRect(origin: screenOrigin, size: highlightRect.size)

      // Notify delegate
      overlayWindow.interactionDelegate?.overlay(overlayWindow, didMoveRegionTo: newRect)
    }
  }

  override func mouseUp(with event: NSEvent) {
    guard let overlayWindow = overlayWindow else { return }

    if isNewSelecting {
      // Complete new selection
      isNewSelecting = false
      let newRect = calculateNewSelectionRect()

      // Only accept if selection is large enough
      if newRect.width > 5 && newRect.height > 5 {
        // Convert to screen coordinates
        let screenRect = CGRect(
          origin: convertToScreenCoords(newRect.origin),
          size: newRect.size
        )
        overlayWindow.interactionDelegate?.overlay(overlayWindow, didReselectWithRect: screenRect)
      }
      needsDisplay = true
    } else if isDragging {
      isDragging = false
      NSCursor.openHand.set()
      overlayWindow.interactionDelegate?.overlayDidFinishMoving(overlayWindow)
    }
  }

  private func calculateNewSelectionRect() -> CGRect {
    let minX = min(newSelectionStart.x, newSelectionEnd.x)
    let maxX = max(newSelectionStart.x, newSelectionEnd.x)
    let minY = min(newSelectionStart.y, newSelectionEnd.y)
    let maxY = max(newSelectionStart.y, newSelectionEnd.y)
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
  }

  override func mouseMoved(with event: NSEvent) {
    guard isInteractionEnabled else { return }

    let point = convert(event.locationInWindow, from: nil)
    let localRect = localHighlightRect()

    if localRect.contains(point) {
      NSCursor.openHand.set()
    } else {
      NSCursor.crosshair.set()
    }
  }

  // MARK: - Drawing

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // Draw dim overlay
    dimColor.setFill()
    bounds.fill()

    // If actively making new selection, draw that instead
    if isNewSelecting {
      drawNewSelection()
      return
    }

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

  private func drawNewSelection() {
    let selectionRect = calculateNewSelectionRect()
    guard selectionRect.width > 0 && selectionRect.height > 0 else { return }

    // Clear the selection area
    NSColor.clear.setFill()
    selectionRect.fill(using: .copy)

    // Draw border
    let borderPath = NSBezierPath(rect: selectionRect)
    borderPath.lineWidth = borderWidth
    borderColor.setStroke()
    borderPath.stroke()

    // Draw size indicator
    let sizeText = "\(Int(selectionRect.width)) x \(Int(selectionRect.height))"
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 12, weight: .medium),
      .foregroundColor: NSColor.white,
    ]
    let textSize = sizeText.size(withAttributes: attributes)
    var textRect = CGRect(
      x: selectionRect.maxX - textSize.width - 8,
      y: selectionRect.minY - textSize.height - 8,
      width: textSize.width + 8,
      height: textSize.height + 4
    )
    if textRect.minY < 0 { textRect.origin.y = selectionRect.maxY + 4 }
    if textRect.maxX > bounds.maxX { textRect.origin.x = selectionRect.minX }

    NSColor.black.withAlphaComponent(0.7).setFill()
    NSBezierPath(roundedRect: textRect, xRadius: 4, yRadius: 4).fill()
    sizeText.draw(at: CGPoint(x: textRect.minX + 4, y: textRect.minY + 2), withAttributes: attributes)
  }
}
