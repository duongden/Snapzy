# Codebase Analysis: Onboarding Persistence

**Date:** 260125
**Status:** Complete

## Current Implementation

### Onboarding Flow Structure
- **Location:** `ClaudeShot/Features/Onboarding/`
- **Main View:** `OnboardingFlowView.swift`
- **Steps:** Welcome -> Permissions -> Shortcuts -> Completion

### Persistence Mechanism (Already Exists)

**OnboardingFlowView.swift:**
```swift
private static let onboardingCompletedKey = "onboardingCompleted"

private func completeOnboarding() {
  UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
  onComplete()
}

static var hasCompletedOnboarding: Bool {
  UserDefaults.standard.bool(forKey: onboardingCompletedKey)
}
```

**ClaudeShotApp.swift:**
```swift
@AppStorage("onboardingCompleted") private var onboardingCompleted = false

// In AppDelegate.applicationDidFinishLaunching:
if !OnboardingFlowView.hasCompletedOnboarding {
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.showOnboardingWindow()
  }
}
```

## Key Finding

**The persistence logic already exists and is correctly implemented.**

The onboarding flow:
1. Checks `OnboardingFlowView.hasCompletedOnboarding` on app launch
2. Only shows onboarding window if flag is `false`
3. Sets flag to `true` when user clicks "Get Started" or "Open Preferences" in CompletionView

## Potential Issues Identified

### Issue 1: Key Mismatch (Minor)
- `OnboardingFlowView` uses: `"onboardingCompleted"` (static key)
- `ClaudeShotApp` uses: `@AppStorage("onboardingCompleted")` (same key)
- **Status:** Keys match - no issue

### Issue 2: Window Opening Mechanism
`showOnboardingWindow()` relies on finding existing window by identifier. If window not found, the fallback code is commented out:
```swift
// If onboarding window not found, open it via OpenWindow environment
//    if let url = URL(string: "zapshot://onboarding") {...}
```

### Issue 3: PreferencesKeys Not Used
`PreferencesKeys.swift` doesn't include `onboardingCompleted` key. For consistency, it should.

## Recommendations

1. Add `onboardingCompleted` to `PreferencesKeys.swift` for consistency
2. Use `@Environment(\.openWindow)` in AppDelegate to properly open onboarding window
3. Add "Restart Onboarding" option in General Settings (already exists via `.showOnboarding` notification)

## Files Involved

| File | Role |
|------|------|
| `ClaudeShot/Features/Onboarding/OnboardingFlowView.swift` | Flow logic + persistence |
| `ClaudeShot/App/ClaudeShotApp.swift` | App entry + launch check |
| `ClaudeShot/Features/Onboarding/Views/CompletionView.swift` | Triggers completion |
| `ClaudeShot/Features/Preferences/PreferencesKeys.swift` | Centralized keys |
