//
//  VideoEditorPlaceholderView.swift
//  ZapShot
//
//  Placeholder view for video editor (coming soon)
//

import SwiftUI

/// Placeholder view displayed when video editor is not yet implemented
struct VideoEditorPlaceholderView: View {
  let videoName: String

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      // Video icon
      Image(systemName: "film")
        .font(.system(size: 64))
        .foregroundColor(.secondary)

      // Title
      Text("Video Editor")
        .font(.title)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      // Coming soon message
      Text("Coming Soon")
        .font(.title2)
        .foregroundColor(.secondary)

      // Video filename
      Text(videoName)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
        .padding(.horizontal, 40)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(NSColor.windowBackgroundColor))
  }
}
