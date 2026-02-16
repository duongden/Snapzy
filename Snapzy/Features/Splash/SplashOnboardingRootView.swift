//
//  SplashOnboardingRootView.swift
//  Snapzy
//
//  Unified coordinator managing splash intro → onboarding flow within the same window
//

import SwiftUI

// MARK: - Screen Enum

enum SplashScreen: Equatable {
  case splash
  case permissions
  case diagnostics
  case shortcuts
  case skipConfirmation
  case completion
}

// MARK: - Navigation Direction

private enum NavigationDirection {
  case forward, backward
}

// MARK: - SplashOnboardingRootView

struct SplashOnboardingRootView: View {
  let needsOnboarding: Bool
  let onDismiss: () -> Void

  @State private var currentScreen: SplashScreen = .splash
  @State private var contentOpacity: Double = 1
  @State private var navigationDirection: NavigationDirection = .forward
  @ObservedObject private var screenCaptureManager = ScreenCaptureManager.shared

  // Onboarding steps (excluding splash)
  private static let onboardingSteps: [SplashScreen] = [.permissions, .diagnostics, .shortcuts, .completion]

  private var isOnboardingStep: Bool {
    currentScreen != .splash
  }

  private var currentStepIndex: Int {
    Self.onboardingSteps.firstIndex(of: currentScreen) ?? 0
  }

  private var showSkipButton: Bool {
    currentScreen == .shortcuts
  }

  var body: some View {
    ZStack {
      Color.clear

      Group {
        switch currentScreen {
        case .splash:
          SplashContentView(onContinue: handleSplashContinue)
            .transition(.opacity)

        case .permissions:
          PermissionsView(
            screenCaptureManager: screenCaptureManager,
            onQuit: { NSApplication.shared.terminate(nil) },
            onNext: { navigateForward(to: .diagnostics) }
          )
          .transition(stepTransition)

        case .diagnostics:
          DiagnosticsOptInView(
            onBack: { navigateBack(to: .permissions) },
            onNext: { navigateForward(to: .shortcuts) }
          )
          .transition(stepTransition)

        case .shortcuts:
          ShortcutsView(
            onBack: { navigateBack(to: .diagnostics) },
            onDecline: { navigateForward(to: .completion) },
            onAccept: {
              KeyboardShortcutManager.shared.enable()
              navigateForward(to: .completion)
            }
          )
          .transition(stepTransition)

        case .skipConfirmation:
          SkipConfirmationView(
            onGoBack: { navigateBack(to: .shortcuts) },
            onConfirmSkip: { handleComplete() }
          )
          .transition(stepTransition)

        case .completion:
          CompletionView(
            onBack: { navigateBack(to: .shortcuts) },
            onComplete: handleComplete
          )
          .transition(stepTransition)
        }
      }
      .opacity(contentOpacity)

      // Skip button — top-right, only on shortcuts step (after permissions passed)
      if showSkipButton {
        VStack {
          HStack {
            Spacer()
            Button("Skip") {
              navigateForward(to: .skipConfirmation)
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
              Capsule().fill(Color.white.opacity(0.1))
            )
            .overlay(
              Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .contentShape(Capsule())
            .onHover { hovering in
              if hovering {
                NSCursor.pointingHand.push()
              } else {
                NSCursor.pop()
              }
            }
          }
          .padding(.top, 48)
          .padding(.trailing, 32)
          Spacer()
        }
        .opacity(contentOpacity)
        .transition(.opacity)
      }

      // Page dots — bottom center, only during onboarding steps
      if isOnboardingStep && currentScreen != .skipConfirmation {
        VStack {
          Spacer()
          HStack(spacing: 8) {
            ForEach(0..<Self.onboardingSteps.count, id: \.self) { index in
              Circle()
                .fill(index == currentStepIndex ? Color.white : Color.white.opacity(0.3))
                .frame(width: 7, height: 7)
                .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
            }
          }
          .padding(.bottom, 32)
        }
        .opacity(contentOpacity)
        .transition(.opacity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Transitions

  private var stepTransition: AnyTransition {
    switch navigationDirection {
    case .forward:
      return .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
      )
    case .backward:
      return .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
      )
    }
  }

  // MARK: - Navigation

  private func handleSplashContinue() {
    if needsOnboarding {
      navigateForward(to: .permissions)
    } else {
      // No onboarding needed — fade out and dismiss
      withAnimation(.easeIn(duration: 0.3)) {
        contentOpacity = 0
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        onDismiss()
      }
    }
  }

  private func navigateForward(to screen: SplashScreen) {
    navigationDirection = .forward
    withAnimation(.easeInOut(duration: 0.4)) {
      currentScreen = screen
    }
  }

  private func navigateBack(to screen: SplashScreen) {
    navigationDirection = .backward
    withAnimation(.easeInOut(duration: 0.4)) {
      currentScreen = screen
    }
  }

  private func handleComplete() {
    // Mark onboarding as completed
    UserDefaults.standard.set(true, forKey: PreferencesKeys.onboardingCompleted)

    // Fade out content, then dismiss window
    withAnimation(.easeIn(duration: 0.3)) {
      contentOpacity = 0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      onDismiss()
    }
  }
}

#Preview {
  SplashOnboardingRootView(needsOnboarding: true, onDismiss: {})
    .frame(width: 800, height: 600)
    .background(.black.opacity(0.5))
}
