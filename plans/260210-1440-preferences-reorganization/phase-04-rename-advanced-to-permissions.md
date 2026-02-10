# Phase 4: Rename Advanced to Permissions

**Status:** Pending | **Depends on:** Nothing (independent) | **Blocks:** Phase 6

## Context

- [Scout report](./scout/scout-01-preferences-files.md) -- "Advanced" tab only contains permissions status (misleading name)
- [UX research](./research/researcher-01-macos-preferences-ux.md) -- Anti-pattern: technical terminology that doesn't match content
- Current file: `Tabs/AdvancedSettingsView.swift` (205 lines)

## Overview

Rename `AdvancedSettingsView` to `PermissionsSettingsView`. The tab currently only shows permissions status (Screen Recording, Microphone, Accessibility) -- the name "Advanced" is misleading. Content stays identical; only the struct name and file name change.

## Requirements

- Rename file: `AdvancedSettingsView.swift` -> `PermissionsSettingsView.swift`
- Rename struct: `AdvancedSettingsView` -> `PermissionsSettingsView`
- Update file header comment
- Content stays 100% identical -- no logic changes
- Tab icon will change to `lock.shield` in Phase 6 (PreferencesView update)

## Related Files

| File | Action |
|------|--------|
| `Tabs/AdvancedSettingsView.swift` | RENAME to `Tabs/PermissionsSettingsView.swift` + rename struct |
| `PreferencesView.swift` | Updated in Phase 6 to reference new name |

## Implementation Steps

### Step 1: Rename file via Xcode

Use Xcode's Refactor > Rename to rename `AdvancedSettingsView` to `PermissionsSettingsView`. This updates:
- The struct name
- The file name
- The Preview struct reference

Alternatively, do it manually:

### Step 2 (manual alternative): Rename file

```bash
mv Snapzy/Features/Preferences/Tabs/AdvancedSettingsView.swift \
   Snapzy/Features/Preferences/Tabs/PermissionsSettingsView.swift
```

### Step 3 (manual alternative): Update file contents

In `PermissionsSettingsView.swift`, make these changes:

1. Update file header comment:
```swift
// Before:
//  AdvancedSettingsView.swift
//  Advanced preferences tab with permissions status and system settings links

// After:
//  PermissionsSettingsView.swift
//  Permissions preferences tab with system permissions status and settings links
```

2. Rename struct:
```swift
// Before:
struct AdvancedSettingsView: View {

// After:
struct PermissionsSettingsView: View {
```

3. Update Preview:
```swift
// Before:
#Preview {
  AdvancedSettingsView()
    .frame(width: 600, height: 400)
}

// After:
#Preview {
  PermissionsSettingsView()
    .frame(width: 600, height: 400)
}
```

### Step 4: Update Xcode project file

If renamed manually (not via Xcode Refactor), update the file reference in `Snapzy.xcodeproj/project.pbxproj` to point to the new filename. Xcode Refactor handles this automatically.

### Step 5: Build and verify

Ensure no compilation errors from the rename. The tab won't appear yet until Phase 6 updates PreferencesView.

## Todo List

- [ ] Rename `AdvancedSettingsView.swift` to `PermissionsSettingsView.swift`
- [ ] Rename struct `AdvancedSettingsView` to `PermissionsSettingsView`
- [ ] Update file header comment
- [ ] Update `#Preview` block
- [ ] Verify Xcode project references are correct
- [ ] Build succeeds

## Success Criteria

- File named `PermissionsSettingsView.swift` exists in `Tabs/`
- Struct named `PermissionsSettingsView` compiles
- No file named `AdvancedSettingsView.swift` remains
- Content (permissions checking, UI, system settings links) is 100% identical
- No references to `AdvancedSettingsView` remain in codebase
