//
//  HistoryWindowController.swift
//  Snapzy
//
//  Manages the capture history browser window lifecycle
//

import AppKit

extension Notification.Name {
  static let historyCopySelection = Notification.Name("historyCopySelection")
  static let historyActivateSelection = Notification.Name("historyActivateSelection")
  static let historyDeleteSelection = Notification.Name("historyDeleteSelection")
}

final class HistoryWindow: NSWindow {
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    guard event.type == .keyDown else {
      return super.performKeyEquivalent(with: event)
    }

    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

    if event.keyCode == 8 && flags == .command {
      if isTextInputActive {
        return super.performKeyEquivalent(with: event)
      }

      NotificationCenter.default.post(name: .historyCopySelection, object: self)
      return true
    }

    return super.performKeyEquivalent(with: event)
  }

  override func keyDown(with event: NSEvent) {
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

    if !isTextInputActive, flags.isEmpty, (event.keyCode == 51 || event.keyCode == 117) {
      NotificationCenter.default.post(name: .historyDeleteSelection, object: self)
      return
    }

    super.keyDown(with: event)
  }

  private var isTextInputActive: Bool {
    guard let responder = firstResponder else { return false }
    return responder is NSTextView || responder is NSTextField
  }
}

/// Manages the capture history browser window
@MainActor
final class HistoryWindowController {
  static let shared = HistoryWindowController()

  private init() {}

  func showWindow() {
    HistoryFloatingManager.shared.showExpanded()
    NSApp.activate(ignoringOtherApps: true)
  }

  func hideWindow() {
    HistoryFloatingManager.shared.hide()
  }

  func copyToClipboard(_ records: [CaptureHistoryRecord]) {
    let existingRecords = records.filter(\.fileExists)
    guard !existingRecords.isEmpty else { return }

    if existingRecords.count == 1, let record = existingRecords.first {
      switch record.captureType {
      case .screenshot, .gif:
        ClipboardHelper.copyImage(from: record.fileURL)
      case .video:
        ClipboardHelper.copyFileURLs([record.fileURL])
      }
    } else {
      ClipboardHelper.copyFileURLs(existingRecords.map(\.fileURL))
    }

    AppToastManager.shared.show(
      message: L10n.Common.copiedToClipboard,
      style: .success,
      duration: 1.6,
      variant: .compact
    )
  }

  func openItem(_ record: CaptureHistoryRecord) {
    guard record.fileExists else { return }

    HistoryFloatingManager.shared.hide()

    switch record.captureType {
    case .screenshot:
      AnnotateManager.shared.openAnnotation(url: record.fileURL)
    case .video, .gif:
      VideoEditorManager.shared.openEditor(for: record.fileURL)
    }
  }

  @discardableResult
  func deleteRecords(_ records: [CaptureHistoryRecord], asksConfirmation: Bool) -> Int {
    let recordsToDelete = uniqueRecords(records)
    guard !recordsToDelete.isEmpty else { return 0 }

    if asksConfirmation {
      let isConfirmed = HistoryFloatingManager.shared.performModalInteraction {
        confirmDelete(records: recordsToDelete)
      }
      guard isConfirmed else { return 0 }
    }

    let scopedAccesses = recordsToDelete.map {
      SandboxFileAccessManager.shared.beginAccessingURL($0.fileURL)
    }
    defer {
      scopedAccesses.forEach { $0.stop() }
    }

    let existingFileURLs = recordsToDelete
      .filter { FileManager.default.fileExists(atPath: $0.filePath) }
      .map(\.fileURL)

    if !existingFileURLs.isEmpty {
      try? NSWorkspace.shared.recycle(existingFileURLs)
    }

    let ids = recordsToDelete.map(\.id)
    CaptureHistoryStore.shared.remove(ids: ids)
    ids.forEach { HistoryThumbnailGenerator.shared.deleteThumbnail(for: $0) }

    AppToastManager.shared.show(
      message: L10n.PreferencesHistory.deletedCaptures(recordsToDelete.count),
      style: .success,
      duration: 1.7,
      variant: .compact
    )

    return recordsToDelete.count
  }

  private func uniqueRecords(_ records: [CaptureHistoryRecord]) -> [CaptureHistoryRecord] {
    var seenIds = Set<UUID>()
    return records.filter { record in
      seenIds.insert(record.id).inserted
    }
  }

  private func confirmDelete(records: [CaptureHistoryRecord]) -> Bool {
    let alert = NSAlert()
    alert.messageText = L10n.PreferencesHistory.deleteSelectedAlertTitle
    alert.informativeText = L10n.PreferencesHistory.deleteSelectedAlertMessage(records.count)
    alert.alertStyle = .warning
    alert.addButton(withTitle: L10n.Common.deleteAction)
    alert.addButton(withTitle: L10n.Common.cancel)

    return alert.runModal() == .alertFirstButtonReturn
  }
}
