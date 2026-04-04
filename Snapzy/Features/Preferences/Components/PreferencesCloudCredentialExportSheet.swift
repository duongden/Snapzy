//
//  PreferencesCloudCredentialExportSheet.swift
//  Snapzy
//
//  Passphrase prompt for exporting an encrypted cloud credential archive.
//

import AppKit
import SwiftUI

struct CloudCredentialExportSheet: View {
  let payload: CloudCredentialTransferPayload
  let onExported: (URL) -> Void
  let onCancel: () -> Void

  @State private var passphrase = ""
  @State private var confirmPassphrase = ""
  @State private var errorMessage: String?
  @State private var isExporting = false

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 8) {
        Image(systemName: "square.and.arrow.up.fill")
          .font(.system(size: 30))
          .foregroundColor(.accentColor)
        Text("Export Cloud Credentials")
          .font(.headline)
        Text("Create an encrypted archive you can import on another Mac. Snapzy does not store this archive passphrase.")
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }

      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Archive Contents")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
          Text("\(payload.providerDisplayName) • Bucket: \(payload.configuration.bucket)")
            .font(.system(size: 12))
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("Archive Passphrase")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
          SecureField(
            "At least \(CloudCredentialTransferService.minimumPassphraseLength) characters",
            text: $passphrase
          )
          .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("Confirm Passphrase")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
          SecureField("Re-enter archive passphrase", text: $confirmPassphrase)
            .textFieldStyle(.roundedBorder)
            .onSubmit { exportArchive() }
        }

        if let errorMessage {
          HStack(alignment: .top, spacing: 6) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 12))
              .foregroundColor(.red)
            Text(errorMessage)
              .font(.system(size: 11))
              .foregroundColor(.red)
          }
        }
      }

      HStack(spacing: 12) {
        Button("Cancel") {
          onCancel()
        }
        .keyboardShortcut(.escape, modifiers: [])

        Button(action: exportArchive) {
          if isExporting {
            ProgressView()
              .controlSize(.small)
          } else {
            Text("Choose Destination")
          }
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.return, modifiers: [])
        .disabled(isExporting)
      }
    }
    .padding(24)
    .frame(width: 400)
  }

  private func exportArchive() {
    errorMessage = nil

    guard passphrase.count >= CloudCredentialTransferService.minimumPassphraseLength else {
      errorMessage =
        "Passphrase must be at least \(CloudCredentialTransferService.minimumPassphraseLength) characters."
      return
    }
    guard passphrase == confirmPassphrase else {
      errorMessage = "Passphrases do not match."
      return
    }
    guard let destinationURL = chooseExportDestinationURL() else { return }

    isExporting = true
    defer {
      isExporting = false
    }

    do {
      try CloudCredentialTransferService.exportArchive(
        payload: payload,
        to: destinationURL,
        passphrase: passphrase
      )
      onExported(destinationURL)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func chooseExportDestinationURL() -> URL? {
    let panel = NSSavePanel()
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    panel.allowedContentTypes = [CloudCredentialTransferService.archiveContentType]
    panel.nameFieldStringValue = CloudCredentialTransferService.suggestedArchiveFileName(for: payload)
    panel.title = "Export Cloud Credentials"
    panel.message = "Choose where Snapzy should save the encrypted credential archive."
    return panel.runModal() == .OK ? panel.url : nil
  }
}
