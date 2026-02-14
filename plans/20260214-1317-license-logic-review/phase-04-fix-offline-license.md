# Phase 04: Fix Offline License — Critical Bug

**Parent:** [plan.md](plan.md)
**Date:** 2026-02-14
**Priority:** 🔴 Critical
**Status:** ⬜ Pending

## Context

- [plan.md](plan.md)
- [Offline Analysis](research/researcher-03-offline-analysis.md)

## Overview

**Bug:** After ~3 days offline, the app invalidates an OTP license. Users who paid for a lifetime license get locked out.

**Root cause:** `handleOfflineValidation()` uses a subscription-style grace period system that caps offline usage at 2 grace periods (each 1 day). After that, the app sets `state = .invalid(reason: .networkError)`.

**Fix:** For OTP, if a cached activated license exists, always trust it when offline. Only invalidate when the server explicitly says revoked/disabled.

## Key Insights

1. Lease renewal is useful — it detects revoked/disabled keys **when online**
2. Grace periods are wrong for OTP — a paid user should never be locked out for being offline
3. Anti-tamper (clock drift detection) should also be relaxed — offline users may have clock sync issues
4. Background sync should be best-effort — try when online, silently skip when offline

## Requirements

- OTP license must work indefinitely offline after activation
- Revocation must still work when user comes back online
- No lock-out due to network errors or clock drift
- Background sync becomes purely opportunistic

## Architecture

```
CURRENT (Subscription-style):
  lease expires → API call → fail → grace period → MAX → LOCK OUT ❌

PROPOSED (OTP-style):
  lease expires → API call → fail → use cached license ✅
  lease expires → API call → success → update lease ✅
  lease expires → API call → revoked → invalidate ✅
```

## Related Code Files

| File                                                                                                                         | Lines    | Role                                          |
| ---------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------------------------- |
| [LicenseManager.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/Core/License/LicenseManager.swift)               | L610-646 | `handleOfflineValidation()` — main fix target |
| [LicenseManager.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/Core/License/LicenseManager.swift)               | L275-293 | Anti-tamper checks in `renewLease()`          |
| [LicenseManager.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/Core/License/LicenseManager.swift)               | L14-31   | `LicenseConfig` — grace period constants      |
| [TimeValidator.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/Core/License/Security/TimeValidator.swift)        | L24-50   | Grace period logic                            |
| [LicenseCache.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/Core/License/Cache/LicenseCache.swift)             | L115-122 | Grace count methods                           |
| [LicenseTelemetry.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/Core/License/Telemetry/LicenseTelemetry.swift) | L16-17   | Grace period events                           |

## Implementation Steps

### Step 1: Simplify `handleOfflineValidation()` (LicenseManager.swift)

Replace the grace period switch with:

```swift
private func handleOfflineValidation(
    timeValidation: TimeValidator.TimeValidationResult,
    localTime: Date
) {
    // OTP: cached activated license is trusted indefinitely offline
    if let cached = cache.load() {
        state = .licensed(license: cached.license)
        #if DEBUG
        print("=== OFFLINE: Trusting cached OTP license ===")
        #endif
        return
    }
    // No cached license at all
    state = .invalid(reason: .networkError)
}
```

### Step 2: Relax anti-tamper in `renewLease()` (LicenseManager.swift)

Change lines 275-293 — instead of calling `handleLicenseInvalidated()` on uptime drift, log telemetry and continue:

```swift
if existingLease.hasUptimeDrift() {
    #if DEBUG
    print("=== LEASE: Uptime drift detected — logging only (OTP) ===")
    #endif
    telemetry.track(event: .timeManipulationDetected)
    // OTP: don't invalidate, just log. Proceed with renewal attempt.
}
```

Similarly for `performTimeValidation()` — don't return early on time manipulation, just log it.

### Step 3: Remove grace period dead code

After Step 1, the following become dead code:

- `LicenseConfig.gracePeriodDays` and `maxGracePeriods` constants
- `TimeValidator` grace period logic (L37-46)
- `TimeValidator.TimeValidationResult.gracePeriodAllowed` and `.gracePeriodExceeded`
- `LicenseCache.incrementGraceCount()`, `getGraceCount()`
- `LicenseTelemetry.gracePeriodUsed`, `gracePeriodExceeded` events
- `UserDefaults` keys: `grace_count`

### Step 4: Remove `performTimeValidation()` call from `renewLease()`

Lines 288-293 — the time validation pre-check before the API call becomes unnecessary since we no longer invalidate on time drift.

## Todo List

- [ ] Simplify `handleOfflineValidation()` to always trust cached license
- [ ] Relax anti-tamper to log-only (no invalidation)
- [ ] Remove grace period constants from `LicenseConfig`
- [ ] Remove `performTimeValidation()` and related method
- [ ] Remove grace period logic from `TimeValidator`
- [ ] Remove grace count methods from `LicenseCache`
- [ ] Remove grace period telemetry events
- [ ] Remove `grace_count` UserDefaults usage

## Success Criteria

1. App works indefinitely offline after activation
2. App detects revoked/disabled keys when back online
3. Project compiles without errors
4. No runtime regressions for online users

## Risk Assessment

**Medium** — Removing anti-tamper reduces piracy protection, but for OTP the trade-off is correct: paid users should never be punished. Revocation still works when online.

## Security Considerations

- Clock manipulation detection weakened → pirates could theoretically activate, go offline, and use forever
- Mitigation: activation still requires server, device limits still enforced, revocation works when online
- For an indie macOS app, this is acceptable. Heavy DRM hurts legitimate users more than pirates.

## Next Steps

After this phase, proceed to Phase 1 (Dead Code Removal) which will naturally clean up additional dead code revealed by this change.
