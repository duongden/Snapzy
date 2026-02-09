//
//  RecordingAnnotationToolbarWindow.swift
//  Snapzy
//
//  Floating NSWindow for annotation tools during recording
//  Draggable with auto-snap to corners, auto horizontal/vertical layout
//  Uses manual drag tracking loop for full control over placeholder + snap
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class RecordingAnnotationToolbarWindow: NSWindow {

  private let annotationState: RecordingAnnotationState
  private var hostingView: NSHostingView<AnyView>?
  private var effectView: NSVisualEffectView?
  private var direction: AnnotationToolbarDirection = .horizontal
  private var enabledCancellable: AnyCancellable?
  private let snapHelper = AnnotationToolbarSnapHelper()
  private var cachedAlternateSize: CGSize?
  private var cachedAlternateDirection: AnnotationToolbarDirection?

  init(annotationState: RecordingAnnotationState) {
    self.annotationState = annotationState

    super.init(
      contentRect: .zero,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    configureWindow()
    rebuildContent()
    positionDefault()
    observeToggle()
  }

  // MARK: - Configuration

  private func configureWindow() {
    isOpaque = false
    backgroundColor = .clear
    level = .popUpMenu
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    hasShadow = false
    isReleasedWhenClosed = false
    appearance = ThemeManager.shared.nsAppearance
    isMovableByWindowBackground = false
    acceptsMouseMovedEvents = true
  }

  override func sendEvent(_ event: NSEvent) {
    if event.type == .leftMouseDown && !isKeyWindow {
      makeKeyAndOrderFront(nil)
    }
    super.sendEvent(event)
  }

  private func observeToggle() {
    enabledCancellable = annotationState.$isAnnotationEnabled
      .receive(on: RunLoop.main)
      .sink { [weak self] enabled in
        if enabled {
          self?.orderFrontRegardless()
        } else {
          self?.orderOut(nil)
        }
      }
  }

  // MARK: - Content

  private func rebuildContent() {
    let result = AnnotationToolbarContentBuilder.build(
      state: annotationState,
      direction: direction
    )
    contentView = result.effectView
    hostingView = result.hostingView
    effectView = result.effectView
    setContentSize(result.fittingSize)
  }

  // MARK: - Positioning

  private func positionDefault() {
    guard let screen = NSScreen.main else { return }
    let sf = screen.visibleFrame
    let size = self.frame.size
    let x = sf.midX - size.width / 2
    let y = sf.minY + 60
    setFrameOrigin(CGPoint(x: x, y: y))
  }

  // MARK: - Manual Drag + Snap

  override func mouseDown(with event: NSEvent) {
    let startMouse = NSEvent.mouseLocation
    let startOrigin = frame.origin

    var lastSnap = currentSnap()
    snapHelper.showPlaceholder(snap: lastSnap, size: sizeForDirection(lastSnap.direction))

    var dragged = false
    while true {
      guard let nextEvent = self.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
      if nextEvent.type == .leftMouseUp { break }

      let currentMouse = NSEvent.mouseLocation
      let newOrigin = CGPoint(
        x: startOrigin.x + (currentMouse.x - startMouse.x),
        y: startOrigin.y + (currentMouse.y - startMouse.y)
      )
      setFrameOrigin(newOrigin)
      dragged = true

      lastSnap = currentSnap()
      snapHelper.updatePlaceholder(snap: lastSnap, size: sizeForDirection(lastSnap.direction))
    }

    snapHelper.hidePlaceholder()

    if dragged {
      snapToPosition(lastSnap)
    }
  }

  // MARK: - Snap

  private func currentSnap() -> AnnotationToolbarSnapResult {
    snapHelper.computeSnap(for: frame, currentDirection: direction) { [self] dir in
      sizeForDirection(dir)
    }
  }

  private func sizeForDirection(_ dir: AnnotationToolbarDirection) -> CGSize {
    if dir == direction { return frame.size }

    if cachedAlternateDirection == dir, let cached = cachedAlternateSize {
      return cached
    }

    let size = AnnotationToolbarContentBuilder.fittingSize(
      state: annotationState,
      direction: dir
    )
    cachedAlternateSize = size
    cachedAlternateDirection = dir
    return size
  }

  private func snapToPosition(_ snap: AnnotationToolbarSnapResult) {
    let needsRebuild = snap.direction != direction
    let targetSize = sizeForDirection(snap.direction)
    let targetFrame = CGRect(origin: snap.origin, size: targetSize)

    if needsRebuild {
      direction = snap.direction
      cachedAlternateSize = nil
      cachedAlternateDirection = nil
    }

    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = 0.25
      ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      self.animator().setFrame(targetFrame, display: true)
    }, completionHandler: { [weak self] in
      guard let self, needsRebuild else { return }
      self.rebuildContent()
    })
  }

  override var canBecomeKey: Bool { true }
}
