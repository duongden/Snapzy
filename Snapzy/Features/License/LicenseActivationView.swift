//
//  LicenseActivationView.swift
//  Snapzy
//
//  License activation screen for first-time setup — dark/frosted theme
//

import SwiftUI

struct LicenseActivationView: View {
    let onContinue: () -> Void

    @State private var licenseKey: String = ""
    @State private var isValidating = false
    @State private var isActivating = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header icon
            Image(systemName: "key.fill")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.8))

            // Title
            Text("License Activation")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            // Subtitle
            Text("Enter your license key to activate Snapzy Pro")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            // Sandbox indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(PolarLicenseProvider.isSandbox ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(PolarLicenseProvider.isSandbox ? "Sandbox Mode" : "Production Mode")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 4)

            // License Key Input
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("License Key")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    TextField("SNAPZY-XXXXX-XXXXX-XXXXX", text: $licenseKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }


                // Purchase Link
                HStack {
                    Spacer()
                    Button {
                        if let url = URL(string: PolarLicenseProvider.isSandbox ? "https://sandbox.polar.sh" : "https://polar.sh") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cart")
                                .font(.system(size: 11))
                            Text("Purchase License")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 380)
            .padding(.top, 8)

            // Error Message
            if showError {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))

                        Text(errorMessage ?? "Invalid license key")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }

                    // Troubleshooting suggestions
                    if PolarLicenseProvider.isSandbox {
                        Text("Make sure you created the license in sandbox.polar.sh")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 4)
            }

            Spacer()

            // Continue Button
            Button {
                activateLicense()
            } label: {
                ZStack {
                    // Hidden "Activating..." layout to reserve max width
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 14, height: 14)
                        Text("Activating...")
                    }
                    .hidden()

                    // Visible content
                    HStack(spacing: 8) {
                        if isValidating || isActivating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .frame(width: 14, height: 14)
                        }
                        Text(buttonLabel)
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isProcessing || licenseKey.isEmpty ? Color.white.opacity(0.1) : Color.white.opacity(0.2))
                )
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(licenseKey.isEmpty || isProcessing)
            .keyboardShortcut(.return, modifiers: [])

            // Hint
            Text("Press Enter ↵")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))

            Spacer()
                .frame(height: 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    /// Whether any async operation is in progress
    private var isProcessing: Bool {
        isValidating || isActivating
    }

    /// Dynamic button label based on current phase
    private var buttonLabel: String {
        if isValidating { return "Validating..." }
        if isActivating { return "Activating..." }
        return "Continue"
    }

    private func activateLicense() {
        guard !licenseKey.isEmpty else { return }

        // Trim whitespace and validate format
        let cleanedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        #if DEBUG
        print("=== LICENSE ACTIVATION DEBUG ===")
        print("Original key: '\(licenseKey)'")
        print("Cleaned key: '\(cleanedKey)'")
        print("Key length: \(cleanedKey.count)")
        print("API URL: \(PolarLicenseProvider.shared.currentBaseURL)")
        if let orgId = LicenseManager.shared.getOrganizationId() {
            print("Org ID: \(orgId.uuidString)")
        }
        print("=============================")
        #endif

        showError = false

        Task {
            do {
                // Phase 1: Validate the key before activating
                isValidating = true
                _ = try await LicenseManager.shared.validateLicenseKey(key: cleanedKey)
                isValidating = false

                #if DEBUG
                print("=== LICENSE VALIDATION PASSED — proceeding to activate ===")
                #endif

                // Phase 2: Activate the validated key
                isActivating = true
                try await LicenseManager.shared.activateLicense(key: cleanedKey)
                isActivating = false

                await MainActor.run {
                    onContinue()
                }
            } catch {
                #if DEBUG
                print("License error: \(error.localizedDescription)")
                #endif
                isValidating = false
                isActivating = false
                await MainActor.run {
                    errorMessage = formatError(error)
                    showError = true
                }
            }
        }
    }

    private func formatError(_ error: Error) -> String {
        if let licenseError = error as? LicenseError {
            return licenseError.localizedDescription
        }

        let message = error.localizedDescription

        if message.contains("404") || message.lowercased().contains("not found") {
            return "License not found. Please check your license key."
        } else if message.contains("401") || message.contains("403") {
            return "Unauthorized. Check your organization ID."
        } else if message.contains("400") {
            return "Invalid license key format."
        }

        return message
    }
}

#Preview {
    LicenseActivationView(onContinue: {})
        .frame(width: 500, height: 500)
        .background(.black.opacity(0.5))
}
