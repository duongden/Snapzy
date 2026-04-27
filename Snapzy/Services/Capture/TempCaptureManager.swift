//
//  TempCaptureManager.swift
//  Snapzy
//
//  Manages temporary capture files for the "Auto-save" toggle.
//  When auto-save is OFF, captures are stored in a temp directory.
//  Users can manually save via Quick Access Card or dismiss to delete.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "TempCaptureManager")

/// Manages lifecycle of temporary capture files when auto-save is disabled
@MainActor
final class TempCaptureManager {

  static let shared = TempCaptureManager()

  private let preferencesManager = PreferencesManager.shared
  private let fileAccessManager = SandboxFileAccessManager.shared
  private let defaults = UserDefaults.standard

  /// Temp directory for unsaved captures (Application Support/Snapzy/Captures/).
  /// Uses Application Support instead of /tmp/ so macOS won't purge files
  /// during drag-and-drop — same pattern as CleanShot X.
  let tempCaptureDirectory: URL = {
    guard let appSupport = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first else {
      // Fallback if Application Support unavailable
      let fallback = FileManager.default.temporaryDirectory
        .appendingPathComponent("Snapzy_Captures", isDirectory: true)
      try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
      return fallback
    }
    let capturesDir = appSupport
      .appendingPathComponent("Snapzy", isDirectory: true)
      .appendingPathComponent("Captures", isDirectory: true)
    try? FileManager.default.createDirectory(at: capturesDir, withIntermediateDirectories: true)
    return capturesDir
  }()

  private init() {}

  // MARK: - Public API

  /// Resolve save directory based on auto-save toggle state.
  /// Returns temp directory if auto-save is OFF, export directory if ON.
  func resolveSaveDirectory(
    for captureType: CaptureType,
    exportDirectory: URL
  ) -> URL {
    let autoSaveEnabled = preferencesManager.isActionEnabled(.save, for: captureType)
    let typeLabel = captureType == .screenshot ? "screenshot" : "recording"

    if autoSaveEnabled {
      logger.info("Auto-save ON for \(typeLabel), using export directory")
      DiagnosticLogger.shared.log(
        .info,
        .capture,
        "Temp capture resolved to export directory",
        context: ["captureType": typeLabel, "autoSave": "true"]
      )
      return exportDirectory
    }

    // Auto-save OFF: use temp directory
    logger.info("Auto-save OFF for \(typeLabel), using temp directory")
    DiagnosticLogger.shared.log(
      .info,
      .capture,
      "Temp capture resolved to temp directory",
      context: ["captureType": typeLabel, "autoSave": "false"]
    )
    return tempCaptureDirectory
  }

  /// Move a temp file to the permanent export location.
  /// Returns the new URL on success, nil on failure.
  func saveToExportLocation(tempURL: URL) -> URL? {
    guard isTempFile(tempURL) else {
      logger.warning("saveToExportLocation called on non-temp file: \(tempURL.lastPathComponent)")
      DiagnosticLogger.shared.log(
        .warning,
        .fileAccess,
        "Temp capture save skipped; source is not a temp file",
        context: ["fileName": tempURL.lastPathComponent]
      )
      return nil
    }

    let exportDir = fileAccessManager.resolvedExportDirectoryURL()
    let exportAccess = fileAccessManager.beginAccessingURL(exportDir)
    defer { exportAccess.stop() }

    let destinationURL = exportAccess.url.appendingPathComponent(tempURL.lastPathComponent)

    do {
      // Create export directory if needed
      try FileManager.default.createDirectory(
        at: exportAccess.url,
        withIntermediateDirectories: true
      )

      // Move file from temp to export
      try FileManager.default.moveItem(at: tempURL, to: destinationURL)

      // Also move recording metadata if it exists (for video files)
      moveRecordingMetadataIfNeeded(from: tempURL, to: destinationURL)

      logger.info("Saved temp file to export: \(destinationURL.lastPathComponent)")
      DiagnosticLogger.shared.log(
        .info,
        .fileAccess,
        "Temp capture saved to export",
        context: ["fileName": destinationURL.lastPathComponent]
      )
      return destinationURL
    } catch {
      logger.error("Failed to save temp file: \(error.localizedDescription)")
      DiagnosticLogger.shared.logError(
        .fileAccess,
        error,
        "Temp capture save to export failed",
        context: ["fileName": tempURL.lastPathComponent]
      )
      return nil
    }
  }

  /// Delete a temp file
  func deleteTempFile(at url: URL) {
    guard isTempFile(url) else { return }

    do {
      try FileManager.default.removeItem(at: url)
      // Also clean up recording metadata if exists
      try? RecordingMetadataStore.delete(for: url)
      logger.debug("Deleted temp file: \(url.lastPathComponent)")
      DiagnosticLogger.shared.log(
        .info,
        .fileAccess,
        "Temp capture deleted",
        context: ["fileName": url.lastPathComponent]
      )
    } catch {
      logger.error("Failed to delete temp file: \(error.localizedDescription)")
      DiagnosticLogger.shared.logError(
        .fileAccess,
        error,
        "Temp capture delete failed",
        context: ["fileName": url.lastPathComponent]
      )
    }
  }

