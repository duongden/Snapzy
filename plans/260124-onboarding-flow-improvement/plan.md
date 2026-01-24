# Onboarding Flow Improvement Plan

**Date:** 2026-01-24
**Status:** Draft
**Complexity:** Medium

---

## Current State Analysis

### Existing Flow Structure
```
WelcomeView → PermissionsView → ShortcutsView → Complete
```

### Current Issues Identified

1. **Branding inconsistency** - Uses generic SF Symbol (`camera.viewfinder`) instead of actual app icon
2. **Limited permissions** - Only requests Screen Recording; missing Microphone and Accessibility
3. **No completion step** - Flow ends abruptly without "Ready to go" confirmation
4. **No auto-open Preferences** - After completion, user left without guidance
5. **Basic UI** - Lacks polish compared to reference (CleanShot X style)
6. **Missing features showcase** - No visual preview of app capabilities

### Reference Design (CleanShot X)
- Welcome screen with app icon and description
- Shortcuts configuration step
- Cloud feature promotion (optional)
- "Ready to go!" completion screen with menu bar preview

---

## Proposed Improvements

### New Flow Structure
```
WelcomeView → PermissionsView → ShortcutsView → CompletionView → Auto-open Preferences
```

### Phase 1: Update WelcomeView

**Changes:**
- Replace SF Symbol with actual app icon: `Image(nsImage: NSApp.applicationIconImage)`
- Add subtle app tagline
- Enhance visual hierarchy with larger icon (128x128)
- Add feature highlights below main description

**File:** `ClaudeShot/Features/Onboarding/Views/WelcomeView.swift`

### Phase 2: Enhance PermissionsView

**Changes:**
- Add Microphone permission row (optional)
- Add Accessibility permission row (optional for global shortcuts)
- Reuse permission checking logic from `AdvancedSettingsView.swift`
- Show required vs optional badges
- Allow "Skip" for optional permissions

**File:** `ClaudeShot/Features/Onboarding/Views/PermissionsView.swift`

**New imports needed:**
```swift
import AVFoundation
import ScreenCaptureKit
```

### Phase 3: Update ShortcutsView

**Changes:**
- Use app icon instead of command symbol
- Add visual keyboard shortcut badges (like reference)
- Improve copy to match app functionality

**File:** `ClaudeShot/Features/Onboarding/Views/ShortcutsView.swift`

### Phase 4: Create CompletionView (New)

**Purpose:** "Ready to go!" confirmation screen

**Content:**
- Success checkmark icon (green circle)
- "Ready to go!" heading
- Description about menu bar access and shortcuts
- Visual preview of menu bar (optional, can be static image)
- "Open Preferences" primary button
- "Get Started" secondary button

**File:** `ClaudeShot/Features/Onboarding/Views/CompletionView.swift` (new)

### Phase 5: Update OnboardingFlowView

**Changes:**
- Add new `completion` step to `OnboardingStep` enum
- Wire CompletionView into flow
- Auto-open Preferences on completion via `SettingsLink` action or programmatic approach
- Use `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)`

**File:** `ClaudeShot/Features/Onboarding/OnboardingFlowView.swift`

### Phase 6: Design System Enhancements

**Changes:**
- Add success button style (green)
- Add feature highlight component
- Improve spacing constants

**File:** `ClaudeShot/Features/Onboarding/DesignSystem/VSDesignSystem.swift`

---

## Implementation Details

### Permission Checking (from AdvancedSettingsView)

```swift
// Screen Recording
func checkScreenRecordingPermission() async {
  do {
    _ = try await SCShareableContent.current
    screenRecordingGranted = true
  } catch {
    screenRecordingGranted = false
  }
}

// Microphone
func checkMicrophonePermission() {
  let status = AVCaptureDevice.authorizationStatus(for: .audio)
  microphoneGranted = (status == .authorized)
}

// Accessibility
func checkAccessibilityPermission() {
  accessibilityGranted = AXIsProcessTrusted()
}
```

### System Settings URLs
```swift
let screenRecordingURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
let microphoneURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
let accessibilityURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

### Auto-open Preferences
```swift
// Method 1: Using selector
NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)

// Method 2: Activate and find settings window
NSApp.activate(ignoringOtherApps: true)
```

---

## File Changes Summary

| File | Action | Priority |
|------|--------|----------|
| `WelcomeView.swift` | Modify | P1 |
| `PermissionsView.swift` | Modify | P1 |
| `PermissionRow.swift` | Modify | P2 |
| `ShortcutsView.swift` | Modify | P2 |
| `CompletionView.swift` | Create | P1 |
| `OnboardingFlowView.swift` | Modify | P1 |
| `VSDesignSystem.swift` | Modify | P3 |

---

## Visual Consistency Guidelines

- Use `Image(nsImage: NSApp.applicationIconImage)` for app icon (from AboutSettingsView)
- Icon size: 128x128 for main screens
- Primary color: `.blue` (existing)
- Success color: `.green`
- Font hierarchy: `.vsHeading()` for titles, `.vsBody()` for descriptions
- Button styles: `VSDesignSystem.PrimaryButtonStyle()`, `VSDesignSystem.SecondaryButtonStyle()`
- Spacing: 24pt between major sections, 12pt between related items
- Padding: 40pt horizontal padding on all views

---

## Testing Checklist

- [ ] Welcome screen shows actual app icon
- [ ] All three permissions display correctly
- [ ] Required permission blocks "Next" button
- [ ] Optional permissions can be skipped
- [ ] Shortcuts view matches app functionality
- [ ] Completion view displays properly
- [ ] Preferences opens automatically after completion
- [ ] Flow state persists correctly
- [ ] Reset onboarding works for testing

---

## Unresolved Questions

1. Should we add a "Launch at Login" toggle in the shortcuts step (like CleanShot)?
2. Include menu bar preview image in completion view, or keep it simple?
3. Should microphone permission request happen inline or redirect to System Settings?
