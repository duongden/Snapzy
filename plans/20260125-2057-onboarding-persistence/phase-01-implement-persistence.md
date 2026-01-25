# Phase 01: Standardize Onboarding Persistence

## Context Links

- [Plan Overview](./plan.md)
- [Codebase Analysis](./reports/01-codebase-analysis.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 260125 |
| Description | Standardize and improve existing onboarding persistence |
| Priority | Low (core functionality already works) |
| Status | Pending |
| Estimated Effort | 30 minutes |

## Key Insights

1. **Persistence already implemented** - `UserDefaults` with `"onboardingCompleted"` key
2. **Check works correctly** - App only shows onboarding when flag is `false`
3. **Minor improvements needed** - Key centralization, window opening fix

## Requirements

- [x] Store onboarding completion state persistently (exists)
- [x] Check state on app launch (exists)
- [x] Only show onboarding when not completed (exists)
- [ ] Centralize key in PreferencesKeys
- [ ] Fix window opening mechanism
- [ ] Add restart onboarding option verification

## Architecture

```
App Launch
    |
    v
AppDelegate.applicationDidFinishLaunching()
    |
    v
Check: OnboardingFlowView.hasCompletedOnboarding
    |
    +-- true --> Skip onboarding, show menu bar
    |
    +-- false --> showOnboardingWindow()
                      |
                      v
                  OnboardingFlowView
                      |
                      v
                  User completes flow
                      |
                      v
                  completeOnboarding()
                      |
                      v
                  UserDefaults.set(true, "onboardingCompleted")
```

## Related Code Files

| File | Changes |
|------|---------|
| `ClaudeShot/Features/Preferences/PreferencesKeys.swift` | Add `onboardingCompleted` key |
| `ClaudeShot/Features/Onboarding/OnboardingFlowView.swift` | Use centralized key |
| `ClaudeShot/App/ClaudeShotApp.swift` | Fix window opening, use centralized key |

## Implementation Steps

### Step 1: Add Key to PreferencesKeys

```swift
// In PreferencesKeys.swift
enum PreferencesKeys {
  // Onboarding
  static let onboardingCompleted = "onboardingCompleted"

  // ... existing keys
}
```

### Step 2: Update OnboardingFlowView

```swift
// Replace hardcoded key
private static let onboardingCompletedKey = PreferencesKeys.onboardingCompleted
```

### Step 3: Update ClaudeShotApp

```swift
// Use centralized key
@AppStorage(PreferencesKeys.onboardingCompleted) private var onboardingCompleted = false
```

### Step 4: Fix Window Opening (Optional)

Use `@Environment(\.openWindow)` or ensure WindowGroup is properly triggered.

## Todo List

- [ ] Add `onboardingCompleted` to `PreferencesKeys.swift`
- [ ] Update `OnboardingFlowView.swift` to use centralized key
- [ ] Update `ClaudeShotApp.swift` to use centralized key
- [ ] Test fresh install scenario
- [ ] Test restart onboarding from preferences
- [ ] Verify persistence across app restarts

## Success Criteria

1. Onboarding shows only on first launch
2. Subsequent launches skip onboarding
3. "Restart Onboarding" from preferences works
4. All keys centralized in `PreferencesKeys`

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing persistence | Low | Key name unchanged |
| Window not opening | Medium | Test WindowGroup behavior |

## Security Considerations

- No sensitive data stored
- UserDefaults appropriate for this use case
- No encryption needed for boolean flag

## Next Steps

After implementation:
1. Test on clean install (delete app preferences)
2. Verify menu bar app functions after onboarding
3. Document in code comments