  /// Check if a URL is in the temp capture directory
  func isTempFile(_ url: URL) -> Bool {
    let tempPath = tempCaptureDirectory.standardizedFileURL.path
    let filePath = url.standardizedFileURL.path
    return filePath.hasPrefix(tempPath)
  }

  /// Cleanup all orphaned temp files (call on app launch).
  /// Skips files that have an active history record — the retention service
  /// will delete them when the history record ages out.
  func cleanupOrphanedFiles() {
    let fm = FileManager.default
    let contents: [URL]
    do {
      contents = try fm.contentsOfDirectory(
        at: tempCaptureDirectory,
        includingPropertiesForKeys: nil
      )
    } catch {
      DiagnosticLogger.shared.logError(.fileAccess, error, "Temp capture startup cleanup failed to list directory")
      return
    }

    let historyEnabled = defaults.object(forKey: PreferencesKeys.historyEnabled) as? Bool ?? true
    var count = 0
    var skipped = 0
    var preservedForRetention = 0

    for fileURL in contents {
      // Skip files referenced by active history records
      if CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path) {
        skipped += 1
        continue
      }

      // Keep recent temp captures alive while history is enabled, even if the
      // startup lookup cannot reconcile them yet. Retention and explicit cache
      // clearing remain the mechanisms that actually delete these files.
      if shouldPreserveForHistoryRetention(fileURL, historyEnabled: historyEnabled) {
        preservedForRetention += 1
        continue
      }

      do {
        try fm.removeItem(at: fileURL)
        try? RecordingMetadataStore.delete(for: fileURL)
        count += 1
      } catch {
        logger.error("Failed to cleanup orphan: \(fileURL.lastPathComponent)")
        DiagnosticLogger.shared.logError(
          .fileAccess,
          error,
          "Temp capture startup cleanup failed to delete orphan",
          context: ["fileName": fileURL.lastPathComponent]
        )
      }
    }

    if count > 0 {
      logger.info("Cleaned up \(count) orphaned temp capture file(s)")
      DiagnosticLogger.shared.log(
        .info,
        .lifecycle,
        "Temp capture startup cleanup removed orphaned files",
        context: ["fileCount": "\(count)"]
      )
    }
    if skipped > 0 {
      logger.info("Preserved \(skipped) temp file(s) with active history records")
      DiagnosticLogger.shared.log(
        .info,
        .lifecycle,
        "Temp capture startup cleanup preserved files with history records",
        context: ["fileCount": "\(skipped)"]
      )
    }
    if preservedForRetention > 0 {
      logger.info("Preserved \(preservedForRetention) recent temp file(s) within history retention window")
      DiagnosticLogger.shared.log(
        .info,
        .lifecycle,
        "Temp capture startup cleanup preserved recent files within history retention window",
        context: ["fileCount": "\(preservedForRetention)"]
      )
    }
  }

  // MARK: - Private

  /// Move associated recording metadata sidecar when saving a video
  private func moveRecordingMetadataIfNeeded(from sourceURL: URL, to destinationURL: URL) {
    // RecordingMetadataStore keeps metadata in App Support and maps it by file bookmark/path.
    // Re-save using destination URL so association follows the moved video.
    if let metadata = RecordingMetadataStore.load(for: sourceURL) {
      do {
        try RecordingMetadataStore.save(metadata, for: destinationURL)
        try RecordingMetadataStore.delete(for: sourceURL)
        DiagnosticLogger.shared.log(
          .debug,
          .recording,
          "Recording metadata moved with temp capture",
          context: ["fileName": destinationURL.lastPathComponent]
        )
      } catch {
        DiagnosticLogger.shared.logError(
          .recording,
          error,
          "Recording metadata move failed for temp capture",
          context: ["fileName": destinationURL.lastPathComponent]
        )
      }
    }
  }

  private func shouldPreserveForHistoryRetention(_ fileURL: URL, historyEnabled: Bool) -> Bool {
    guard historyEnabled else { return false }
    guard
      let values = try? fileURL.resourceValues(
        forKeys: [.isRegularFileKey, .contentModificationDateKey, .creationDateKey]
      ),
      values.isRegularFile == true
    else {
      return false
    }

    let retentionDays = defaults.integer(forKey: PreferencesKeys.historyRetentionDays)
    if retentionDays == 0 {
      return true
    }

    let referenceDate = values.contentModificationDate ?? values.creationDate ?? .distantPast
    let cutoff = Date().addingTimeInterval(-TimeInterval(retentionDays * 24 * 60 * 60))
    return referenceDate >= cutoff
  }
}
