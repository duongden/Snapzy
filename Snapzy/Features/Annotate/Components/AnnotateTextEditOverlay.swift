//
//  TextEditOverlay.swift
//  Snapzy
//
//  SwiftUI overlay for inline text annotation editing
//

import AppKit
import SwiftUI

/// Overlay for editing text annotations inline on the canvas
struct TextEditOverlay: View {
  @ObservedObject var state: AnnotateState
  let scale: CGFloat
  let canvasBounds: CGRect

  @State private var editingText: String = ""
  @State private var textHeight: CGFloat = 28

  // MARK: - Constants

  private let minTextFieldWidth: CGFloat = AnnotateTextLayout.minWidth
  /// TextEditor has internal horizontal insets (~5pt each side) that reduce
  /// the actual text rendering width compared to the frame width.
  /// We must subtract these when measuring to predict wrap points correctly.
  private let textEditorHorizontalInsets: CGFloat = 10
  /// Extra vertical padding for TextEditor's internal chrome (top/bottom insets)
  private let textEditorVerticalPadding: CGFloat = 4

  var body: some View {
    GeometryReader { _ in
      if let editingId = state.editingTextAnnotationId,
         let annotation = state.annotations.first(where: { $0.id == editingId }),
         case .text(let currentText) = annotation.type {

        let displayBounds = calculateDisplayBounds(annotation.bounds)
        let displayFont = AnnotateTextLayout.displayFont(
          size: annotation.properties.fontSize,
          fontName: annotation.properties.fontName,
          scale: scale
        )
        let fieldWidth = max(displayBounds.width, minTextFieldWidth)
        // Use measured textHeight with the inline editor's text insets
        // plus vertical padding for its editing chrome.
        let fieldHeight = max(textHeight + textEditorVerticalPadding, displayBounds.height)

        InlineAnnotationTextEditor(
          text: $editingText,
          font: displayFont,
          textColor: NSColor(annotation.properties.strokeColor),
          onCommit: { commitEdit(id: editingId) },
          onCancel: cancelEdit,
          onUndo: { state.undo() },
          onRedo: { state.redo() }
        )
          .frame(
            width: fieldWidth,
            height: fieldHeight,
            alignment: .topLeading
          )
          .background(Color.clear)
          .position(
            x: displayBounds.minX + fieldWidth / 2,
            y: displayBounds.minY + fieldHeight / 2
          )
          .onAppear {
            editingText = currentText
            recalculateHeight(text: currentText, font: displayFont, width: fieldWidth)
          }
          .onChange(of: editingText) { newValue in
            recalculateHeight(text: newValue, font: displayFont, width: fieldWidth)
            // Live-update annotation text and bounds
            if let editingId = state.editingTextAnnotationId {
              state.updateAnnotationText(id: editingId, text: newValue)
            }
          }
      }
    }
  }

  /// Recalculate editor height based on wrapped text content.
  /// We subtract the inline editor's horizontal insets from the measurement
  /// width so that wrap predictions match the actual narrower rendering area.
  private func recalculateHeight(text: String, font: NSFont, width: CGFloat) {
    let effectiveWidth = max(width - textEditorHorizontalInsets, minTextFieldWidth)
    textHeight = AnnotateTextLayout.measuredHeight(
      text: text,
      font: font,
      constrainedWidth: effectiveWidth
    )
  }

  /// Convert image bounds to display coordinates
  /// The parent view supplies a frame that matches the active canvas bounds.
  /// Crop offset is handled by this conversion, so we only:
  /// 1. Scale the bounds
  /// 2. Flip Y axis (AppKit bottom-left origin → SwiftUI top-left origin)
  private func calculateDisplayBounds(_ imageBounds: CGRect) -> CGRect {
    // Scale the bounds
    let scaledX = (imageBounds.origin.x - canvasBounds.minX) * scale
    let scaledWidth = imageBounds.width * scale
    let scaledHeight = imageBounds.height * scale

    // Flip Y axis: AppKit uses bottom-left origin, SwiftUI uses top-left
    // In AppKit: y=0 is bottom, y increases upward
    // In SwiftUI: y=0 is top, y increases downward
    let flippedY = (canvasBounds.maxY - imageBounds.origin.y - imageBounds.height) * scale

    return CGRect(
      x: scaledX,
      y: flippedY,
      width: scaledWidth,
      height: scaledHeight
    )
  }

