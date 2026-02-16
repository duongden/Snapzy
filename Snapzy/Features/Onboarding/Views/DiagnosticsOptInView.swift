//
//  DiagnosticsOptInView.swift
//  Snapzy
//
//  Onboarding step for crash logging opt-in — dark/frosted theme
//

import SwiftUI

struct DiagnosticsOptInView: View {
  let onBack: () -> Void
  let onNext: () -> Void

  @AppStorage(PreferencesKeys.diagnosticsEnabled) private var diagnosticsEnabled = true

  var body: some View {
    ZStack {
      VStack(spacing: 24) {
        Spacer()

        // Icon
        Image(systemName: "doc.text.magnifyingglass")
          .font(.system(size: 48))
          .foregroundColor(.white.opacity(0.8))

        // Title
        Text("Help Us Improve")
          .vsHeading()

        // Description
        Text(
          "Snapzy can collect anonymous diagnostic logs when something goes wrong. These logs help us find and fix bugs faster."
        )
        .vsBody()
        .multilineTextAlignment(.center)
        .frame(maxWidth: 340)

        // Toggle card
        VStack(spacing: 12) {
          HStack(spacing: 12) {
            Image(systemName: "ant.fill")
              .font(.system(size: 14))
              .foregroundColor(.white.opacity(0.6))
              .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
              Text("Enable Crash Logging")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

              Text("Logs are stored locally on your device")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $diagnosticsEnabled)
              .labelsHidden()
              .toggleStyle(.switch)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.white.opacity(0.06))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
          )
        }
        .frame(maxWidth: 380)

        // Privacy note
        Text("No personal data is collected. Nothing is sent without your action.")
          .font(.system(size: 11))
          .foregroundColor(.white.opacity(0.35))
          .multilineTextAlignment(.center)
          .frame(maxWidth: 340)

        Spacer()

        // Navigation
        HStack(spacing: 16) {
          Button("Back") {
            onBack()
          }
          .buttonStyle(VSDesignSystem.SecondaryButtonStyle())

          Button("Next") {
            onNext()
          }
          .buttonStyle(VSDesignSystem.PrimaryButtonStyle())
          .keyboardShortcut(.return, modifiers: [])
        }

        Spacer()
          .frame(height: 40)
      }
      .padding(40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  DiagnosticsOptInView(
    onBack: {},
    onNext: {}
  )
  .frame(width: 500, height: 520)
  .background(.black.opacity(0.5))
}
