# Phase 1: Extract Shared Components

**Status:** Pending | **Depends on:** Nothing | **Blocks:** Phases 2-6

## Context

- [Scout report](./scout/scout-01-preferences-files.md) -- identifies `settingRow` duplicated across 4 files
- [SwiftUI research](./research/researcher-02-swiftui-tab-reorganization.md) -- shared component extraction patterns (Section 5)

## Overview

The private `settingRow(icon:title:description:content:)` method is copy-pasted identically in 4 tab files. Extract into a shared `SettingRow` view in `Components/` before reorganizing tabs, so all subsequent phases use the shared version.

## Requirements

- Extract `settingRow` helper to `Components/SettingRow.swift` as a public struct
- Signature: `SettingRow<Content: View>(icon: String, title: String, description: String?, @ViewBuilder content: () -> Content)`
- Visual output must be pixel-identical to current private method
- Replace all 4 private copies with the shared struct

## Related Files

| File | Action |
|------|--------|
| `Components/SettingRow.swift` | CREATE -- new shared component |
| `Tabs/GeneralSettingsView.swift` | MODIFY -- remove private `settingRow`, use `SettingRow` |
| `Tabs/RecordingSettingsView.swift` | MODIFY -- remove private `settingRow`, use `SettingRow` |
| `Tabs/QuickAccessSettingsView.swift` | MODIFY -- remove private `settingRow`, use `SettingRow` |
| `Tabs/ShortcutsSettingsView.swift` | MODIFY -- remove private `settingRow`, use `SettingRow` |

## Implementation Steps

### Step 1: Create `Components/SettingRow.swift`

Create new file at `Snapzy/Features/Preferences/Components/SettingRow.swift`:

```swift
//
//  SettingRow.swift
//  Snapzy
//
//  Shared setting row component used across all preference tabs
//

import SwiftUI

struct SettingRow<Content: View>: View {
  let icon: String
  let title: String
  let description: String?
  @ViewBuilder let content: () -> Content

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.secondary)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .fontWeight(.medium)
        if let description {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()
      content()
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  Form {
    SettingRow(icon: "gear", title: "Example Setting", description: "A description") {
      Toggle("", isOn: .constant(true))
        .labelsHidden()
    }
  }
  .formStyle(.grouped)
  .frame(width: 500)
}
```

### Step 2: Update GeneralSettingsView.swift

1. Delete the `// MARK: - Setting Row Helper` section (lines 121-150 in current file)
2. Replace all `settingRow(` calls with `SettingRow(`

Example change:
```swift
// Before
settingRow(icon: "power.circle", title: "Start at login", description: "Launch Snapzy when you log in") {

// After
SettingRow(icon: "power.circle", title: "Start at login", description: "Launch Snapzy when you log in") {
```

### Step 3: Update RecordingSettingsView.swift

1. Delete the `// MARK: - Setting Row Helper` section (lines 113-142)
2. Replace all `settingRow(` calls with `SettingRow(`

### Step 4: Update QuickAccessSettingsView.swift

1. Delete the private `settingRow` method
2. Replace all `settingRow(` calls with `SettingRow(`

### Step 5: Update ShortcutsSettingsView.swift

1. Delete the private `settingRow` method
2. Replace all `settingRow(` calls with `SettingRow(`

### Step 6: Verify compilation

Build and run. All 4 tabs should render identically to before.

## Todo List

- [ ] Create `Components/SettingRow.swift` with extracted view struct
- [ ] Remove private `settingRow` from `GeneralSettingsView.swift`, replace calls
- [ ] Remove private `settingRow` from `RecordingSettingsView.swift`, replace calls
- [ ] Remove private `settingRow` from `QuickAccessSettingsView.swift`, replace calls
- [ ] Remove private `settingRow` from `ShortcutsSettingsView.swift`, replace calls
- [ ] Build and verify all tabs render correctly

## Success Criteria

- `SettingRow.swift` exists in `Components/`
- No private `settingRow` methods remain in any tab file
- All 4 tabs compile and render identically to current state
- Each tab file is shorter by ~20 lines (the removed helper)
