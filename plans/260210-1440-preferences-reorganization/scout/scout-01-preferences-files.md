# Scout Report: Preferences-Related Files

**Date**: 2026-02-10 | **Scope**: All Preferences/Settings files in Snapzy

## 1. Core Preferences Files (`Features/Preferences/`)

| File | Description |
|------|-------------|
| `PreferencesView.swift` | Root TabView (6 tabs, 700x550 frame) |
| `PreferencesKeys.swift` | Centralized enum of all UserDefaults keys (~22 keys) |
| `PreferencesManager.swift` | AfterCaptureAction matrix state manager |

## 2. Tab Views (`Features/Preferences/Tabs/`)

| File | Tab | Sections |
|------|-----|----------|
| `GeneralSettingsView.swift` | General | Startup, Appearance, Storage, Capture, Post-Capture Actions, Help, Software Updates (7 sections) |
| `ShortcutsSettingsView.swift` | Shortcuts | Global toggle, Capture/Recording/Tools shortcuts, Annotation tool shortcuts |
| `QuickAccessSettingsView.swift` | Quick Access | Position, Appearance, Behaviors |
| `RecordingSettingsView.swift` | Recording | Format, Quality, Behavior, Audio, Save Location ("See General tab") |
| `AdvancedSettingsView.swift` | Advanced | Permissions status only (Screen Recording, Microphone, Accessibility) |
| `AboutSettingsView.swift` | About | App info, version, update check, resource links |
| `PlaceholderSettingsView.swift` | -- | Placeholder factory for future tabs (wallpaper, cloud) |

## 3. Components (`Features/Preferences/Components/`)

| File | Used By | Purpose |
|------|---------|---------|
| `AfterCaptureMatrixView.swift` | General tab | Matrix toggle for post-capture actions |
| `AppearanceThumbnailView.swift` | General tab | Visual light/dark/auto mode picker |
| `LoginItemManager.swift` | General tab | SMAppService wrapper for launch-at-login |
| `AboutFeatureCard.swift` | About tab | Feature highlight card |
| `AboutLinkCard.swift` | About tab | Clickable URL card |
| `AboutCreditRow.swift` | About tab | Credit/acknowledgment row |

## 4. Related Managers

| File | Referenced By |
|------|---------------|
| `Core/Theme/ThemeManager.swift` | PreferencesView, GeneralSettingsView, 5+ other files |
| `Features/QuickAccess/QuickAccessManager.swift` | QuickAccessSettingsView, StatusBarController |
| `Core/AnnotateShortcutManager.swift` | ShortcutsSettingsView |
| `Core/UpdaterManager.swift` | GeneralSettingsView, AboutSettingsView |
| `Core/ShortcutRecorderView.swift` | ShortcutsSettingsView |
| `Core/SingleKeyRecorderView.swift` | ShortcutsSettingsView |

## 5. Files Referencing PreferencesKeys (15 files)

- `GeneralSettingsView.swift` — playSounds, exportLocation, hideDesktopIcons, hideDesktopWidgets
- `RecordingSettingsView.swift` — recordingFormat, recordingFPS, recordingQuality, captureAudio, captureMicrophone, rememberLastArea
- `Core/Theme/ThemeManager.swift` — appearanceMode
- `Core/Services/DesktopIconManager.swift` — hideDesktopIcons, hideDesktopWidgets
- `Core/ScreenCaptureViewModel.swift` — multiple keys
- `Features/Recording/RecordingCoordinator.swift` — recording keys
- `Features/Recording/RecordingToolbarWindow.swift` — recording keys
- `Features/Recording/Annotation/RecordingAnnotationShortcutConfig.swift` — annotationShortcutModifier, annotationShortcutHoldDuration
- `Features/Onboarding/OnboardingFlowView.swift` — onboardingCompleted
- `Features/QuickAccess/QuickAccessCardView.swift`
- `Core/Services/PostCaptureActionHandler.swift`
- `App/SnapzyApp.swift`
- `PreferencesManager.swift`, `AfterCaptureMatrixView.swift`

## 6. Window/ Subfolder

Empty directory — no files.

## 7. Key Observation: Duplicated `settingRow` Helper

The private `settingRow(icon:title:description:content:)` method is copy-pasted across 4 tab files:
- GeneralSettingsView.swift
- RecordingSettingsView.swift
- QuickAccessSettingsView.swift
- ShortcutsSettingsView.swift

Should be extracted to shared component.

## Summary

- **16 total preference files** (3 root + 7 tabs + 6 components)
- **4 core managers** (PreferencesManager, ThemeManager, QuickAccessManager, AnnotateShortcutManager)
- **22 UserDefaults keys** in PreferencesKeys.swift
- **15 files** reference PreferencesKeys across the codebase
- **No migration needed** — pure UI reorganization, keys stay unchanged
