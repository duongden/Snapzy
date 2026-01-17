//
//  RecordingToolbarView.swift
//  ZapShot
//
//  Pre-record toolbar with format picker and record/cancel buttons
//

import SwiftUI

struct RecordingToolbarView: View {
  @Binding var selectedFormat: VideoFormat
  let onRecord: () -> Void
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      // Format picker
      Picker("Format", selection: $selectedFormat) {
        Text("MOV").tag(VideoFormat.mov)
        Text("MP4").tag(VideoFormat.mp4)
      }
      .pickerStyle(.segmented)
      .frame(width: 120)

      Divider()
        .frame(height: 20)

      // Record button
      Button(action: onRecord) {
        Label("Record", systemImage: "record.circle")
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
      .controlSize(.large)

      // Cancel button
      Button("Cancel", action: onCancel)
        .controlSize(.large)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
  }
}

#Preview {
  RecordingToolbarView(
    selectedFormat: .constant(.mov),
    onRecord: {},
    onCancel: {}
  )
  .padding()
}
