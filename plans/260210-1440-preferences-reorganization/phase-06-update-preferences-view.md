# Phase 6: Update PreferencesView

**Status:** Pending | **Depends on:** Phases 1-5 (all) | **Blocks:** Nothing (final phase)

## Context

- Current file: `PreferencesView.swift` (46 lines)
- Current tab order: General, Shortcuts, Quick Access, Recording, Advanced, About
- Target tab order: General, Capture, Quick Access, Shortcuts, Permissions, About

## Overview

Final phase -- wire everything together. Update PreferencesView.swift TabView to reference the new/renamed views, set new tab order and icons. Delete obsolete files (RecordingSettingsView.swift, PlaceholderSettingsView.swift).

## Requirements

- Update TabView with new tab order and new view references
- New icons: Capture (`camera.viewfinder`), Permissions (`lock.shield`)
- Reference `CaptureSettingsView` (new, Phase 2)
- Reference `PermissionsSettingsView` (renamed, Phase 4)
- Remove `RecordingSettingsView` reference
- Remove `AdvancedSettingsView` reference
- Delete `RecordingSettingsView.swift` file
- Delete `PlaceholderSettingsView.swift` file (unused, all entries commented out)
- Remove commented-out Wallpaper and Cloud placeholder references

## Related Files

| File | Action |
|------|--------|
| `PreferencesView.swift` | MODIFY -- update TabView |
| `Tabs/RecordingSettingsView.swift` | DELETE -- contents moved to CaptureSettingsView |
| `Tabs/PlaceholderSettingsView.swift` | DELETE -- unused placeholder factory |

## Implementation Steps

### Step 1: Update PreferencesView.swift

Replace the TabView contents with the new tab structure:

```swift
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
    }
    .frame(width: 700, height: 550)
  }
}

#Preview {
  PreferencesView()
}
```

Key changes from current:
- `RecordingSettingsView()` replaced by `CaptureSettingsView()`
- `AdvancedSettingsView()` replaced by `PermissionsSettingsView()`
- Tab order changed: Capture moved to #2, Shortcuts moved to #4
- Icons updated: `camera.viewfinder` for Capture, `lock.shield` for Permissions
- Commented-out Wallpaper/Cloud placeholders removed

### Step 2: Delete RecordingSettingsView.swift

```bash
git rm Snapzy/Features/Preferences/Tabs/RecordingSettingsView.swift
```

Contents fully absorbed into `CaptureSettingsView.swift` (Phase 2). No references remain.

### Step 3: Delete PlaceholderSettingsView.swift

```bash
git rm Snapzy/Features/Preferences/Tabs/PlaceholderSettingsView.swift
```

All placeholder entries were commented out in PreferencesView. No longer needed.

### Step 4: Update Xcode project file

If files were deleted via `git rm` instead of Xcode, remove the file references from `Snapzy.xcodeproj/project.pbxproj`. Using Xcode's "Delete > Move to Trash" handles this automatically.

### Step 5: Full build and verification

1. Build the project -- zero errors expected
2. Open Preferences window -- verify 6 tabs appear in correct order
3. Verify each tab:
   - **General**: Startup, Appearance, Storage, Help, Software Updates
   - **Capture**: Screenshot Behavior, Recording, Audio, After Capture
   - **Quick Access**: unchanged
   - **Shortcuts**: unchanged
   - **Permissions**: Screen Recording, Microphone, Accessibility status
   - **About**: App icon, name, version, update button, resource links
4. Toggle settings in Capture tab -- verify they persist (same UserDefaults keys)
5. Verify no "See General tab" cross-references remain anywhere

## Todo List

- [ ] Update `PreferencesView.swift` with new TabView structure
- [ ] Delete `RecordingSettingsView.swift`
- [ ] Delete `PlaceholderSettingsView.swift`
- [ ] Update Xcode project references
- [ ] Full build -- zero errors
- [ ] Visual verification of all 6 tabs
- [ ] Verify settings persistence across app restart

## Success Criteria

- PreferencesView shows 6 tabs in order: General, Capture, Quick Access, Shortcuts, Permissions, About
- Each tab icon matches spec: `gear`, `camera.viewfinder`, `square.stack`, `keyboard`, `lock.shield`, `info.circle`
- No deleted files remain in project
- No compilation errors or warnings
- All settings persist correctly (same UserDefaults keys)
- No cross-tab references ("See General tab" etc.)
- Window frame unchanged (700x550)
