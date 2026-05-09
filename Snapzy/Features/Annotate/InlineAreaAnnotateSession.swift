//
//  InlineAreaAnnotateSession.swift
//  Snapzy
//
//  Coordinates direct area screenshot annotation before post-capture routing.
//

import AppKit
import Combine
import CoreGraphics
import Foundation

@MainActor
final class InlineAreaAnnotateSession: ObservableObject {
  enum Phase {
    case selecting
    case annotating
  }

  @Published var phase: Phase = .selecting
  @Published var selectionRect: CGRect?
  @Published var isUploading = false
  @Published var uploadProgress: Double = 0
  @Published var showCloudNotConfiguredAlert = false
  @Published var uploadErrorMessage: String?
  @Published var isMoveModifierActive = false

  let state = AnnotateState()
  let screenFrame: CGRect
  let backdropImage: NSImage

  private let displayID: CGDirectDisplayID
  private let frozenSession: FrozenAreaCaptureSession
  private let saveDirectory: URL
  private let outputFormat: ImageFormat
  private let onComplete: (CaptureResult) -> Void
  private weak var window: NSWindow?
  private var localKeyMonitor: Any?
  private var globalKeyMonitor: Any?
  private var stateChangeCancellable: AnyCancellable?
  private var didComplete = false

  init(
    displayID: CGDirectDisplayID,
    screenFrame: CGRect,
    backdrop: AreaSelectionBackdrop,
    frozenSession: FrozenAreaCaptureSession,
    saveDirectory: URL,
    outputFormat: ImageFormat,
    onComplete: @escaping (CaptureResult) -> Void
  ) {
    self.displayID = displayID
    self.screenFrame = screenFrame
    self.backdropImage = NSImage(cgImage: backdrop.image, size: screenFrame.size)
    self.frozenSession = frozenSession
    self.saveDirectory = saveDirectory
    self.outputFormat = outputFormat
    self.onComplete = onComplete
    self.stateChangeCancellable = state.objectWillChange.sink { [weak self] _ in
      Task { @MainActor in
        self?.objectWillChange.send()
      }
    }
  }

  func attach(window: NSWindow) {
    self.window = window
    installKeyMonitors()
  }

  func beginAnnotating(with localRect: CGRect) {
    let clampedRect = clampedSelectionRect(localRect.standardized)
    guard clampedRect.width > 5, clampedRect.height > 5,
          let image = cropImage(for: clampedRect) else { return }

    selectionRect = clampedRect
    state.loadImage(image, url: nil)
    state.selectedTool = .selection
    phase = .annotating
  }

  func moveSelection(to localRect: CGRect, refreshImage: Bool) {
    let clampedRect = clampedSelectionRect(localRect.standardized)
    selectionRect = clampedRect
    guard refreshImage, let image = cropImage(for: clampedRect) else { return }
    state.replaceSourceImagePreservingAnnotations(image)
  }

  func resizeSelection(to localRect: CGRect, previousRect: CGRect) {
    let clampedRect = clampedSelectionRect(localRect.standardized)
    guard clampedRect.width > 5,
          clampedRect.height > 5,
          let image = cropImage(for: clampedRect) else { return }

    let standardizedPreviousRect = previousRect.standardized
    let annotationOffset = CGPoint(
      x: standardizedPreviousRect.minX - clampedRect.minX,
      y: standardizedPreviousRect.minY - clampedRect.minY
    )

    selectionRect = clampedRect
    state.replaceSourceImagePreservingAnnotations(image, annotationOffset: annotationOffset)
  }

  func clampedSelectionPreview(for localRect: CGRect) -> CGRect {
    clampedSelectionRect(localRect.standardized)
  }

  func handleKeyEvent(_ event: NSEvent) -> Bool {
    guard phase == .annotating else {
      isMoveModifierActive = false
      if event.type == .keyDown, event.keyCode == 53 {
        cancel()
        return true
      }
      return false
    }

    if isCommandSaveShortcut(event) {
      Task { await finish() }
      return true
    }

    if window?.firstResponder is NSTextView {
      if event.keyCode == 49 {
        isMoveModifierActive = false
      }
      return false
    }

    if event.keyCode == 49 {
      isMoveModifierActive = event.type == .keyDown
      return true
    }

    guard event.type == .keyDown else { return false }

    switch event.keyCode {
    case 36, 76:
      Task { await finish() }
      return true
    case 53:
      cancel()
      return true
    default:
      return false
    }
  }

  func cancel() {
    complete(.failure(.cancelled))
  }

  func windowDidClose() {
    complete(.failure(.cancelled), closeWindow: false)
  }

  func finish() async {
    guard phase == .annotating else { return }
    if let selectionRect, let image = cropImage(for: selectionRect) {
      state.replaceSourceImagePreservingAnnotations(image)
    }

    guard let renderedImage = AnnotateExporter.renderFinalImage(state: state),
          let cgImage = AnnotateExporter.bestCGImage(from: renderedImage) else {
      complete(.failure(.captureFailed(L10n.ScreenCapture.failedToCropCapturedImage)))
      return
    }

    let result = await ScreenCaptureManager.shared.saveProcessedImage(
      cgImage,
      to: saveDirectory,
      format: outputFormat,
      scaleFactor: Self.imageScale(renderedImage)
    )

    if case .success = result {
      SoundManager.playScreenshotCapture()
    }
    complete(result)
  }

