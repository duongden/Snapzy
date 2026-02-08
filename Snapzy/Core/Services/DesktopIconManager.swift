//
//  DesktopIconManager.swift
//  Snapzy
//
//  Provides Finder app reference for ScreenCaptureKit-based desktop icon exclusion.
//  Instead of killing/restarting Finder (slow, ~3-5s), we exclude Finder from
//  SCContentFilter at capture time, but keep open Finder windows visible via
//  exceptingWindows. Wallpaper is preserved because it's rendered by
//  Dock/WallpaperAgent, not Finder.
//

import Foundation
import ScreenCaptureKit

@MainActor
final class DesktopIconManager {
  static let shared = DesktopIconManager()

  private init() {}

  /// Whether the user has enabled desktop icon hiding in preferences
  var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: PreferencesKeys.hideDesktopIcons)
  }

  /// Get Finder as SCRunningApplication for exclusion from capture filters.
  func getFinderApps(from content: SCShareableContent) -> [SCRunningApplication] {
    content.applications.filter { $0.bundleIdentifier == "com.apple.finder" }
  }

  /// Get visible Finder windows (non-desktop) to keep in capture via exceptingWindows.
  /// Desktop icon windows have windowLayer > 0; regular Finder windows have windowLayer == 0.
  func getVisibleFinderWindows(from content: SCShareableContent) -> [SCWindow] {
    content.windows.filter { window in
      window.owningApplication?.bundleIdentifier == "com.apple.finder"
        && window.windowLayer == 0
        && window.isOnScreen
    }
  }
}
