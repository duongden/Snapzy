//
//  OCRScanningOverlayWindow.swift
//  Snapzy
//
//  Lightweight non-interactive progress overlay for OCR area capture.
//

import AppKit
import QuartzCore

@MainActor
final class OCRScanningOverlayController {
  static let shared = OCRScanningOverlayController()

  private var overlayWindow: OCRScanningOverlayWindow?
  private var activeSessionID: UUID?
  private var visibleSince: CFAbsoluteTime = 0
  private let minimumVisibleDuration: CFTimeInterval = 0.45

  private init() {}

  func begin(over rect: CGRect) -> UUID? {
    dismissImmediately()

    guard rect.width >= 8, rect.height >= 8 else { return nil }

    let sessionID = UUID()
    let window = OCRScanningOverlayWindow(rect: rect)
    activeSessionID = sessionID
    visibleSince = CFAbsoluteTimeGetCurrent()
    overlayWindow = window
    window.orderFrontRegardless()
    window.startAnimating()
    return sessionID
  }

  func finish(_ sessionID: UUID?) {
    guard let sessionID, sessionID == activeSessionID else { return }

    let remaining = max(0, minimumVisibleDuration - (CFAbsoluteTimeGetCurrent() - visibleSince))
    guard remaining > 0 else {
      dismissImmediately()
      return
    }

    Task { @MainActor in
      try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
      guard self.activeSessionID == sessionID else { return }
      self.dismissImmediately()
    }
  }

  private func dismissImmediately() {
    overlayWindow?.stopAnimating()
    overlayWindow?.orderOut(nil)
    overlayWindow?.close()
    overlayWindow = nil
    activeSessionID = nil
  }
}

@MainActor
private final class OCRScanningOverlayWindow: NSPanel {
  private let overlayView: OCRScanningOverlayView

  init(rect: CGRect) {
    self.overlayView = OCRScanningOverlayView(frame: CGRect(origin: .zero, size: rect.size))

    super.init(
      contentRect: rect,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    configureWindow()
    contentView = overlayView
  }

  private func configureWindow() {
    isFloatingPanel = true
    isOpaque = false
    backgroundColor = .clear
    sharingType = .none
    level = .screenSaver
    ignoresMouseEvents = true
    hasShadow = false
    hidesOnDeactivate = false
    isReleasedWhenClosed = false
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .transient]
    animationBehavior = .none
  }

  func startAnimating() { overlayView.startAnimating() }
  func stopAnimating() { overlayView.stopAnimating() }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}

private final class OCRScanningOverlayView: NSView {
  private let scanLayer = CAGradientLayer()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    setupLayers()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layout() {
    super.layout()
    layoutLayers()
  }

  func startAnimating() {
    layoutLayers()

    let lineHeight = scanLineHeight
    scanLayer.removeAnimation(forKey: "ocr-scan")
    scanLayer.position.y = -lineHeight / 2

    let scanAnimation = CABasicAnimation(keyPath: "position.y")
    scanAnimation.fromValue = bounds.height + lineHeight / 2
    scanAnimation.toValue = -lineHeight / 2
    scanAnimation.duration = 0.65
    scanAnimation.repeatCount = .infinity
    scanAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    scanLayer.add(scanAnimation, forKey: "ocr-scan")

    displayIfNeeded()
    CATransaction.flush()
  }

  func stopAnimating() {
    scanLayer.removeAllAnimations()
  }

  private var scanLineHeight: CGFloat { min(max(bounds.height * 0.025, 3), 10) }

  private func setupLayers() {
    guard let layer else { return }
    let tintColor = NSColor.controlAccentColor

    layer.masksToBounds = true

    scanLayer.startPoint = CGPoint(x: 0.5, y: 0)
    scanLayer.endPoint = CGPoint(x: 0.5, y: 1)
    scanLayer.colors = [
      tintColor.withAlphaComponent(0.00).cgColor,
      tintColor.withAlphaComponent(0.18).cgColor,
      NSColor.white.withAlphaComponent(0.55).cgColor,
      tintColor.withAlphaComponent(0.18).cgColor,
      tintColor.withAlphaComponent(0.00).cgColor
    ]
    scanLayer.locations = [0, 0.30, 0.50, 0.70, 1]

    layer.addSublayer(scanLayer)
  }

  private func layoutLayers() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    let lineHeight = scanLineHeight
    scanLayer.frame = CGRect(x: 0, y: bounds.height - lineHeight, width: bounds.width, height: lineHeight)

    CATransaction.commit()
  }
}
