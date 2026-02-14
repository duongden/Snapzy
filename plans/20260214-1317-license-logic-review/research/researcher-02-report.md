# Research Report: Polar API & One-Time Payment License Behavior

## Summary

Analysis of how Polar.sh license keys behave with "One Time Payment" products vs subscriptions, and implications for the current license validation logic.

## Polar One-Time Payment License Behavior

1. **`expiresAt`**: `null` for lifetime/OTP keys — license never expires
2. **`status`**: `"granted"` when active; `"revoked"` if admin revokes; `"disabled"` if admin disables
3. **`limitActivations`**: configurable per product (e.g., 2 devices)
4. **`usage`**: current activation count
5. **`lastValidatedAt`**: updated on each `/validate` call — useful for anti-tamper

## What Lease Renewal Actually Does for OTP

The current `renewLease()` calls `/validate` endpoint → Polar returns `"granted"` (forever, since no expiry). The lease system is effectively:

- "Is this key still valid on the server?" (not revoked/disabled)
- Creates a local time-boxed permit so the app doesn't call API on every action

This is **correct and valuable** for OTP because:

- Admin can still revoke/disable a key (refund, chargeback, abuse)
- Prevents key sharing (device limits enforced server-side)
- Offline-first: cached lease allows usage without internet

## Trial System Analysis

The trial allows users to use the app for 30 days without a license key.

For a **pure OTP model**, the trial flow is:

- `state = .noLicense` → User must enter key → Purchase flow
- No trial needed if user already paid at point of download

However, a trial can still be useful for OTP if:

- App is distributed outside purchase flow (e.g., direct download)
- User discovers app first, tries it, then purchases

**Current trial implementation details:**

- `startTrial()` saves `trialStart` date to UserDefaults
- `checkTrialStatus()` calculates remaining days
- `LicenseState.trial(daysRemaining:)` and `.trialExpired` states
- Trial grants `.pro` entitlements (same as licensed)
- `LicenseOnboardingRootView` checks trial/license state to decide flow

## Dead Code Identified

### `LicenseTier` enum

```swift
enum LicenseTier: String, CaseIterable {
    case free = "Free"
    case pro = "Pro"
}
```

- Defines feature lists for marketing but never used in runtime logic
- No code checks `LicenseTier` to gate features

### `LicenseEntitlements` struct

- `shouldShowProFeatures()` returns `true` for `.trial` and `.licensed` — used nowhere
- `canAccessFeature()` — used nowhere
- The actual gating in the app uses `LicenseManager.shared.isLicensed` (a simple bool)

### `NTPTimeProvider`

- Complete class with NTP time fetching via `/usr/bin/sntp`
- Never called from any code path

### `LicenseConfiguration` struct

- Defines `default` and `sandbox` configs with `apiBaseURL`, `validateInterval`, `cacheValidityDuration`
- `LicenseManager` doesn't use this struct; it has its own `LicenseConfig` private struct
- `PolarLicenseProvider` uses `SecretsConfig` directly

## Key Observations

1. **No feature gating exists** — `isLicensed` is a simple boolean check. The entitlements system is dead code.
2. **`expiresAt` checks are safe** — they return `false` when `nil`, which is correct for OTP
3. **The lease system is appropriate** — it provides "is the license still valid?" checks without requiring constant connectivity
4. **Trial decision is business-level** — pure OTP might not need trial, but it's useful for "try before buy"
