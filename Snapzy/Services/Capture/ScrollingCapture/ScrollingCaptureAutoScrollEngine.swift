//
//  ScrollingCaptureAutoScrollEngine.swift
//  Snapzy
//
//  Accessibility-guided auto-scroll driver for scrolling capture sessions.
//

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

final class ScrollingCaptureAutoScrollEngine {
  enum PreparationOutcome {
    case ready(description: String)
    case unavailablePermission(description: String)
    case noScrollableTarget(description: String)
  }

  enum StepOutcome {
    case scrolled(estimatedPoints: CGFloat, boundaryReached: Bool)
    case blocked(description: String)
    case reachedBoundary(description: String)
    case failed(description: String)
  }

  private struct Candidate {
    let processID: pid_t
    let application: AXUIElement
    let window: AXUIElement?
    let container: AXUIElement
    let verticalScrollBar: AXUIElement?
    let role: String
    let overlapRatio: CGFloat
    let centerDistance: CGFloat
    let depth: Int
    let applicationName: String
    let score: CGFloat
  }

  private struct Target {
    let processID: pid_t
    let application: AXUIElement
    let window: AXUIElement?
    let container: AXUIElement
    let verticalScrollBar: AXUIElement?
    let applicationName: String
    let anchorPoint: CGPoint
  }

  private struct ScrollBarState {
    let value: Double
    let minValue: Double
    let maxValue: Double

    var range: Double {
      max(maxValue - minValue, 0.0001)
    }

    var normalizedValue: Double {
      (value - minValue) / range
    }
  }

  private let selectionRect: CGRect
  private let selectionRectTopLeft: CGRect
  private let systemWideElement = AXUIElementCreateSystemWide()
  private let minimumStepPoints: CGFloat = 28
  private let maximumStepPoints: CGFloat = 260
  private let topLeftScreenMaxY: CGFloat

  private var target: Target?
  private var wheelDirectionSign: Int32 = 1
  private var hasCorrectedWheelDirection = false

  init(selectionRect: CGRect) {
    self.selectionRect = selectionRect
    self.topLeftScreenMaxY = Self.menuBarScreenMaxY()
    self.selectionRectTopLeft = Self.convertRectToTopLeft(
      selectionRect,
      menuBarScreenMaxY: self.topLeftScreenMaxY
    )
  }

  var targetDescription: String {
    guard let target else { return "Auto-scroll unavailable" }
    return "Ready for \(target.applicationName)"
  }

  func prepare() -> PreparationOutcome {
    guard AXIsProcessTrusted() else {
      return .unavailablePermission(description: "Auto-scroll needs Accessibility permission.")
    }

    guard let candidate = resolveBestCandidate() else {
      target = nil
      return .noScrollableTarget(
        description: "Couldn't detect a scrollable target. Snapzy will stay in manual mode."
      )
    }

    target = Target(
      processID: candidate.processID,
      application: candidate.application,
      window: candidate.window,
      container: candidate.container,
      verticalScrollBar: candidate.verticalScrollBar,
      applicationName: candidate.applicationName,
      anchorPoint: Self.convertPointToTopLeft(
        CGPoint(x: selectionRect.midX, y: selectionRect.midY),
        menuBarScreenMaxY: topLeftScreenMaxY
      )
    )
    wheelDirectionSign = 1
    hasCorrectedWheelDirection = false

    return .ready(description: "Ready for \(candidate.applicationName)")
  }

  func invalidate() {
    target = nil
    hasCorrectedWheelDirection = false
  }

  func flipWheelDirectionHint() {
    wheelDirectionSign *= -1
    hasCorrectedWheelDirection = true
  }

  func performStep(points: CGFloat) async -> StepOutcome {
    guard let target else {
      return .failed(description: "Auto-scroll is not ready for this session.")
    }

    activateTargetApplication(target)

    let clampedPoints = min(max(minimumStepPoints, points), maximumStepPoints)
    return await performEventStep(points: clampedPoints, target: target, allowDirectionCorrection: true)
  }

