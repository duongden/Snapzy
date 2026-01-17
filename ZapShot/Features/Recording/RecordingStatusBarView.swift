//
//  RecordingStatusBarView.swift
//  ZapShot
//
//  Status bar shown during active recording with timer and controls
//

import SwiftUI

struct RecordingStatusBarView: View {
  @ObservedObject var recorder: ScreenRecordingManager
  let onStop: () -> Void

  @State private var indicatorOpacity: Double = 1.0

  var body: some View {
    HStack(spacing: 16) {
      // Recording indicator (pulsing red dot)
      Circle()
        .fill(.red)
        .frame(width: 10, height: 10)
        .opacity(recorder.isPaused ? 0.4 : indicatorOpacity)
        .animation(
          .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
          value: indicatorOpacity
        )
        .onAppear { indicatorOpacity = 0.3 }

      // Timer display
      Text(recorder.formattedDuration)
        .font(.system(.body, design: .monospaced))
        .foregroundColor(recorder.isPaused ? .secondary : .primary)
        .frame(width: 60, alignment: .leading)

      Divider()
        .frame(height: 20)

      // Pause/Resume button
      Button(action: { recorder.togglePause() }) {
        Image(systemName: recorder.isPaused ? "play.fill" : "pause.fill")
          .frame(width: 20)
      }
      .buttonStyle(.bordered)
      .controlSize(.regular)

      // Stop button
      Button(action: onStop) {
        Image(systemName: "stop.fill")
          .foregroundColor(.red)
      }
      .buttonStyle(.bordered)
      .controlSize(.regular)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
  }
}

#Preview {
  RecordingStatusBarView(
    recorder: ScreenRecordingManager.shared,
    onStop: {}
  )
  .padding()
}
