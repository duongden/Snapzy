//
//  PreferencesView.swift
//  Snapzy
//
//  Root preferences window with tabbed interface
//

import SwiftUI

struct PreferencesView: View {
  @ObservedObject private var themeManager = ThemeManager.shared
  @ObservedObject private var navigationState = PreferencesNavigationState.shared

  var body: some View {
    TabView(selection: $navigationState.selectedTab) {
      LazyView(GeneralSettingsView())
        .tabItem { Label("General", systemImage: "gearshape.fill") }
        .tag(PreferencesTab.general)

      LazyView(CaptureSettingsView())
        .tabItem { Label("Capture", systemImage: "camera.fill") }
        .tag(PreferencesTab.capture)

      LazyView(QuickAccessSettingsView())
        .tabItem { Label("Quick Access", systemImage: "square.stack.fill") }
        .tag(PreferencesTab.quickAccess)

      LazyView(ShortcutsSettingsView())
        .tabItem { Label("Shortcuts", systemImage: "keyboard.fill") }
        .tag(PreferencesTab.shortcuts)

      LazyView(PermissionsSettingsView())
        .tabItem { Label("Permissions", systemImage: "lock.shield.fill") }
        .tag(PreferencesTab.permissions)

      LazyView(CloudSettingsView())
        .tabItem { Label("Cloud", systemImage: "icloud.fill") }
        .tag(PreferencesTab.cloud)

      LazyView(AboutSettingsView())
        .tabItem { Label("About", systemImage: "info.circle.fill") }
        .tag(PreferencesTab.about)
    }
    .frame(width: 700, height: 550)
  }
}

#Preview {
  PreferencesView()
}