  private func performEventStep(
    points: CGFloat,
    target: Target,
    allowDirectionCorrection: Bool
  ) async -> StepOutcome {
    let previousState = verticalScrollState(of: target.verticalScrollBar)

    guard let event = CGEvent(
      scrollWheelEvent2Source: nil,
      units: .pixel,
      wheelCount: 1,
      wheel1: Int32(round(CGFloat(wheelDirectionSign) * points)),
      wheel2: 0,
      wheel3: 0
    ) else {
      return .failed(description: "Snapzy couldn't create an auto-scroll event.")
    }

    event.location = target.anchorPoint
    event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
    event.postToPid(target.processID)

    try? await Task.sleep(nanoseconds: 55_000_000)

    guard let previousState else {
      return .scrolled(estimatedPoints: points, boundaryReached: false)
    }

    guard let currentState = verticalScrollState(of: target.verticalScrollBar) else {
      return .scrolled(estimatedPoints: points, boundaryReached: false)
    }

    let delta = currentState.normalizedValue - previousState.normalizedValue
    let boundaryThreshold = 0.995

    if currentState.normalizedValue >= boundaryThreshold || previousState.normalizedValue >= boundaryThreshold {
      if abs(delta) < 0.0005 {
        return .reachedBoundary(description: "Auto-scroll reached the end of the visible content.")
      }
    }

    if abs(delta) < 0.0005 {
      if let directOutcome = await performDirectScrollBarStep(
        points: points,
        target: target,
        currentState: currentState,
        allowDirectionCorrection: allowDirectionCorrection
      ) {
        return directOutcome
      }

      if allowDirectionCorrection && !hasCorrectedWheelDirection {
        wheelDirectionSign *= -1
        hasCorrectedWheelDirection = true
        return await performEventStep(points: points, target: target, allowDirectionCorrection: false)
      }

      return .blocked(description: "Auto-scroll couldn't move that surface further.")
    }

    if delta < 0, allowDirectionCorrection && !hasCorrectedWheelDirection {
      wheelDirectionSign *= -1
      hasCorrectedWheelDirection = true
      return await performEventStep(points: points, target: target, allowDirectionCorrection: false)
    }

    return .scrolled(
      estimatedPoints: points,
      boundaryReached: currentState.normalizedValue >= boundaryThreshold
    )
  }

  private func performDirectScrollBarStep(
    points: CGFloat,
    target: Target,
    currentState: ScrollBarState,
    allowDirectionCorrection: Bool
  ) async -> StepOutcome? {
    guard let scrollBar = target.verticalScrollBar else { return nil }
    guard isAttributeSettable(kAXValueAttribute as String, of: scrollBar) else { return nil }

    let containerHeight = frame(of: target.container)?.height ?? selectionRectTopLeft.height
    let normalizedStep = Double(
      min(max(points / max(containerHeight * 0.9, 1), 0.035), 0.32)
    )

    let proposedValue = clamp(
      currentState.value + Double(wheelDirectionSign) * normalizedStep * currentState.range,
      lowerBound: currentState.minValue,
      upperBound: currentState.maxValue
    )

    if abs(proposedValue - currentState.value) < 0.0005 {
      return .reachedBoundary(description: "Auto-scroll reached the end of the visible content.")
    }

    guard setNumericAttribute(kAXValueAttribute as String, value: proposedValue, of: scrollBar) else {
      return nil
    }

    try? await Task.sleep(nanoseconds: 45_000_000)

    guard let updatedState = verticalScrollState(of: target.verticalScrollBar) else {
      return .scrolled(estimatedPoints: points, boundaryReached: false)
    }

    let delta = updatedState.normalizedValue - currentState.normalizedValue
    if abs(delta) < 0.0005 {
      if allowDirectionCorrection && !hasCorrectedWheelDirection {
        wheelDirectionSign *= -1
        hasCorrectedWheelDirection = true
        return await performDirectScrollBarStep(
          points: points,
          target: target,
          currentState: currentState,
          allowDirectionCorrection: false
        )
      }

      return .blocked(description: "Auto-scroll couldn't move that surface further.")
    }

    return .scrolled(
      estimatedPoints: points,
      boundaryReached: updatedState.normalizedValue >= 0.995
    )
  }

  private func resolveBestCandidate() -> Candidate? {
    var bestCandidate: Candidate?

    for samplePoint in samplePoints() {
      guard let element = copyElement(at: samplePoint) else { continue }

      for (depth, ancestor) in ancestorChain(startingAt: element).enumerated() {
        guard let candidate = makeCandidate(from: ancestor, depth: depth) else { continue }
        if candidate.score > (bestCandidate?.score ?? -.greatestFiniteMagnitude) {
          bestCandidate = candidate
        }
      }
    }

    return bestCandidate
  }

