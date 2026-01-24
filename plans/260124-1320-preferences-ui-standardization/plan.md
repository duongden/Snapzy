# Preferences UI Standardization

## Overview
Standardize all Preferences tabs to match AdvancedSettingsView layout patterns for consistent UX.

**Created:** 260124
**Priority:** Medium
**Complexity:** Low

## Reference Pattern (AdvancedSettingsView)
```
┌──────────────────────────────────────────────────────────────────┐
│ 🎥 (28px) │ Title (.medium) + Desc (.caption) │ Spacer │ Control │
└──────────────────────────────────────────────────────────────────┘
```
- Icon: SF Symbol, .title2, .secondary, frame(width: 28)
- Title: .fontWeight(.medium)
- Description: .font(.caption).foregroundColor(.secondary)
- Row: HStack(spacing: 12), .padding(.vertical, 4)
- Buttons: .buttonStyle(.bordered).controlSize(.small)

## Implementation Phases

| Phase | Description | Status | Progress |
|-------|-------------|--------|----------|
| 01 | Update GeneralSettingsView | Pending | 0% |
| 02 | Update RecordingSettingsView | Pending | 0% |
| 03 | Update ShortcutsSettingsView | Pending | 0% |
| 04 | Update QuickAccessSettingsView | Pending | 0% |

## Files to Modify
- `ClaudeShot/Features/Preferences/Tabs/GeneralSettingsView.swift`
- `ClaudeShot/Features/Preferences/Tabs/RecordingSettingsView.swift`
- `ClaudeShot/Features/Preferences/Tabs/ShortcutsSettingsView.swift`
- `ClaudeShot/Features/Preferences/Tabs/QuickAccessSettingsView.swift`

## No Changes Required
- `AboutSettingsView.swift` - Hero layout intentional for About page

## Constraints
- DO NOT change Appearance picker to toggle
- DO NOT change radio groups to toggles
- Keep existing functionality intact
- Maintain Form + .formStyle(.grouped) pattern

## Phase Files
- [Phase 01: GeneralSettingsView](./phase-01-general-settings-view.md)
- [Phase 02: RecordingSettingsView](./phase-02-recording-settings-view.md)
- [Phase 03: ShortcutsSettingsView](./phase-03-shortcuts-settings-view.md)
- [Phase 04: QuickAccessSettingsView](./phase-04-quick-access-settings-view.md)

## Success Criteria
- [ ] All tabs use consistent icon + title + description row layout
- [ ] All buttons use .buttonStyle(.bordered).controlSize(.small)
- [ ] No functionality changes, only visual updates
- [ ] Build succeeds with no errors
