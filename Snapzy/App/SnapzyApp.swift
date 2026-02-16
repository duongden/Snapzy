//
//  SnapzyApp.swift
//  Snapzy
//
//  Main app entry point - Menu Bar App
//

import SwiftUI
import Sparkle
import Combine

// MARK: - Notification Names

extension Notification.Name {
  static let showOnboarding = Notification.Name("showOnboarding")
}

@main
struct SnapzyApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @ObservedObject private var themeManager = ThemeManager.shared

  var body: some Scene {
    // Settings Window
    Settings {
      PreferencesView()
        .preferredColorScheme(themeManager.systemAppearance)
    }
  }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
  private let viewModel = ScreenCaptureViewModel()
  private var cancellables = Set<AnyCancellable>()

  func applicationDidFinishLaunching(_ notification: Notification) {
    // --- Diagnostics: crash detection & logging ---
    let didCrash = CrashSentinel.shared.checkAndReset()
    DiagnosticLogger.shared.startSession()
    LogCleanupScheduler.shared.start()

    // Setup status bar with dependencies (uses shared UpdaterManager)
    StatusBarController.shared.setup(
      viewModel: viewModel,
      updater: UpdaterManager.shared.updater,
      didCrash: didCrash && DiagnosticLogger.shared.isEnabled
    )

    // Show splash (handles onboarding internally if needed)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      SplashWindowController.shared.show()
    }



    // Listen for restart onboarding notification
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleShowOnboarding),
      name: .showOnboarding,
      object: nil
    )

    // Force license screen when license is invalidated (revoked/disabled/tampered)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleLicenseInvalidated),
      name: .licenseInvalidated,
      object: nil
    )

    // Observe invalid license alert from startup validation
    observeInvalidLicenseAlert()
  }

  func applicationWillTerminate(_ notification: Notification) {
    DiagnosticLogger.shared.log(.info, .lifecycle, "App terminated normally")
    CrashSentinel.shared.markTerminated()
    LogCleanupScheduler.shared.stop()
  }

  @objc private func handleShowOnboarding() {
    SplashWindowController.shared.show(forceOnboarding: true)
  }

  @objc private func handleLicenseInvalidated() {
    SplashWindowController.shared.showLicenseActivation()
  }



  // MARK: - Invalid License Confirmation

  private func observeInvalidLicenseAlert() {
    LicenseManager.shared.$showInvalidLicenseAlert
      .removeDuplicates()
      .filter { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.showInvalidLicenseConfirmation()
      }
      .store(in: &cancellables)
  }

  private func showInvalidLicenseConfirmation() {
    let licenseManager = LicenseManager.shared

    let alert = NSAlert()
    alert.messageText = "License Invalid"
    alert.informativeText = "\(licenseManager.invalidLicenseMessage)\n\nYou can clear the license and activate a new one, or quit the app."
    alert.alertStyle = .critical
    alert.addButton(withTitle: "Reactivate License")
    alert.addButton(withTitle: "Quit App")

    let response = alert.runModal()

    switch response {
    case .alertFirstButtonReturn:
      licenseManager.confirmClearInvalidLicense()
    case .alertSecondButtonReturn:
      licenseManager.confirmQuitApp()
    default:
      break
    }
  }
}
