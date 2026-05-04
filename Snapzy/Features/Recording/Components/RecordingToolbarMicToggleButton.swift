//
//  ToolbarMicToggleButton.swift
//  Snapzy
//
//  Toggle button for microphone mute/unmute in recording toolbar
//  Styled to match Apple's native macOS recording toolbar
//

import AVFoundation
import SwiftUI

struct ToolbarMicToggleButton: View {
  @ObservedObject var state: RecordingToolbarState
  @State private var isHovered = false
  @State private var showPermissionDeniedAlert = false

  private var systemName: String {
    state.captureMicrophone ? "mic.fill" : "mic.slash.fill"
  }

  private var accessibilityLabel: String {
    state.captureMicrophone ? L10n.Microphone.mute : L10n.Microphone.unmute
  }

  private var tooltipText: String {
    state.captureMicrophone ? L10n.Microphone.on : L10n.Microphone.off
  }

  var body: some View {
    Button {
      handleMicToggle()
    } label: {
      Image(systemName: systemName)
        .font(.system(size: ToolbarConstants.iconSize, weight: .medium))
        .foregroundColor(foregroundColor)
        .frame(
          width: ToolbarConstants.iconButtonSize,
          height: ToolbarConstants.iconButtonSize
        )
        .background(
          RoundedRectangle(cornerRadius: ToolbarConstants.buttonCornerRadius)
            .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
        )
        .contentShape(RoundedRectangle(cornerRadius: ToolbarConstants.buttonCornerRadius))
        .animation(ToolbarConstants.hoverAnimation, value: isHovered)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .help(tooltipText)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(L10n.Microphone.doubleTapToToggle)
    .alert(L10n.Microphone.accessRequiredTitle, isPresented: $showPermissionDeniedAlert) {
      Button(L10n.Common.openSystemSettings) {
        openMicrophoneSettings()
      }
      Button(L10n.Common.cancel, role: .cancel) {}
    } message: {
      Text(L10n.Microphone.preferencesMessage)
    }
  }

  private var foregroundColor: Color {
    .primary.opacity(state.captureMicrophone ? 1.0 : 0.5)
  }

  /// Request microphone permission when user enables toggle
  private func handleMicToggle() {
    if state.captureMicrophone {
      state.captureMicrophone = false
      return
    }

    let status = AVCaptureDevice.authorizationStatus(for: .audio)

    switch status {
    case .notDetermined:
      Task {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
          if granted {
            state.captureMicrophone = true
          } else {
            showPermissionDeniedAlert = true
          }
        }
      }
    case .authorized:
      state.captureMicrophone = true
    case .denied, .restricted:
      showPermissionDeniedAlert = true
    @unknown default:
      state.captureMicrophone = true
    }
  }

  private func openMicrophoneSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
      NSWorkspace.shared.open(url)
    }
  }
}

#Preview {
  HStack(spacing: 4) {
    ToolbarMicToggleButton(state: RecordingToolbarState())
  }
  .padding(10)
  .background(.ultraThinMaterial)
  .clipShape(RoundedRectangle(cornerRadius: 14))
}
