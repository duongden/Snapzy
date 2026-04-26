//
//  HistoryToolbar.swift
//  Snapzy
//
//  Top toolbar for the history browser
//

import SwiftUI

struct HistoryToolbar: View {
  @Binding var searchText: String
  let selectedCount: Int
  let canSelectAll: Bool
  let onSelectAll: () -> Void
  let onClearSelection: () -> Void
  let onDeleteSelection: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      // Search
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
        TextField("Search by filename", text: $searchText)
          .textFieldStyle(PlainTextFieldStyle())
        if !searchText.isEmpty {
          Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(8)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .stroke(Color.white.opacity(0.08), lineWidth: 1)
      )

      Spacer()

      // Selection info
      if selectedCount > 0 {
        Text(L10n.PreferencesHistory.selectedCaptures(selectedCount))
          .font(.caption)
          .foregroundColor(.secondary)

        if canSelectAll {
          Button(action: onSelectAll) {
            Text(L10n.PreferencesHistory.selectAll)
              .font(.caption)
          }
          .buttonStyle(PlainButtonStyle())
        }

        Button(action: onClearSelection) {
          Text(L10n.PreferencesHistory.clearSelection)
            .font(.caption)
        }
        .buttonStyle(PlainButtonStyle())

        Button(action: onDeleteSelection) {
          Label(L10n.Common.deleteAction, systemImage: "trash")
            .font(.caption)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.red)
      }
    }
    .padding(.horizontal)
    .padding(.top, 12)
    .padding(.bottom, 4)
  }
}