  private func makeCandidate(from element: AXUIElement, depth: Int) -> Candidate? {
    var processID: pid_t = 0
    guard AXUIElementGetPid(element, &processID) == .success, processID != 0 else { return nil }

    let role = stringAttribute(kAXRoleAttribute as String, of: element) ?? ""
    let verticalScrollBar =
      uiElementAttribute(kAXVerticalScrollBarAttribute as String, of: element)
      ?? findVerticalScrollBarInContents(of: element)

    let isLikelyScrollable = verticalScrollBar != nil || likelyScrollableRoles.contains(role)
    guard isLikelyScrollable else { return nil }

    guard let frame = frame(of: element) else { return nil }
    let overlapRect = selectionRectTopLeft.intersection(frame)
    guard !overlapRect.isNull, overlapRect.width > 0, overlapRect.height > 0 else { return nil }

    let selectionArea = max(selectionRectTopLeft.width * selectionRectTopLeft.height, 1)
    let overlapArea = overlapRect.width * overlapRect.height
    let overlapRatio = overlapArea / selectionArea
    guard overlapRatio > 0.24 || verticalScrollBar != nil else { return nil }

    let centerDistance = hypot(
      frame.midX - selectionRectTopLeft.midX,
      frame.midY - selectionRectTopLeft.midY
    )

    let application = AXUIElementCreateApplication(processID)
    let applicationName = NSRunningApplication(processIdentifier: processID)?.localizedName ?? "the target app"
    let window = windowAncestor(startingAt: element)
    var score = overlapRatio * 100
    score += verticalScrollBar != nil ? 18 : 0
    score += role == (kAXScrollAreaRole as String) ? 16 : 0
    score += likelyScrollableRoles.contains(role) ? 8 : 0
    score -= centerDistance / 30
    score -= CGFloat(depth) * 2.2

    return Candidate(
      processID: processID,
      application: application,
      window: window,
      container: element,
      verticalScrollBar: verticalScrollBar,
      role: role,
      overlapRatio: overlapRatio,
      centerDistance: centerDistance,
      depth: depth,
      applicationName: applicationName,
      score: score
    )
  }

  private func samplePoints() -> [CGPoint] {
    let insetRect = selectionRect.insetBy(
      dx: min(max(18, selectionRect.width * 0.18), selectionRect.width * 0.32),
      dy: min(max(18, selectionRect.height * 0.18), selectionRect.height * 0.32)
    )

    let xs = [insetRect.minX, insetRect.midX, insetRect.maxX]
    let ys = [insetRect.minY, insetRect.midY, insetRect.maxY]
    var points: [CGPoint] = []
    points.reserveCapacity(xs.count * ys.count)

    for y in ys {
      for x in xs {
        points.append(Self.convertPointToTopLeft(
          CGPoint(x: x, y: y),
          menuBarScreenMaxY: topLeftScreenMaxY
        ))
      }
    }

    return points
  }

  private func copyElement(at topLeftPoint: CGPoint) -> AXUIElement? {
    var element: AXUIElement?
    let result = AXUIElementCopyElementAtPosition(
      systemWideElement,
      Float(topLeftPoint.x),
      Float(topLeftPoint.y),
      &element
    )
    guard result == .success else { return nil }
    return element
  }

  private func ancestorChain(startingAt element: AXUIElement) -> [AXUIElement] {
    var chain: [AXUIElement] = []
    var current: AXUIElement? = element
    var visitedRoles = 0

    while visitedRoles < 14, let currentElement = current {
      chain.append(currentElement)
      current = uiElementAttribute(kAXParentAttribute as String, of: currentElement)
      visitedRoles += 1
    }

    return chain
  }

  private func windowAncestor(startingAt element: AXUIElement) -> AXUIElement? {
    for ancestor in ancestorChain(startingAt: element) {
      if stringAttribute(kAXRoleAttribute as String, of: ancestor) == (kAXWindowRole as String) {
        return ancestor
      }
    }

    return nil
  }

