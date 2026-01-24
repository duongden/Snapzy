//
//  VideoInfoPanel.swift
//  ClaudeShot
//
//  Video metadata display panel
//

import SwiftUI

/// Panel displaying video file information
struct VideoInfoPanel: View {
  @ObservedObject var state: VideoEditorState

  var body: some View {
    HStack(spacing: 24) {
      InfoItem(label: "File", value: state.filename)
      InfoItem(label: "Resolution", value: state.resolutionString)
      InfoItem(label: "Format", value: state.fileExtension.uppercased())
      InfoItem(label: "Duration", value: state.formattedDuration)

      Spacer()

      // Zoom segments count badge
      if !state.zoomSegments.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "plus.magnifyingglass")
            .font(.system(size: 10))
          Text("\(state.zoomSegments.count) zoom\(state.zoomSegments.count > 1 ? "s" : "")")
            .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(ZoomColors.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ZoomColors.primary.opacity(0.15))
        .cornerRadius(4)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(Color.white.opacity(0.05))
    .cornerRadius(6)
  }
}

// MARK: - Info Item

/// Single info item with label and value
private struct InfoItem: View {
  let label: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.system(size: 10))
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      Text(value)
        .font(.system(size: 12))
        .foregroundColor(.primary)
        .lineLimit(1)
        .truncationMode(.middle)
    }
  }
}
