//
//  PreferencesView.swift
//  Snapzy
//
//  Root preferences window with tabbed interface
//

import SwiftUI

struct PreferencesView: View {
  @ObservedObject private var themeManager = ThemeManager.shared

  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem { Label("General", systemImage: "gear") }

      CaptureSettingsView()
        .tabItem { Label("Capture", systemImage: "camera.viewfinder") }

      QuickAccessSettingsView()
        .tabItem { Label("Quick Access", systemImage: "square.stack") }

      ShortcutsSettingsView()
        .tabItem { Label("Shortcuts", systemImage: "keyboard") }

      PermissionsSettingsView()
        .tabItem { Label("Permissions", systemImage: "lock.shield") }

      AboutSettingsView()
        .tabItem { Label("About", systemImage: "info.circle") }

      #if DEBUG
      LicenseDebugSettingsView()
        .tabItem { Label("License", systemImage: "ant.fill") }
      #endif
    }
    .frame(width: 700, height: 550)
  }
}

#Preview {
  PreferencesView()
}