  private func findVerticalScrollBarInContents(of element: AXUIElement) -> AXUIElement? {
    guard let contents = uiElementArrayAttribute(kAXContentsAttribute as String, of: element) else {
      return nil
    }

    for content in contents.prefix(4) {
      if let scrollBar = uiElementAttribute(kAXVerticalScrollBarAttribute as String, of: content) {
        return scrollBar
      }
    }

    return nil
  }

  private func verticalScrollState(of scrollBar: AXUIElement?) -> ScrollBarState? {
    guard let scrollBar else { return nil }
    guard let value = numericAttribute(kAXValueAttribute as String, of: scrollBar) else {
      return nil
    }

    let minValue = numericAttribute(kAXMinValueAttribute as String, of: scrollBar) ?? 0
    let maxValue = numericAttribute(kAXMaxValueAttribute as String, of: scrollBar) ?? 1
    let adjustedMaxValue = max(maxValue, minValue + 0.0001)

    return ScrollBarState(
      value: value,
      minValue: minValue,
      maxValue: adjustedMaxValue
    )
  }

  private func activateTargetApplication(_ target: Target) {
    if let runningApplication = NSRunningApplication(processIdentifier: target.processID) {
      _ = runningApplication.activate()
    } else if let window = target.window {
      _ = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
    }
  }

  private func frame(of element: AXUIElement) -> CGRect? {
    guard
      let positionValue = axValueAttribute(kAXPositionAttribute as String, of: element),
      let sizeValue = axValueAttribute(kAXSizeAttribute as String, of: element)
    else {
      return nil
    }

    var position = CGPoint.zero
    var size = CGSize.zero
    guard AXValueGetValue(positionValue, .cgPoint, &position) else { return nil }
    guard AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }

    return CGRect(origin: position, size: size)
  }

  private func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }

    return value as? String
  }

  private func numericAttribute(_ attribute: String, of element: AXUIElement) -> Double? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }

    if let number = value as? NSNumber {
      return number.doubleValue
    }

    return nil
  }

  private func setNumericAttribute(
    _ attribute: String,
    value: Double,
    of element: AXUIElement
  ) -> Bool {
    let number = NSNumber(value: value)
    return AXUIElementSetAttributeValue(
      element,
      attribute as CFString,
      number as CFTypeRef
    ) == .success
  }

  private func isAttributeSettable(_ attribute: String, of element: AXUIElement) -> Bool {
    var isSettable = DarwinBoolean(false)
    guard AXUIElementIsAttributeSettable(
      element,
      attribute as CFString,
      &isSettable
    ) == .success else {
      return false
    }

    return isSettable.boolValue
  }

  private func uiElementAttribute(_ attribute: String, of element: AXUIElement) -> AXUIElement? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }

    return value as! AXUIElement?
  }

  private func uiElementArrayAttribute(_ attribute: String, of element: AXUIElement) -> [AXUIElement]? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }

    return value as? [AXUIElement]
  }

  private func axValueAttribute(_ attribute: String, of element: AXUIElement) -> AXValue? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }

    return (value as! AXValue)
  }

  private static func menuBarScreenMaxY() -> CGFloat {
    let zeroOriginScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero })
    return zeroOriginScreen?.frame.maxY
      ?? NSScreen.screens.map(\.frame.maxY).max()
      ?? 0
  }

  private static func convertPointToTopLeft(
    _ point: CGPoint,
    menuBarScreenMaxY: CGFloat
  ) -> CGPoint {
    CGPoint(x: point.x, y: menuBarScreenMaxY - point.y)
  }

  private static func convertRectToTopLeft(
    _ rect: CGRect,
    menuBarScreenMaxY: CGFloat
  ) -> CGRect {
    CGRect(
      x: rect.minX,
      y: menuBarScreenMaxY - rect.maxY,
      width: rect.width,
      height: rect.height
    )
  }

  private func clamp(_ value: Double, lowerBound: Double, upperBound: Double) -> Double {
    min(max(lowerBound, value), upperBound)
  }

  private let likelyScrollableRoles: Set<String> = [
    kAXScrollAreaRole as String,
    kAXTextAreaRole as String,
    kAXListRole as String,
    kAXOutlineRole as String,
    kAXTableRole as String,
    kAXBrowserRole as String,
    "AXWebArea",
    "AXCollectionView",
    "AXDocument"
  ]
}
