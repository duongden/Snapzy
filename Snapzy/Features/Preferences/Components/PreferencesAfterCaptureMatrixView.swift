//
//  AfterCaptureMatrixView.swift
//  Snapzy
//
//  Grid component for configuring post-capture actions
//

import SwiftUI

struct AfterCaptureMatrixView: View {
  @ObservedObject private var manager = PreferencesManager.shared
  @ObservedObject private var cloudManager = CloudManager.shared
  @State private var showCloudNotConfiguredAlert = false

  var body: some View {
    VStack(spacing: 0) {
      // Column headers
      HStack(spacing: 12) {
        Spacer()
          .frame(width: 28)
        Spacer()
        HStack(spacing: 16) {
          Text("Screenshot")
            .font(.caption2)
            .foregroundColor(.secondary)
            .frame(width: 70)
          Text("Recording")
            .font(.caption2)
            .foregroundColor(.secondary)
            .frame(width: 70)
        }
      }
      .padding(.bottom, 4)

      ForEach(AfterCaptureAction.allCases, id: \.self) { action in
        actionRow(for: action)
      }
    }
    .alert("Cloud Not Configured", isPresented: $showCloudNotConfiguredAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please set up your cloud credentials in Preferences → Cloud before enabling this option.")
    }
  }

  @ViewBuilder
  private func actionRow(for action: AfterCaptureAction) -> some View {
    HStack(spacing: 12) {
      Image(systemName: iconName(for: action))
        .font(.title2)
        .foregroundColor(.secondary)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 2) {
        Text(action.displayName)
          .fontWeight(.medium)
        Text(description(for: action))
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      HStack(spacing: 16) {
        toggleColumn(label: "Screenshot", action: action, type: .screenshot)
        toggleColumn(label: "Recording", action: action, type: .recording)
      }
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private func toggleColumn(label: String, action: AfterCaptureAction, type: CaptureType) -> some View {
    let isDisabled = (action == .openAnnotate && type == .recording)
      || (action == .uploadToCloud && type == .recording)
    Toggle("", isOn: cloudAwareBinding(for: action, type: type))
      .labelsHidden()
      .accessibilityLabel("\(action.displayName) for \(label.lowercased())")
      .frame(width: 70)
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.3 : 1)
  }

  private func iconName(for action: AfterCaptureAction) -> String {
    switch action {
    case .showQuickAccess:
      return "rectangle.on.rectangle.angled"
    case .copyFile:
      return "doc.on.clipboard"
    case .save:
      return "square.and.arrow.down"
    case .openAnnotate:
      return "pencil.and.outline"
    case .uploadToCloud:
      return "icloud.and.arrow.up"
    }
  }

  private func description(for action: AfterCaptureAction) -> String {
    switch action {
    case .showQuickAccess:
      return "Display overlay with quick actions"
    case .copyFile:
      return "Copy to clipboard automatically"
    case .save:
      return "Save to export location"
    case .openAnnotate:
      return "Open annotate editor after capture"
    case .uploadToCloud:
      return "Upload screenshot to cloud & copy link"
    }
  }

  private func binding(for action: AfterCaptureAction, type: CaptureType) -> Binding<Bool> {
    Binding(
      get: { manager.isActionEnabled(action, for: type) },
      set: { manager.setAction(action, for: type, enabled: $0) }
    )
  }

  /// Cloud-aware binding that shows alert when enabling cloud without configuration
  private func cloudAwareBinding(for action: AfterCaptureAction, type: CaptureType) -> Binding<Bool> {
    Binding(
      get: { manager.isActionEnabled(action, for: type) },
      set: { newValue in
        if action == .uploadToCloud && newValue && !cloudManager.isConfigured {
          showCloudNotConfiguredAlert = true
          return
        }
        manager.setAction(action, for: type, enabled: newValue)
      }
    )
  }
}

#Preview {
  AfterCaptureMatrixView()
    .padding()
}
