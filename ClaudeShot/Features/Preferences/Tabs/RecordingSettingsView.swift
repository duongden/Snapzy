//
//  RecordingSettingsView.swift
//  ClaudeShot
//
//  Recording preferences tab with format, quality, and audio settings
//

import AVFoundation
import SwiftUI

struct RecordingSettingsView: View {
  @AppStorage(PreferencesKeys.recordingFormat) private var format = "mov"
  @AppStorage(PreferencesKeys.recordingFPS) private var fps = 30
  @AppStorage(PreferencesKeys.recordingQuality) private var quality = "high"
  @AppStorage(PreferencesKeys.recordingCaptureAudio) private var captureAudio = true
  @AppStorage(PreferencesKeys.recordingCaptureMicrophone) private var captureMicrophone = false

  @State private var showPermissionDeniedAlert = false

  /// Microphone capture via ScreenCaptureKit requires macOS 15.0+
  private var isMicAvailable: Bool {
    if #available(macOS 15.0, *) {
      return true
    }
    return false
  }

  var body: some View {
    Form {
      Section("Format") {
        Picker("Video Format", selection: $format) {
          Text("MOV (Recommended)").tag("mov")
          Text("MP4").tag("mp4")
        }
        .pickerStyle(.radioGroup)

        Text("MOV offers better quality. MP4 provides wider compatibility.")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Section("Quality") {
        Picker("Frame Rate", selection: $fps) {
          Text("30 FPS").tag(30)
          Text("60 FPS").tag(60)
        }

        Picker("Quality", selection: $quality) {
          Text("High").tag("high")
          Text("Medium").tag("medium")
          Text("Low").tag("low")
        }

        Text("Higher quality results in larger file sizes.")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Section("Audio") {
        Toggle("Capture System Audio", isOn: $captureAudio)

        Toggle("Capture Microphone", isOn: Binding(
          get: { captureMicrophone },
          set: { newValue in
            if newValue {
              handleMicrophoneEnable()
            } else {
              captureMicrophone = false
            }
          }
        ))
        .disabled(!captureAudio || !isMicAvailable)

        if !isMicAvailable {
          Text("Microphone capture requires macOS 15.0 or later.")
            .font(.caption)
            .foregroundColor(.orange)
        } else {
          Text("System audio captures sounds from apps. Microphone captures your voice.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .alert("Microphone Access Required", isPresented: $showPermissionDeniedAlert) {
        Button("Open System Settings") {
          openMicrophoneSettings()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("ClaudeShot needs microphone permission. Please enable it in System Settings > Privacy & Security > Microphone.")
      }

      Section("Save Location") {
        HStack {
          Text("Recordings save to the same location as screenshots.")
            .foregroundColor(.secondary)
          Spacer()
          Text("See General tab")
            .foregroundColor(.accentColor)
            .font(.caption)
        }
      }
    }
    .formStyle(.grouped)
  }

  /// Request microphone permission when user enables toggle
  private func handleMicrophoneEnable() {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)

    switch status {
    case .notDetermined:
      Task {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
          if granted {
            captureMicrophone = true
          } else {
            showPermissionDeniedAlert = true
          }
        }
      }
    case .authorized:
      captureMicrophone = true
    case .denied, .restricted:
      showPermissionDeniedAlert = true
    @unknown default:
      captureMicrophone = true
    }
  }

  private func openMicrophoneSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
      NSWorkspace.shared.open(url)
    }
  }
}

#Preview {
  RecordingSettingsView()
    .frame(width: 500, height: 400)
}
