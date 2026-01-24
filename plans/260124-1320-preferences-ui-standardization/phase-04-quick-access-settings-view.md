# Phase 04: Update QuickAccessSettingsView

## Context
- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 01-03
- **Reference:** AdvancedSettingsView.swift

## Overview
- **Date:** 260124
- **Description:** Add icons to QuickAccessSettingsView
- **Priority:** Medium
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
- Position section has segmented picker
- Appearance section has slider
- Behaviors section has multiple toggles needing icons

## Requirements
1. Add settingRow helper
2. Add icons to Position section
3. Add icons to Appearance section
4. Add icons to all Behaviors toggles

## Architecture
Same settingRow helper pattern

## Related Code Files
- `ClaudeShot/Features/Preferences/Tabs/QuickAccessSettingsView.swift`

## Implementation Steps

### Step 1: Update Position Section
- Screen edge picker → icon: "rectangle.leadinghalf.inset.filled"

### Step 2: Update Appearance Section
- Overlay Size → icon: "arrow.up.left.and.arrow.down.right"

### Step 3: Update Behaviors Section
Icons for each toggle:
- Enable floating overlay → "square.on.square"
- Auto-close overlay → "timer"
- Enable drag & drop → "hand.draw"
- Show cloud upload → "cloud.fill"

## Todo List
- [ ] Add settingRow helper
- [ ] Update Position section with icon
- [ ] Update Appearance section with icon
- [ ] Update Behaviors section with icons
- [ ] Test build

## Success Criteria
- [ ] All settings have icons
- [ ] Slider still works
- [ ] Segmented picker unchanged
- [ ] No build errors

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Slider layout change | Low | Test slider functionality |

## Security Considerations
- No security impact

## Next Steps
Build and test all tabs
