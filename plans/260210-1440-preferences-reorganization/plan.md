# Preferences Reorganization Plan

**Date:** 2026-02-10 | **Status:** Planning
**Scope:** Reorganize 6 Preferences tabs from junk-drawer layout to task-oriented structure

## Goal

Move settings between tabs so each tab has a clear, focused purpose. Pure UI reorganization -- no UserDefaults key changes, no data migration.

## Target Tab Structure

| # | Tab | Icon | Content |
|---|------|------|---------|
| 1 | General | `gear` | Startup, Appearance, Storage, Updates, Help |
| 2 | Capture | `camera.viewfinder` | Screenshot behavior, Recording settings, After-capture actions |
| 3 | Quick Access | `square.stack` | Unchanged |
| 4 | Shortcuts | `keyboard` | Unchanged |
| 5 | Permissions | `lock.shield` | Renamed from Advanced -- same permissions content |
| 6 | About | `info.circle` | App info, version, update button, resource links only |

## Phases

| Phase | File | Status | Description |
|-------|------|--------|-------------|
| 1 | [phase-01](./phase-01-extract-shared-components.md) | Pending | Extract duplicated `settingRow` into shared `SettingRow.swift` |
| 2 | [phase-02](./phase-02-create-capture-tab.md) | Pending | Create `CaptureSettingsView.swift` (screenshot + recording + after-capture) |
| 3 | [phase-03](./phase-03-update-general-tab.md) | Pending | Slim down GeneralSettingsView (remove Capture, Post-Capture sections) |
| 4 | [phase-04](./phase-04-rename-advanced-to-permissions.md) | Pending | Rename AdvancedSettingsView to PermissionsSettingsView |
| 5 | [phase-05](./phase-05-simplify-about-tab.md) | Pending | Strip About tab to app info only |
| 6 | [phase-06](./phase-06-update-preferences-view.md) | Pending | Update PreferencesView TabView, delete dead files |

## Key Constraints

- NO UserDefaults key changes -- keys in `PreferencesKeys.swift` stay identical
- No migration needed -- just moving SwiftUI views between files
- All `@AppStorage` bindings use same keys, just in different tab files
- Shared `settingRow` helper extracted first (Phase 1) so subsequent phases use it

## Files Involved

**Base path:** `Snapzy/Features/Preferences/`

| Action | File |
|--------|------|
| NEW | `Components/SettingRow.swift` |
| NEW | `Tabs/CaptureSettingsView.swift` |
| MODIFY | `Tabs/GeneralSettingsView.swift` |
| RENAME | `Tabs/AdvancedSettingsView.swift` -> `Tabs/PermissionsSettingsView.swift` |
| MODIFY | `Tabs/AboutSettingsView.swift` |
| MODIFY | `PreferencesView.swift` |
| DELETE | `Tabs/RecordingSettingsView.swift` |
| DELETE | `Tabs/PlaceholderSettingsView.swift` |

## Risk Assessment

- **Low risk**: No logic changes, no key changes, no new dependencies
- **Testing**: Visual verification only -- ensure all settings appear in correct tab and toggles still bind to same keys
