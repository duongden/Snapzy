# Phase 5: Simplify About Tab

**Status:** Pending | **Depends on:** Nothing (independent) | **Blocks:** Phase 6

## Context

- Current file: `Tabs/AboutSettingsView.swift` (205 lines)
- Currently contains: hero section (icon, name, version, update button), feature highlights (commented out), links section, credits section (commented out)

## Overview

The About tab is already fairly clean -- feature highlights and credits sections are commented out. Main task: ensure the tab contains ONLY app info (icon, name, version), update check button, and resource links. Remove any settings/preferences logic. The `lastUpdateCheckDate` display in the version badge is informational (not a setting), so it stays.

## Requirements

- Keep: hero section (app icon, name, version badge, "Check for Updates" button)
- Keep: links section (Website, Rate on GitHub, Report Issue)
- Remove: `featureHighlightsSection` computed property (currently commented out but still in code)
- Remove: `creditsSection` computed property (currently commented out but still in code)
- Remove: `AboutFeatureCard` references (component can stay in Components/ for potential future use)
- Remove: `AboutCreditRow` references (component can stay in Components/ for potential future use)
- No settings, no preferences, no toggles in this tab

## Related Files

| File | Action |
|------|--------|
| `Tabs/AboutSettingsView.swift` | MODIFY -- remove dead code (commented-out sections) |
| `Components/AboutFeatureCard.swift` | NO CHANGE -- keep file, just unused by About tab for now |
| `Components/AboutCreditRow.swift` | NO CHANGE -- keep file, just unused by About tab for now |

## Implementation Steps

### Step 1: Remove `featureHighlightsSection` computed property

Delete the entire `featureHighlightsSection` computed property (lines 104-138 in current file):

```swift
// DELETE this entire computed property:
private var featureHighlightsSection: some View {
  VStack(alignment: .leading, spacing: Spacing.md) {
    sectionHeader("Highlights")
    LazyVGrid(columns: [...]) {
      AboutFeatureCard(...)
      // ... all 4 cards
    }
  }
}
```

### Step 2: Remove `creditsSection` computed property

Delete the entire `creditsSection` computed property (lines 171-190):

```swift
// DELETE this entire computed property:
private var creditsSection: some View {
  VStack(alignment: .leading, spacing: Spacing.md) {
    sectionHeader("Acknowledgments")
    VStack(spacing: Spacing.sm) {
      AboutCreditRow(...)
      // ...
    }
    Text("(c) 2024-2025 ...")
  }
}
```

### Step 3: Clean up body references

Remove the commented-out references in `body`:

```swift
// Before:
VStack(spacing: Spacing.lg) {
  heroSection
  // featureHighlightsSection
  linksSection
  // creditsSection
}

// After:
VStack(spacing: Spacing.lg) {
  heroSection
  linksSection
}
```

### Step 4: Verify remaining structure

After cleanup, the file should contain:
- `appVersion` computed property
- `updater` property (for "Check for Updates" button only)
- `body` -- ScrollView with heroSection + linksSection
- `heroSection` -- app icon, name, version badge, update button
- `linksSection` -- resource link cards
- `sectionHeader` helper

Estimated file size: ~100 lines (down from 205).

## Todo List

- [ ] Remove `featureHighlightsSection` computed property
- [ ] Remove `creditsSection` computed property
- [ ] Remove commented-out references in body
- [ ] Verify remaining structure compiles
- [ ] Confirm file is under 200 lines

## Success Criteria

- AboutSettingsView contains only: hero section + links section
- No dead/commented-out code remains
- "Check for Updates" button still works
- Resource links still open in browser
- No settings toggles or preferences exist in this tab
- File is clean and under ~110 lines
