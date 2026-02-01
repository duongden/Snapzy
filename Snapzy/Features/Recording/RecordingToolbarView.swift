//
//  RecordingToolbarView.swift
//  Snapzy
//
//  Pre-record toolbar with options menu and record/cancel buttons
//  Styled to match Apple's native macOS recording toolbar aesthetic
//

import SwiftUI

struct RecordingToolbarView: View {
  @ObservedObject var state: RecordingToolbarState
  let onRecord: () -> Void
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: ToolbarConstants.itemSpacing) {
      // Close button
      ToolbarIconButton(
        systemName: "xmark",
        action: onCancel,
        accessibilityLabel: "Cancel recording"
      )

      RecordingToolbarDivider()

      // Options menu
      ToolbarOptionsMenu(state: state)

      // Capture mode toggle (area/fullscreen)
      ToolbarCaptureAreaToggle(state: state)

      // Mic toggle button
      ToolbarMicToggleButton(state: state)

      RecordingToolbarDivider()

      // Record button
      Button(action: onRecord) {
        HStack(spacing: 6) {
          Image(systemName: "record.circle.fill")
          Text("Record")
        }
      }
      .buttonStyle(RecordButtonStyle())
      .fixedSize()
      .accessibilityLabel("Start recording")
      .accessibilityHint("Begins screen recording with current settings")
    }
    .padding(.horizontal, ToolbarConstants.horizontalPadding)
    .padding(.vertical, ToolbarConstants.verticalPadding)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: ToolbarConstants.toolbarCornerRadius))
    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Recording toolbar")
  }
}

#Preview {
  RecordingToolbarView(
    state: RecordingToolbarState(),
    onRecord: {},
    onCancel: {}
  )
  .padding()
}
