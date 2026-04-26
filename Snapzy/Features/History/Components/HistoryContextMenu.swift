//
//  HistoryContextMenu.swift
//  Snapzy
//
//  Context menu for history items
//

import SwiftUI

struct HistoryContextMenu: View {
  let record: CaptureHistoryRecord

  var body: some View {
    Button("Open in Finder") {
      NSWorkspace.shared.activateFileViewerSelecting([record.fileURL])
    }

    Button("Copy") {
      HistoryWindowController.shared.copyToClipboard([record])
    }

    Button("Edit") {
      HistoryWindowController.shared.openItem(record)
    }

    if CloudManager.shared.isConfigured {
      Button("Upload to Cloud") {
        Task {
          _ = try? await CloudManager.shared.upload(fileURL: record.fileURL)
        }
      }
    }

    Divider()

    Button("Delete") {
      HistoryWindowController.shared.deleteRecords([record], asksConfirmation: false)
    }
  }
}
