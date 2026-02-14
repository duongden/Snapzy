//
//  SnapzyApp.swift
//  Snapzy
//
//  Main app entry point - Menu Bar App
//

import SwiftUI
import Sparkle

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

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Setup status bar with dependencies (uses shared UpdaterManager)
    StatusBarController.shared.setup(
      viewModel: viewModel,
      updater: UpdaterManager.shared.updater
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
  }

  @objc private func handleShowOnboarding() {
    SplashWindowController.shared.show(forceOnboarding: true)
  }

  @objc private func handleLicenseInvalidated() {
    SplashWindowController.shared.showLicenseActivation()
  }
}