  private func commitEdit(id: UUID) {
    if state.editingTextAnnotationId == id {
      state.updateAnnotationText(id: id, text: editingText)
      state.commitTextEditing()
    }
  }

  private func cancelEdit() {
    // If it was a new annotation with empty text, delete it
    if let editingId = state.editingTextAnnotationId,
       let annotation = state.annotations.first(where: { $0.id == editingId }),
       case .text(let text) = annotation.type,
       text.isEmpty {
      state.annotations.removeAll { $0.id == editingId }
      state.selectedAnnotationId = nil
    }
    state.finishTextEditing()
  }
}

private struct InlineAnnotationTextEditor: NSViewRepresentable {
  @Binding var text: String
  let font: NSFont
  let textColor: NSColor
  let onCommit: () -> Void
  let onCancel: () -> Void
  let onUndo: () -> Void
  let onRedo: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  func makeNSView(context: Context) -> UndoIsolatedTextView {
    let textView = UndoIsolatedTextView()
    textView.delegate = context.coordinator
    textView.string = text
    textView.onCommit = onCommit
    textView.onCancel = onCancel
    textView.onUndo = onUndo
    textView.onRedo = onRedo

    textView.drawsBackground = false
    textView.backgroundColor = .clear
    textView.isRichText = false
    textView.importsGraphics = false
    textView.allowsUndo = false
    textView.isEditable = true
    textView.isSelectable = true
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = true
    textView.autoresizingMask = [.width]
    textView.textContainerInset = NSSize(width: 5, height: 0)
    textView.textContainer?.widthTracksTextView = true
    textView.textContainer?.heightTracksTextView = false
    textView.textContainer?.lineFragmentPadding = 0
    textView.font = font
    textView.textColor = textColor

    DispatchQueue.main.async {
      textView.window?.makeFirstResponder(textView)
    }

    return textView
  }

  func updateNSView(_ textView: UndoIsolatedTextView, context: Context) {
    context.coordinator.text = $text
    textView.onCommit = onCommit
    textView.onCancel = onCancel
    textView.onUndo = onUndo
    textView.onRedo = onRedo

    if textView.string != text {
      context.coordinator.isApplyingExternalText = true
      textView.string = text
      context.coordinator.isApplyingExternalText = false
    }
    if textView.font != font {
      textView.font = font
    }
    if textView.textColor != textColor {
      textView.textColor = textColor
    }
  }

  static func dismantleNSView(_ textView: UndoIsolatedTextView, coordinator: Coordinator) {
    textView.onCommit = nil
    textView.onCancel = nil
    textView.onUndo = nil
    textView.onRedo = nil
    textView.delegate = nil
    textView.undoManager?.removeAllActions()
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var text: Binding<String>
    var isApplyingExternalText = false

    init(text: Binding<String>) {
      self.text = text
    }

    func textDidChange(_ notification: Notification) {
      guard !isApplyingExternalText,
            let textView = notification.object as? NSTextView else { return }
      text.wrappedValue = textView.string
    }

    func textDidEndEditing(_ notification: Notification) {
      guard let textView = notification.object as? UndoIsolatedTextView else { return }
      textView.onCommit?()
    }
  }

  final class UndoIsolatedTextView: NSTextView {
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?

    override var undoManager: UndoManager? { nil }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
      guard event.type == .keyDown else {
        return super.performKeyEquivalent(with: event)
      }

      let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
      if event.keyCode == 6 && flags == .command {
        onUndo?()
        return true
      }
      if event.keyCode == 6 && flags == [.command, .shift] {
        onRedo?()
        return true
      }

      return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
      if event.keyCode == 53 {
        onCancel?()
        return
      }
      super.keyDown(with: event)
    }
  }
}
