//
//  MouseClickHighlightWindow.swift
//  Snapzy
//
//  Transparent overlay window that draws animated circles at click positions.
//  Captured by ScreenCaptureKit via exceptingWindows so the effect
//  appears in the recorded video.
//

import AppKit
import QuartzCore

@MainActor
final class MouseClickHighlightWindow: NSWindow {

  init(recordingRect: CGRect) {
    super.init(
      contentRect: recordingRect,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    configureWindow()
  }

  // MARK: - Configuration

  private func configureWindow() {
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    isReleasedWhenClosed = false
    // Same level as annotation overlay — between .floating and .popUpMenu
    level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    // Pass-through so clicks reach the underlying app
    ignoresMouseEvents = true
  }

  // MARK: - Public

  /// The CGWindowID used for ScreenCaptureKit exceptingWindows
  var overlayWindowID: CGWindowID {
    CGWindowID(windowNumber)
  }

  /// Update frame when recording rect changes
  func updateRecordingRect(_ rect: CGRect) {
    setFrame(rect, display: true)
  }

  /// Show an animated click circle at the given screen position
  func showClickEffect(at screenPoint: NSPoint) {
    guard let contentView else { return }

    // Convert screen position to window-local position
    let windowPoint = convertPoint(fromScreen: screenPoint)
    // Flip Y from window coords (bottom-left origin) to view coords
    let viewPoint = NSPoint(x: windowPoint.x, y: windowPoint.y)

    let effectView = ClickEffectView(center: viewPoint)
    contentView.addSubview(effectView)
    effectView.animate { [weak effectView] in
      effectView?.removeFromSuperview()
    }
  }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}

// MARK: - Click Effect View

private final class ClickEffectView: NSView {

  static let diameter: CGFloat = 40
  static let animationDuration: CFTimeInterval = 0.4

  private let circleLayer = CAShapeLayer()
  private var completionHandler: (() -> Void)?

  init(center: NSPoint) {
    let size = Self.diameter
    let frame = CGRect(
      x: center.x - size / 2,
      y: center.y - size / 2,
      width: size,
      height: size
    )
    super.init(frame: frame)

    wantsLayer = true
    layer?.masksToBounds = false
    setupCircleLayer()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  private func setupCircleLayer() {
    let bounds = CGRect(origin: .zero, size: CGSize(width: Self.diameter, height: Self.diameter))
    let path = CGPath(ellipseIn: bounds, transform: nil)

    circleLayer.path = path
    circleLayer.fillColor = NSColor(
      displayP3Red: 0.068, green: 0.222, blue: 1.0, alpha: 0.35
    ).cgColor
    circleLayer.strokeColor = nil
    circleLayer.frame = bounds

    // Initial state — scaled down and semi-transparent
    circleLayer.opacity = 0.5
    circleLayer.transform = CATransform3DMakeScale(0.5, 0.5, 1)

    layer?.addSublayer(circleLayer)
  }

  func animate(completion: @escaping () -> Void) {
    completionHandler = completion

    CATransaction.begin()
    CATransaction.setCompletionBlock { [weak self] in
      self?.completionHandler?()
    }

    // Scale: 0.5 → 1.0
    let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
    scaleAnim.fromValue = 0.5
    scaleAnim.toValue = 1.0
    scaleAnim.duration = Self.animationDuration
    scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    scaleAnim.fillMode = .forwards
    scaleAnim.isRemovedOnCompletion = false

    // Opacity: 0.5 → 0.0
    let opacityAnim = CABasicAnimation(keyPath: "opacity")
    opacityAnim.fromValue = 0.5
    opacityAnim.toValue = 0.0
    opacityAnim.duration = Self.animationDuration
    opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    opacityAnim.fillMode = .forwards
    opacityAnim.isRemovedOnCompletion = false

    circleLayer.add(scaleAnim, forKey: "scaleUp")
    circleLayer.add(opacityAnim, forKey: "fadeOut")

    CATransaction.commit()
  }
}
