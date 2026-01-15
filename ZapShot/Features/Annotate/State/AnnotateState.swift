//
//  AnnotateState.swift
//  ZapShot
//
//  Central state management for annotation window
//

import AppKit
import Combine
import SwiftUI

/// Central state for annotation window
@MainActor
final class AnnotateState: ObservableObject {

  // MARK: - Source Image

  let sourceImage: NSImage
  let sourceURL: URL

  // MARK: - Tool State

  @Published var selectedTool: AnnotationToolType = .selection
  @Published var strokeWidth: CGFloat = 3
  @Published var strokeColor: Color = .red
  @Published var fillColor: Color = .clear

  // MARK: - UI State

  @Published var showSidebar: Bool = true
  @Published var zoomLevel: CGFloat = 1.0

  // MARK: - Background Settings

  @Published var backgroundStyle: BackgroundStyle = .none
  @Published var padding: CGFloat = 40
  @Published var inset: CGFloat = 0
  @Published var autoBalance: Bool = true
  @Published var shadowIntensity: CGFloat = 0.3
  @Published var cornerRadius: CGFloat = 8
  @Published var imageAlignment: ImageAlignment = .center
  @Published var aspectRatio: AspectRatioOption = .auto

  // MARK: - Annotations

  @Published var annotations: [AnnotationItem] = []
  @Published var selectedAnnotationId: UUID?

  // MARK: - Counter Tool State

  @Published var counterValue: Int = 1

  // MARK: - Undo/Redo

  @Published var canUndo: Bool = false
  @Published var canRedo: Bool = false

  private var undoStack: [[AnnotationItem]] = []
  private var redoStack: [[AnnotationItem]] = []

  init(image: NSImage, url: URL) {
    self.sourceImage = image
    self.sourceURL = url
  }

  // MARK: - Undo/Redo Methods

  func saveState() {
    undoStack.append(annotations)
    redoStack.removeAll()
    canUndo = true
    canRedo = false
  }

  func undo() {
    guard let previous = undoStack.popLast() else { return }
    redoStack.append(annotations)
    annotations = previous
    canUndo = !undoStack.isEmpty
    canRedo = true
  }

  func redo() {
    guard let next = redoStack.popLast() else { return }
    undoStack.append(annotations)
    annotations = next
    canUndo = true
    canRedo = !redoStack.isEmpty
  }

  // MARK: - Counter

  func nextCounterValue() -> Int {
    let value = counterValue
    counterValue += 1
    return value
  }

  func resetCounter() {
    counterValue = 1
  }
}
