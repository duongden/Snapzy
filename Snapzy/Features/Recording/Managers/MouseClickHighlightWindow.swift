//
//  MouseClickHighlightWindow.swift
//  Snapzy
//
//  Transparent overlay window that draws ripple wave effects at click positions
//  and a persistent follow-circle while the mouse is held down.
//  Captured by ScreenCaptureKit via exceptingWindows so the effect
//  appears in the recorded video.
//

import AppKit
import QuartzCore

@MainActor
final class MouseClickHighlightWindow: NSWindow {

  /// Persistent circle that follows the cursor while mouse is held
  private var holdCircleView: HoldCircleView?

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
    level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    ignoresMouseEvents = true
  }

  // MARK: - Public

  var overlayWindowID: CGWindowID {
    CGWindowID(windowNumber)
  }

  func updateRecordingRect(_ rect: CGRect) {
    setFrame(rect, display: true)
  }

  /// On mouse-down: spawn ripple waves and show hold circle
  func showClickEffect(at screenPoint: NSPoint) {
    guard let contentView else { return }

    let viewPoint = viewPosition(from: screenPoint)

    // Spawn expanding ripple rings
    for i in 0..<3 {
      let delay = CFTimeInterval(i) * 0.12
      let ripple = RippleRingView(center: viewPoint)
      contentView.addSubview(ripple)
      ripple.animateExpand(delay: delay) { [weak ripple] in
        ripple?.removeFromSuperview()
      }
    }

    // Show persistent hold circle
    holdCircleView?.removeFromSuperview()
    let hold = HoldCircleView(center: viewPoint)
    contentView.addSubview(hold)
    hold.animateIn()
    holdCircleView = hold
  }

  /// While mouse is held and dragged, move the hold circle to follow cursor
  func moveClickEffect(to screenPoint: NSPoint) {
    guard let hold = holdCircleView else { return }
    let viewPoint = viewPosition(from: screenPoint)
    hold.updateCenter(viewPoint)
  }

  /// On mouse-up: fade out and remove the hold circle
  func dismissClickEffect() {
    guard let hold = holdCircleView else { return }
    holdCircleView = nil
    hold.animateOut { [weak hold] in
      hold?.removeFromSuperview()
    }
  }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }

  // MARK: - Helpers

  private func viewPosition(from screenPoint: NSPoint) -> NSPoint {
    let windowPoint = convertPoint(fromScreen: screenPoint)
    return NSPoint(x: windowPoint.x, y: windowPoint.y)
  }
}

// MARK: - Ripple Ring View

/// A single hollow circular ring that expands outward and fades.
private final class RippleRingView: NSView {

  static let maxDiameter: CGFloat = 50
  static let ringWidth: CGFloat = 2
  static let animationDuration: CFTimeInterval = 0.7

  private let ringLayer = CAShapeLayer()

  init(center: NSPoint) {
    let size = Self.maxDiameter
    let frame = CGRect(
      x: center.x - size / 2,
      y: center.y - size / 2,
      width: size,
      height: size
    )
    super.init(frame: frame)

    wantsLayer = true
    layer?.masksToBounds = false
    setupRingLayer()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  private func setupRingLayer() {
    let bounds = CGRect(origin: .zero, size: CGSize(width: Self.maxDiameter, height: Self.maxDiameter))
    let inset = Self.ringWidth / 2
    let path = CGPath(ellipseIn: bounds.insetBy(dx: inset, dy: inset), transform: nil)

    ringLayer.path = path
    ringLayer.fillColor = nil
    ringLayer.strokeColor = NSColor(
      displayP3Red: 0.068, green: 0.222, blue: 1.0, alpha: 0.5
    ).cgColor
    ringLayer.lineWidth = Self.ringWidth
    ringLayer.frame = bounds

    // Start small and invisible
    ringLayer.opacity = 0
    ringLayer.transform = CATransform3DMakeScale(0.15, 0.15, 1)

    layer?.addSublayer(ringLayer)
  }

  func animateExpand(delay: CFTimeInterval, completion: @escaping () -> Void) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)

    // Scale: small → full
    let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
    scaleAnim.fromValue = 0.15
    scaleAnim.toValue = 1.0
    scaleAnim.duration = Self.animationDuration
    scaleAnim.beginTime = CACurrentMediaTime() + delay
    scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    scaleAnim.fillMode = .both
    scaleAnim.isRemovedOnCompletion = false

    // Opacity: appear then fade
    let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
    opacityAnim.values = [0.0, 0.8, 0.0]
    opacityAnim.keyTimes = [0, 0.25, 1.0]
    opacityAnim.duration = Self.animationDuration
    opacityAnim.beginTime = CACurrentMediaTime() + delay
    opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    opacityAnim.fillMode = .both
    opacityAnim.isRemovedOnCompletion = false

    ringLayer.add(scaleAnim, forKey: "rippleScale")
    ringLayer.add(opacityAnim, forKey: "rippleFade")

    CATransaction.commit()
  }
}

// MARK: - Hold Circle View

/// A persistent hollow circle that follows the cursor while the mouse is held down.
private final class HoldCircleView: NSView {

  static let diameter: CGFloat = 36
  static let ringWidth: CGFloat = 2

  private let ringLayer = CAShapeLayer()

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
    setupRingLayer()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  private func setupRingLayer() {
    let bounds = CGRect(origin: .zero, size: CGSize(width: Self.diameter, height: Self.diameter))
    let inset = Self.ringWidth / 2
    let path = CGPath(ellipseIn: bounds.insetBy(dx: inset, dy: inset), transform: nil)

    ringLayer.path = path
    ringLayer.fillColor = nil
    ringLayer.strokeColor = NSColor(
      displayP3Red: 0.068, green: 0.222, blue: 1.0, alpha: 0.5
    ).cgColor
    ringLayer.lineWidth = Self.ringWidth
    ringLayer.frame = bounds

    ringLayer.opacity = 0
    ringLayer.transform = CATransform3DMakeScale(0.5, 0.5, 1)

    layer?.addSublayer(ringLayer)
  }

  func updateCenter(_ point: NSPoint) {
    let size = Self.diameter
    frame = CGRect(
      x: point.x - size / 2,
      y: point.y - size / 2,
      width: size,
      height: size
    )
  }

  func animateIn() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
    scaleAnim.fromValue = 0.5
    scaleAnim.toValue = 1.0
    scaleAnim.duration = 0.15
    scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    scaleAnim.fillMode = .forwards
    scaleAnim.isRemovedOnCompletion = false

    let opacityAnim = CABasicAnimation(keyPath: "opacity")
    opacityAnim.fromValue = 0.0
    opacityAnim.toValue = 1.0
    opacityAnim.duration = 0.15
    opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    opacityAnim.fillMode = .forwards
    opacityAnim.isRemovedOnCompletion = false

    ringLayer.add(scaleAnim, forKey: "holdScaleIn")
    ringLayer.add(opacityAnim, forKey: "holdFadeIn")

    CATransaction.commit()
  }

  func animateOut(completion: @escaping () -> Void) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)

    let opacityAnim = CABasicAnimation(keyPath: "opacity")
    opacityAnim.fromValue = 1.0
    opacityAnim.toValue = 0.0
    opacityAnim.duration = 0.3
    opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
    opacityAnim.fillMode = .forwards
    opacityAnim.isRemovedOnCompletion = false

    ringLayer.add(opacityAnim, forKey: "holdFadeOut")

    CATransaction.commit()
  }
}
