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
      LazyView(GeneralSettingsView())
        .tabItem { Label("General", systemImage: "gearshape.fill") }

      LazyView(CaptureSettingsView())
        .tabItem { Label("Capture", systemImage: "camera.fill") }

      LazyView(QuickAccessSettingsView())
        .tabItem { Label("Quick Access", systemImage: "square.stack.fill") }

      LazyView(ShortcutsSettingsView())
        .tabItem { Label("Shortcuts", systemImage: "keyboard.fill") }

      LazyView(PermissionsSettingsView())
        .tabItem { Label("Permissions", systemImage: "lock.shield.fill") }

      LazyView(CloudSettingsView())
        .tabItem { Label("Cloud", systemImage: "icloud.fill") }

      LazyView(AboutSettingsView())
        .tabItem { Label("About", systemImage: "info.circle.fill") }
    }
    .frame(width: 700, height: 550)
  }
}

#Preview {
  PreferencesView()
}
