# Phase 01: Update GeneralSettingsView

## Context
- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** None
- **Reference:** AdvancedSettingsView.swift

## Overview
- **Date:** 260124
- **Description:** Add icons and improve row layout for GeneralSettingsView
- **Priority:** Medium
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
- Startup section has 2 toggles needing icons
- Storage section needs folder icon and improved layout
- Software Updates section needs icons for toggles
- Keep Appearance and Post-Capture Actions unchanged

## Requirements
1. Add settingRow helper function matching AdvancedSettingsView pattern
2. Update Startup section with icons
3. Update Storage section layout
4. Update Software Updates section with icons
5. Keep Appearance picker unchanged
6. Keep AfterCaptureMatrixView unchanged

## Architecture
```swift
private func settingRow(
  icon: String,
  title: String,
  description: String? = nil,
  content: () -> some View
) -> some View
```

## Related Code Files
- `ClaudeShot/Features/Preferences/Tabs/GeneralSettingsView.swift`
- `ClaudeShot/Features/Preferences/Tabs/AdvancedSettingsView.swift` (reference)

## Implementation Steps

### Step 1: Add settingRow helper
```swift
@ViewBuilder
private func settingRow<Content: View>(
  icon: String,
  title: String,
  description: String? = nil,
  @ViewBuilder content: () -> Content
) -> some View {
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
```

### Step 2: Update Startup Section
- "Start at login" → icon: "power.circle"
- "Play sounds" → icon: "speaker.wave.2"

### Step 3: Update Storage Section
- Add folder.fill icon
- Keep Choose button with .buttonStyle(.bordered).controlSize(.small)

### Step 4: Update Help Section
- "Restart Onboarding" → icon: "arrow.counterclockwise.circle"

### Step 5: Update Software Updates Section
- Auto check → icon: "arrow.triangle.2.circlepath"
- Auto download → icon: "arrow.down.circle"
- Last checked → icon: "clock"

## Todo List
- [ ] Add settingRow helper function
- [ ] Update Startup section toggles with icons
- [ ] Update Storage section with icon and improved layout
- [ ] Update Help section with icon
- [ ] Update Software Updates section with icons
- [ ] Test build

## Success Criteria
- [ ] All settings have icons
- [ ] Layout matches AdvancedSettingsView pattern
- [ ] Appearance picker unchanged
- [ ] AfterCaptureMatrixView unchanged
- [ ] No build errors

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Toggle layout changes | Low | Test toggle functionality |

## Security Considerations
- No security impact, UI-only changes

## Next Steps
Proceed to Phase 02: RecordingSettingsView
