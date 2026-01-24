# Phase 02: Update RecordingSettingsView

## Context
- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 01 (helper pattern)
- **Reference:** AdvancedSettingsView.swift

## Overview
- **Date:** 260124
- **Description:** Add icons to RecordingSettingsView sections
- **Priority:** Medium
- **Implementation Status:** Pending
- **Review Status:** Pending

## Key Insights
- Format section uses radio group - keep as is
- Quality section has pickers - add icons
- Audio section has toggles - add icons with descriptions
- Keep all existing functionality

## Requirements
1. Add settingRow helper (same pattern as Phase 01)
2. Add icons to Format section intro
3. Add icons to Quality pickers
4. Add icons to Audio toggles
5. Keep radio groups unchanged

## Architecture
Same settingRow helper pattern from Phase 01

## Related Code Files
- `ClaudeShot/Features/Preferences/Tabs/RecordingSettingsView.swift`

## Implementation Steps

### Step 1: Add settingRow helper
Same as Phase 01

### Step 2: Update Format Section
- Add intro text with film icon
- Keep Picker with .radioGroup style unchanged

### Step 3: Update Quality Section
- Frame Rate → icon: "gauge.with.dots.needle.33percent"
- Quality → icon: "sparkles"

### Step 4: Update Audio Section
- System Audio → icon: "speaker.wave.3.fill", desc: "Captures sounds from apps"
- Microphone → icon: "mic.fill", desc: "Captures your voice"

### Step 5: Update Save Location Section
- Add folder.fill icon to info row

## Todo List
- [ ] Add settingRow helper
- [ ] Update Format section
- [ ] Update Quality section with icons
- [ ] Update Audio section with icons and descriptions
- [ ] Update Save Location section
- [ ] Test build

## Success Criteria
- [ ] All settings have icons
- [ ] Radio groups unchanged
- [ ] Picker styles unchanged
- [ ] No build errors

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Radio picker layout | Low | Don't wrap in settingRow |

## Security Considerations
- No security impact

## Next Steps
Proceed to Phase 03: ShortcutsSettingsView
