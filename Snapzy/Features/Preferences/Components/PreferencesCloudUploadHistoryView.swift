//
//  PreferencesCloudUploadHistoryView.swift
//  Snapzy
//
//  Window and view for managing all cloud upload history records
//

import AppKit
import SwiftUI

// MARK: - History Window Controller

/// Manages the cloud upload history window lifecycle
@MainActor
final class CloudUploadHistoryWindowController {
  static let shared = CloudUploadHistoryWindowController()

  private var window: NSWindow?

  private init() {}

  func showWindow() {
    if let existingWindow = window, existingWindow.isVisible {
      existingWindow.makeKeyAndOrderFront(nil)
      return
    }

    let view = CloudUploadHistoryView()
    let hostingView = NSHostingView(rootView: view)

    let newWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    newWindow.title = "Cloud Upload History"
    newWindow.contentView = hostingView
    newWindow.center()
    newWindow.isReleasedWhenClosed = false
    newWindow.makeKeyAndOrderFront(nil)

    window = newWindow
  }
}

// MARK: - History View

/// Main view for browsing and managing cloud upload history
struct CloudUploadHistoryView: View {
  @ObservedObject private var store = CloudUploadHistoryStore.shared
  @ObservedObject private var cloudManager = CloudManager.shared
  @State private var searchText = ""
  @State private var confirmDeleteAll = false
  @State private var isDeleting = false
  @State private var deleteError: String?

  private var filteredRecords: [CloudUploadRecord] {
    if searchText.isEmpty { return store.records }
    return store.records.filter { record in
      record.fileName.localizedCaseInsensitiveContains(searchText)
        || record.publicURL.absoluteString.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Toolbar
      HStack {
        HStack(spacing: 6) {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
            .font(.system(size: 12))
          TextField("Search uploads...", text: $searchText)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))

        Spacer()

        if isDeleting {
          ProgressView()
            .scaleEffect(0.6)
            .frame(width: 14, height: 14)
        }

        Text("\(store.records.count) uploads")
          .font(.system(size: 11))
          .foregroundColor(.secondary)

        Button(role: .destructive) {
          confirmDeleteAll = true
        } label: {
          Image(systemName: "trash")
            .font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .help("Clear all history")
        .disabled(store.records.isEmpty || isDeleting)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)

      // Error banner
      if let error = deleteError {
        HStack(spacing: 6) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
            .font(.system(size: 11))
          Text(error)
            .font(.system(size: 11))
            .foregroundColor(.orange)
          Spacer()
          Button("Dismiss") { deleteError = nil }
            .font(.system(size: 10))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
      }

      Divider()

      // Records list
      if filteredRecords.isEmpty {
        VStack(spacing: 8) {
          Spacer()
          Image(systemName: "icloud.slash")
            .font(.system(size: 32))
            .foregroundColor(.secondary)
          Text(searchText.isEmpty ? "No uploads yet" : "No results found")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
          Spacer()
        }
        .frame(maxWidth: .infinity)
      } else {
        List {
          ForEach(filteredRecords) { record in
            HistoryRecordRow(record: record, isDeleting: isDeleting) {
              deleteRecord(record)
            }
          }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
      }
    }
    .frame(minWidth: 500, minHeight: 350)
    .alert("Clear All Upload History?", isPresented: $confirmDeleteAll) {
      Button("Delete from Cloud & Clear", role: .destructive) {
        deleteAllFromCloud()
      }
      Button("Clear History Only") {
        store.removeAll()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("\"Delete from Cloud & Clear\" removes files from cloud storage and local history.\n\"Clear History Only\" removes local records but keeps files on cloud.")
    }
  }

  private func deleteRecord(_ record: CloudUploadRecord) {
    isDeleting = true
    deleteError = nil
    Task {
      do {
        try await cloudManager.deleteFromCloud(record: record)
      } catch {
        deleteError = "Failed to delete \(record.fileName): \(error.localizedDescription)"
      }
      isDeleting = false
    }
  }

  private func deleteAllFromCloud() {
    let records = store.records
    isDeleting = true
    deleteError = nil
    Task {
      do {
        try await cloudManager.deleteAllFromCloud(records: records)
      } catch {
        deleteError = "Some files could not be deleted: \(error.localizedDescription)"
      }
      isDeleting = false
    }
  }
}

// MARK: - History Record Row

private struct HistoryRecordRow: View {
  let record: CloudUploadRecord
  let isDeleting: Bool
  let onDelete: () -> Void

  @State private var isHovering = false
  @State private var copied = false

  var body: some View {
    HStack(spacing: 12) {
      // File icon
      Image(systemName: record.isExpired ? "doc.badge.clock" : "doc.fill")
        .font(.system(size: 18))
        .foregroundColor(record.isExpired ? .orange : .accentColor)
        .frame(width: 28)

      // File info
      VStack(alignment: .leading, spacing: 3) {
        Text(record.fileName)
          .font(.system(size: 13, weight: .medium))
          .lineLimit(1)

        HStack(spacing: 8) {
          Label(record.formattedDate, systemImage: "calendar")
          Label(record.formattedFileSize, systemImage: "doc")
          Label(record.expireTime.displayName, systemImage: "clock")
          Label(record.providerType.displayName, systemImage: "cloud")

          if record.isExpired {
            Text("Expired")
              .fontWeight(.medium)
              .foregroundColor(.orange)
          }
        }
        .font(.system(size: 10))
        .foregroundColor(.secondary)

        Text(record.publicURL.absoluteString)
          .font(.system(size: 10, design: .monospaced))
          .foregroundColor(.blue)
          .lineLimit(1)
          .truncationMode(.middle)
      }

      Spacer()

      // Actions
      if isHovering {
        HStack(spacing: 8) {
          Button(action: copyLink) {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
              .font(.system(size: 11))
              .foregroundColor(copied ? .green : .primary)
          }
          .buttonStyle(.plain)
          .help("Copy link")

          Button(action: openInBrowser) {
            Image(systemName: "safari")
              .font(.system(size: 11))
          }
          .buttonStyle(.plain)
          .help("Open in browser")

          Button(role: .destructive, action: onDelete) {
            Image(systemName: "trash")
              .font(.system(size: 11))
              .foregroundColor(.red)
          }
          .buttonStyle(.plain)
          .help("Remove from history")
        }
        .transition(.opacity)
      }
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
    .onHover { isHovering = $0 }
    .animation(.easeInOut(duration: 0.15), value: isHovering)
  }

  private func copyLink() {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(record.publicURL.absoluteString, forType: .string)
    copied = true
    Task {
      try? await Task.sleep(nanoseconds: 1_500_000_000)
      copied = false
    }
  }

  private func openInBrowser() {
    NSWorkspace.shared.open(record.publicURL)
  }
}

#Preview {
  CloudUploadHistoryView()
    .frame(width: 600, height: 500)
}
