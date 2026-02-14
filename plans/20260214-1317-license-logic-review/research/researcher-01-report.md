# Research Report: License System Inventory & One-Time Payment Alignment

## Summary

Full audit of 14 files in `Snapzy/Core/License/` and `Snapzy/Features/License/` to determine which license concepts align with a "One Time Payment" (lifetime) model and which are designed for subscriptions.

## Current Architecture

### Files & Roles

| File                              | Role                                                                               | Lines |
| --------------------------------- | ---------------------------------------------------------------------------------- | ----- |
| `LicenseManager.swift`            | Central orchestrator: activate, validate, renew lease, trial, deactivate           | 655   |
| `PolarLicenseProvider.swift`      | Polar API client: activate, validate, deactivate, getLicense                       | 258   |
| `LicenseCache.swift`              | Keychain + UserDefaults persistence                                                | 168   |
| `License.swift`                   | Data models: `License`, `ValidateResponse`, `ActivateResponse`                     | 194   |
| `LicenseState.swift`              | Enum: `.trial`, `.licensed`, `.trialExpired`, `.invalid`, `.loading`, `.noLicense` | 178   |
| `LicenseConfiguration.swift`      | Config struct (unused in LicenseManager—it uses `LicenseConfig` private struct)    | 45    |
| `LicenseConstants.swift`          | `LicenseTier` enum + `LicenseEntitlements` struct                                  | 102   |
| `LicenseLease.swift`              | Time-boxed permission record for offline-first validation                          | 46    |
| `LicenseError.swift`              | Error enum (18 cases)                                                              | 58    |
| `LicenseDebugger.swift`           | Debug utilities                                                                    | 95    |
| `TimeValidator.swift`             | Clock-drift + grace period logic                                                   | 184   |
| `LicenseTelemetry.swift`          | Local event tracking                                                               | 124   |
| `LicenseActivationView.swift`     | Activation UI (validate → activate 2-phase)                                        | 267   |
| `LicenseOnboardingRootView.swift` | Splash → license → onboarding flow                                                 | 255   |

## Concepts vs One-Time Payment

### ✅ KEEP (aligned with One Time Payment)

1. **License activation/deactivation** — core of device-linked license keys
2. **Lease-based periodic re-validation** — prevents piracy; lease simply checks the key is still "granted" (not revoked)
3. **Grace period for offline** — essential for users without constant internet
4. **Anti-tamper (time manipulation detection)** — security measure, model-agnostic
5. **Telemetry** — helpful for debugging regardless of payment model
6. **Device fingerprinting** — needed for activation ID tracking
7. **Cache (Keychain + UserDefaults)** — required persistence layer
8. **License invalidation (revoked/disabled)** — admin can revoke any license type
9. **Debugger** — development tool
10. **Activation view + Onboarding flow** — user-facing, needed for license entry

### ⚠️ REVIEW (potentially unnecessary)

1. **Trial system** (30-day trial, `startTrial()`, `.trial` state, `.trialExpired`) — for OTP, user pays once upfront. Trial is only useful if you offer a "try before you buy" model. If not, remove entirely.
2. **`LicenseTier` enum (free/pro)** — implies tiered functionality. **Never referenced** outside `LicenseConstants.swift`. Dead code.
3. **`LicenseEntitlements` struct** — defines granular feature gates (canRecord, canAnnotate, etc.). **Only referenced** in `LicenseState.entitlements` but `canAccessFeature()` and `shouldShowProFeatures()` are **never called** in the codebase. Dead code.
4. **`expiresAt` / `isExpired` on `License`** — for OTP via Polar, `expiresAt` is `nil` (perpetual). The `isExpired` check returns `false` when `nil`. Harmless but the UI code in `LicenseState.statusDescription` checks `daysRemaining` which will always be `nil`. Some cleanup possible.
5. **`LicenseConfiguration` struct** — duplicates `LicenseConfig` private struct in `LicenseManager`. One is unused.
6. **`licenseExpired` error case** — will never trigger for OTP. Harmless but adds noise.
7. **`NTPTimeProvider`** — defined but **never called** anywhere. Dead code.

## Usage Across Codebase

| Consumer                            | Usage                                                    |
| ----------------------------------- | -------------------------------------------------------- |
| `SnapzyApp.swift:49,86`             | `LicenseManager.shared.renewLease()`                     |
| `StatusBarController.swift:186`     | `LicenseManager.shared.isLicensed`                       |
| `KeyboardShortcutManager.swift:399` | `LicenseManager.shared.isLicensed`                       |
| `AboutSettingsView.swift`           | License status display, deactivate, activate, debug info |
| `LicenseOnboardingRootView.swift`   | Checks `LicenseManager.shared.state` for license/trial   |

## Unresolved Questions

1. Does the user want a trial period (try before you buy)?
2. Should `LicenseEntitlements`/`LicenseTier` be removed or preserved for future use?
