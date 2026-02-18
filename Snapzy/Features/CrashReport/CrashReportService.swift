//
//  CrashReportService.swift
//  Snapzy
//
//  Centralized crash report presentation logic.
//  Both the status bar menu and preferences call this single entry point.
//

import AppKit

enum CrashReportService {

  static let bugReportURL = URL(string: "https://snapzy.app/bug-report")!

  /// Present the crash report alert with a draggable log file.
  /// Returns `true` if the user chose "Submit" (and the bug report page was opened).
  @MainActor
  @discardableResult
  static func presentAlert() -> Bool {
    let alert = NSAlert()
    alert.messageText = "Snapzy quit unexpectedly"
    alert.informativeText = "A diagnostic log was saved. Drag the file below to the bug report page."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Submit")
    alert.addButton(withTitle: "Dismiss")

    let logFile = DiagnosticLogger.shared.currentLogFileURL
    if FileManager.default.fileExists(atPath: logFile.path) {
      alert.accessoryView = CrashReportAccessoryView(fileURL: logFile)
    }

    let response = alert.runModal()

    if response == .alertFirstButtonReturn {
      NSWorkspace.shared.open(bugReportURL)
      return true
    }

    return false
  }
}
