//
//  ThemeManager.swift
//  ZapShot
//
//  Centralized theme state management for SwiftUI and AppKit
//

import AppKit
import Combine
import SwiftUI

/// Manages app-wide appearance/theme state
@MainActor
final class ThemeManager: ObservableObject {

  static let shared = ThemeManager()

  /// User's preferred appearance mode, persisted to UserDefaults
  @AppStorage(PreferencesKeys.appearanceMode)
  var preferredAppearance: AppearanceMode = .system {
    didSet {
      objectWillChange.send()
    }
  }

  private init() {}

  // MARK: - SwiftUI

  /// ColorScheme for SwiftUI's .preferredColorScheme() modifier
  /// Returns nil to follow system appearance
  var systemAppearance: ColorScheme? {
    switch preferredAppearance {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }

  // MARK: - AppKit

  /// NSAppearance for NSWindow.appearance property
  /// Returns nil to follow system appearance
  var nsAppearance: NSAppearance? {
    switch preferredAppearance {
    case .system: return nil
    case .light: return NSAppearance(named: .aqua)
    case .dark: return NSAppearance(named: .darkAqua)
    }
  }
}