  func copyCurrentImage() {
    guard let image = AnnotateExporter.renderFinalImage(state: state) else { return }
    ClipboardHelper.copyImage(image)
    SoundManager.play("Pop")
  }

  func shareCurrentImage(from view: NSView) {
    guard let image = AnnotateExporter.renderFinalImage(state: state) else { return }
    NSSharingServicePicker(items: [image]).show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
  }

  func uploadCurrentImage() {
    guard CloudManager.shared.isConfigured else {
      showCloudNotConfiguredAlert = true
      return
    }
    guard !isUploading, let image = AnnotateExporter.renderFinalImage(state: state) else { return }

    isUploading = true
    uploadProgress = 0.15
    uploadErrorMessage = nil

    Task {
      var scratchURL: URL?
      defer {
        if let scratchURL {
          try? FileManager.default.removeItem(at: scratchURL)
        }
      }

      do {
        let url = try writeUploadScratchFile(image)
        scratchURL = url
        uploadProgress = 0.75
        let result = try await CloudManager.shared.upload(fileURL: url)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.publicURL.absoluteString, forType: .string)
        uploadProgress = 1
        isUploading = false
        SoundManager.play("Pop")
      } catch {
        isUploading = false
        uploadProgress = 0
        uploadErrorMessage = error.localizedDescription
        DiagnosticLogger.shared.logError(.cloud, error, "Inline area annotate upload failed")
      }
    }
  }

  private func cropImage(for localRect: CGRect) -> NSImage? {
    do {
      let result = try frozenSession.cropImage(for: AreaSelectionResult(
        target: .rect(screenRect(for: localRect)),
        displayID: displayID,
        mode: .screenshot
      ))
      let size = CGSize(
        width: CGFloat(result.image.width) / max(result.scaleFactor, 1),
        height: CGFloat(result.image.height) / max(result.scaleFactor, 1)
      )
      return NSImage(cgImage: result.image, size: size)
    } catch {
      DiagnosticLogger.shared.logError(.capture, error, "Inline area annotate crop failed")
      return nil
    }
  }

  private func screenRect(for localRect: CGRect) -> CGRect {
    CGRect(
      x: screenFrame.minX + localRect.minX,
      y: screenFrame.maxY - localRect.maxY,
      width: localRect.width,
      height: localRect.height
    )
  }

  private func clampedSelectionRect(_ rect: CGRect) -> CGRect {
    var result = rect
    result.size.width = min(max(result.width, 1), screenFrame.width)
    result.size.height = min(max(result.height, 1), screenFrame.height)
    result.origin.x = min(max(result.minX, 0), max(0, screenFrame.width - result.width))
    result.origin.y = min(max(result.minY, 0), max(0, screenFrame.height - result.height))
    return result
  }

  private func writeUploadScratchFile(_ image: NSImage) throws -> URL {
    let directory = TempCaptureManager.shared.tempCaptureDirectory
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = CaptureOutputNaming.makeUniqueFileURL(
      in: directory,
      baseName: "Snapzy_Inline_Annotate_\(Int(Date().timeIntervalSince1970))",
      fileExtension: outputFormat.fileExtension
    )
    guard let data = AnnotateExporter.imageData(from: image, for: outputFormat.fileExtension) else {
      throw CaptureError.saveFailed(L10n.ScreenCapture.failedToCropCapturedImage)
    }
    try data.write(to: url, options: .atomic)
    return url
  }

  private func installKeyMonitors() {
    localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
      guard self?.handleKeyEvent(event) == true else { return event }
      return nil
    }
    globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
      Task { @MainActor in
        _ = self?.handleKeyEvent(event)
      }
    }
  }

  private func removeKeyMonitors() {
    if let localKeyMonitor {
      NSEvent.removeMonitor(localKeyMonitor)
      self.localKeyMonitor = nil
    }
    if let globalKeyMonitor {
      NSEvent.removeMonitor(globalKeyMonitor)
      self.globalKeyMonitor = nil
    }
  }

  private func complete(_ result: CaptureResult, closeWindow: Bool = true) {
    guard !didComplete else { return }
    didComplete = true
    isMoveModifierActive = false
    removeKeyMonitors()
    frozenSession.invalidate()
    if closeWindow {
      window?.close()
    }
    onComplete(result)
  }

  private static func imageScale(_ image: NSImage) -> CGFloat {
    guard let rep = image.representations.first as? NSBitmapImageRep,
          image.size.width > 0,
          image.size.height > 0 else { return 1 }
    return max(CGFloat(rep.pixelsWide) / image.size.width, CGFloat(rep.pixelsHigh) / image.size.height, 1)
  }

  private func isCommandSaveShortcut(_ event: NSEvent) -> Bool {
    guard event.type == .keyDown else { return false }
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard flags.contains(.command),
          !flags.contains(.control),
          !flags.contains(.option) else { return false }
    return event.keyCode == 1 || event.charactersIgnoringModifiers?.lowercased() == "s"
  }
}
