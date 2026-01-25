//
//  ClaudeShotApp.swift
//  ClaudeShot
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
struct ClaudeShotApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State private var showOnboarding = !OnboardingFlowView.hasCompletedOnboarding
  @ObservedObject private var themeManager = ThemeManager.shared

  var body: some Scene {
    // Onboarding Window (shown only when needed)
    WindowGroup(id: "onboarding") {
      OnboardingFlowView(onComplete: {
        showOnboarding = false
        // Close onboarding window
        NSApp.windows
          .filter { $0.identifier?.rawValue.contains("onboarding") == true }
          .forEach { $0.close() }
      })
      .frame(width: 700, height: 600)
      .preferredColorScheme(themeManager.systemAppearance)
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .defaultSize(width: 500, height: 450)

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
  private var updaterController: SPUStandardUpdaterController!

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Initialize Sparkle updater
    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )

    // Setup status bar with dependencies
    StatusBarController.shared.setup(
      viewModel: viewModel,
      updater: updaterController.updater
    )

    // Show onboarding on first launch
    if !OnboardingFlowView.hasCompletedOnboarding {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.showOnboardingWindow()
      }
    }

    // Listen for restart onboarding notification
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleShowOnboarding),
      name: .showOnboarding,
      object: nil
    )
  }

  @objc private func handleShowOnboarding() {
    showOnboardingWindow()
  }

  private func showOnboardingWindow() {
    NSApp.activate(ignoringOtherApps: true)
    for window in NSApp.windows {
      if window.identifier?.rawValue.contains("onboarding") == true {
        window.makeKeyAndOrderFront(nil)
        window.center()
        return
      }
    }
    // If onboarding window not found, open it via OpenWindow environment
//    if let url = URL(string: "zapshot://onboarding") {
//      NSWorkspace.shared.open(url)
//    }
  }
}

