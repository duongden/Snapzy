# Phase 03: Update ShortcutsSettingsView

## Context
- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 01-02
- **Reference:** AdvancedSettingsView.swift

## Overview
- **Date:** 260124
- **Description:** Minor polish to ShortcutsSettingsView
- **Priority:** Low
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
- Structure already good with ShortcutRecorderView
- Just needs icons for toggle and section polish
- Reset button already at bottom

## Requirements
1. Add icon to "Enable global keyboard shortcuts" toggle
2. Add section description text
3. Keep ShortcutRecorderView unchanged
4. Keep Reset button at bottom

## Architecture
Same settingRow helper pattern

## Related Code Files
- `ClaudeShot/Features/Preferences/Tabs/ShortcutsSettingsView.swift`

## Implementation Steps

### Step 1: Update Global Shortcuts Section
- Add keyboard icon to enable toggle
- Add intro description text

### Step 2: Update Capture Section
- Keep ShortcutRecorderView as-is (custom component)
- Optionally add command.square icons if fits layout

## Todo List
- [ ] Add icon to enable shortcuts toggle
- [ ] Add section description
- [ ] Verify ShortcutRecorderView unchanged
- [ ] Test build

## Success Criteria
- [ ] Enable toggle has icon
- [ ] ShortcutRecorderView works correctly
- [ ] Reset button functions
- [ ] No build errors

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| ShortcutRecorderView layout | Low | Don't modify custom component |

## Security Considerations
- No security impact

## Next Steps
Proceed to Phase 04: QuickAccessSettingsView
