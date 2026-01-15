//
//  CanvasDrawingView.swift
//  ZapShot
//
//  NSViewRepresentable wrapper for the drawing canvas
//

import AppKit
import SwiftUI

/// NSViewRepresentable wrapper for the drawing canvas
struct CanvasDrawingView: NSViewRepresentable {
  @ObservedObject var state: AnnotateState

  func makeNSView(context: Context) -> DrawingCanvasNSView {
    let view = DrawingCanvasNSView(state: state)
    return view
  }

  func updateNSView(_ nsView: DrawingCanvasNSView, context: Context) {
    nsView.state = state
    nsView.needsDisplay = true
  }
}

/// NSView subclass handling mouse events and drawing
final class DrawingCanvasNSView: NSView {
  var state: AnnotateState
  private var currentPath: [CGPoint] = []
  private var isDrawing = false
  private var dragStart: CGPoint?

  init(state: AnnotateState) {
    self.state = state
    super.init(frame: .zero)
    setupView()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  // MARK: - Mouse Events

  override func mouseDown(with event: NSEvent) {
    let point = convert(event.locationInWindow, from: nil)
    dragStart = point
    isDrawing = true

    switch state.selectedTool {
    case .pencil, .highlighter:
      currentPath = [point]
    default:
      break
    }
  }

  override func mouseDragged(with event: NSEvent) {
    guard isDrawing else { return }
    let point = convert(event.locationInWindow, from: nil)

    switch state.selectedTool {
    case .pencil, .highlighter:
      currentPath.append(point)
      needsDisplay = true
    default:
      currentPath = [point]
      needsDisplay = true
    }
  }

  override func mouseUp(with event: NSEvent) {
    guard isDrawing, let start = dragStart else { return }
    let end = convert(event.locationInWindow, from: nil)

    Task { @MainActor in
      state.saveState()
      createAnnotation(from: start, to: end)
    }

    isDrawing = false
    dragStart = nil
    currentPath = []
    needsDisplay = true
  }

  // MARK: - Annotation Creation

  private func createAnnotation(from start: CGPoint, to end: CGPoint) {
    let item = AnnotationFactory.createAnnotation(
      tool: state.selectedTool,
      from: start,
      to: end,
      path: currentPath,
      state: state
    )
    if let item = item {
      state.annotations.append(item)
    }
  }

  // MARK: - Drawing

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    guard let context = NSGraphicsContext.current?.cgContext else { return }

    // Draw existing annotations
    let renderer = AnnotationRenderer(context: context)
    for annotation in state.annotations {
      renderer.draw(annotation)
    }

    // Draw current stroke if drawing
    if isDrawing, let start = dragStart {
      renderer.drawCurrentStroke(
        tool: state.selectedTool,
        start: start,
        currentPath: currentPath,
        strokeColor: state.strokeColor,
        strokeWidth: state.strokeWidth
      )
    }
  }
}
