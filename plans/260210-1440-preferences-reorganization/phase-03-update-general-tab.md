# Phase 3: Update General Tab

**Status:** Pending | **Depends on:** Phase 1 (SettingRow), Phase 2 (CaptureSettingsView exists) | **Blocks:** Phase 6

## Context

- [Scout report](./scout/scout-01-preferences-files.md) -- GeneralSettingsView has 7 sections (junk drawer)
- Current file: `Tabs/GeneralSettingsView.swift` (199 lines)
- Sections to REMOVE: "Capture" (lines 58-68), "Post-Capture Actions" (lines 70-72) -- moved to CaptureSettingsView in Phase 2

## Overview

Slim down GeneralSettingsView by removing the "Capture" and "Post-Capture Actions" sections that moved to the new Capture tab. Keep: Startup, Appearance, Storage, Help, Software Updates. Also replace private `settingRow` with shared `SettingRow` (Phase 1).

## Requirements

- Remove "Capture" section (hideDesktopIcons, hideDesktopWidgets toggles)
- Remove "Post-Capture Actions" section (AfterCaptureMatrixView)
- Remove corresponding `@AppStorage` properties: `hideDesktopIcons`, `hideDesktopWidgets`
- Keep all remaining sections intact: Startup, Appearance, Storage, Help, Software Updates
- Use shared `SettingRow` from Phase 1 (private `settingRow` already removed in Phase 1)
- Keep all helper methods: `exportLocationDisplay`, `initializeExportLocation`, `chooseExportLocation`, `restartOnboarding`

## Related Files

| File | Action |
|------|--------|
| `Tabs/GeneralSettingsView.swift` | MODIFY -- remove 2 sections and 2 `@AppStorage` properties |

## Implementation Steps

### Step 1: Remove `@AppStorage` properties for moved settings

Delete these two lines from the top of the struct:

```swift
// DELETE these lines:
@AppStorage(PreferencesKeys.hideDesktopIcons) private var hideDesktopIcons = false
@AppStorage(PreferencesKeys.hideDesktopWidgets) private var hideDesktopWidgets = false
```

### Step 2: Remove "Capture" section from Form body

Delete the entire "Capture" section block (currently lines 58-68):

```swift
// DELETE this entire section:
Section("Capture") {
  SettingRow(icon: "eye.slash", title: "Hide desktop icons", description: "Temporarily hide icons during capture") {
    Toggle("", isOn: $hideDesktopIcons)
      .labelsHidden()
  }

  SettingRow(icon: "widget.small", title: "Hide desktop widgets", description: "Temporarily hide widgets during capture") {
    Toggle("", isOn: $hideDesktopWidgets)
      .labelsHidden()
  }
}
```

### Step 3: Remove "Post-Capture Actions" section from Form body

Delete the entire "Post-Capture Actions" section (currently lines 70-72):

```swift
// DELETE this entire section:
Section("Post-Capture Actions") {
  AfterCaptureMatrixView()
}
```

### Step 4: Resulting file structure

After removals, GeneralSettingsView should contain exactly 5 sections in this order:

1. **Startup** -- Start at login toggle, Play sounds toggle
2. **Appearance** -- AppearanceModePicker
3. **Storage** -- Save location chooser
4. **Help** -- Restart onboarding button
5. **Software Updates** -- Check automatically, Download automatically, Last checked

### Step 5: Verify the file

- Estimated file size: ~140 lines (down from 199)
- All remaining `@AppStorage` bindings: `playSounds`, `exportLocation`
- All remaining state: `startAtLogin`
- All remaining helper methods: `exportLocationDisplay`, `initializeExportLocation`, `chooseExportLocation`, `restartOnboarding`
- Imports: `SwiftUI`, `Sparkle` (still needed for SPUUpdater)

## Todo List

- [ ] Remove `hideDesktopIcons` and `hideDesktopWidgets` `@AppStorage` properties
- [ ] Remove "Capture" section from Form body
- [ ] Remove "Post-Capture Actions" section from Form body
- [ ] Verify remaining 5 sections compile and render correctly
- [ ] Confirm file is under 200 lines

## Success Criteria

- GeneralSettingsView has exactly 5 sections: Startup, Appearance, Storage, Help, Software Updates
- No references to `hideDesktopIcons`, `hideDesktopWidgets`, or `AfterCaptureMatrixView` remain
- All remaining settings still bind to correct UserDefaults keys
- File compiles without warnings
