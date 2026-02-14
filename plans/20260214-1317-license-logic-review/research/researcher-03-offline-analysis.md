# Research Report: Offline License Behavior — Critical Bug Found

## Summary

Traced complete offline flow after OTP activation. Found **critical bug**: the app locks users out after ~3 days offline, contradicting OTP model.

## Offline Flow Trace

### Happy Path (online)

1. App starts → `loadCachedState()` → valid lease → `.licensed` ✅
2. Lease expires (1h prod) → `renewLease()` → server returns "granted" → new lease ✅

### Offline Failure Path

1. App starts → `loadCachedState()` → expired lease + cached license → `.licensed` + schedule renewal
2. `renewLease()` → lease expired → tries server → **network error**
3. Falls to `catch` block → `handleOfflineValidation(timeValidation, localTime)`
4. `TimeValidator.validateTime()` checks:
   - `elapsed` since `lastLocalTime` > `gracePeriod` (86400s = 1 day)?
   - If yes AND `graceCount < maxGracePeriods (2)` → `.gracePeriodAllowed`
   - If yes AND `graceCount >= 2` → **`.gracePeriodExceeded`** ❌
5. `handleOfflineValidation()` L638-640:
   ```swift
   case .gracePeriodExceeded:
       state = .invalid(reason: .networkError) // ← APP LOCKS OUT
   ```

### Timeline

| Day | What happens                                                                                                  |
| --- | ------------------------------------------------------------------------------------------------------------- |
| 0   | License activated, lease created (1h)                                                                         |
| 0-1 | Lease expires. If offline: `timeValidation = .valid` (< 1 day since last validation) → cached license used ✅ |
| 1-2 | Offline > 1 day: `gracePeriodAllowed` (graceCount: 0→1) → cached license ✅                                   |
| 2-3 | Offline > 1 day again: `gracePeriodAllowed` (graceCount: 1→2) → cached license ✅                             |
| 3+  | Offline: `gracePeriodExceeded` (graceCount: 2 ≥ maxGracePeriods 2) → **`.invalid`** ❌❌❌                    |

## Root Cause

`TimeValidator` + `handleOfflineValidation()` were designed for **subscription validation** where periodic server checks are mandatory. For OTP, this is wrong — a paid lifetime license should never be invalidated due to network unavailability.

## Fix Options

### Option A: Best-Effort Renewal (Recommended for OTP)

- Lease renewal tries server when online → detects revocation
- If offline and cached license exists → **always trust cached license**
- Never invalidate on network error when cached activation exists

**Change `handleOfflineValidation()`**:

```swift
private func handleOfflineValidation(...) {
    // OTP: if we have a cached, activated license, always trust it offline
    if let cached = cache.load() {
        state = .licensed(license: cached.license)
        return
    }
    // No cache at all → invalid
    state = .invalid(reason: .networkError)
}
```

**Impact**: Grace period logic becomes irrelevant. `TimeValidator` grace period code becomes dead.

### Option B: Remove Lease System Entirely

- Once activated → cached license is the authority
- No periodic re-validation at all
- Cannot detect revoked licenses

**Not recommended** — loses ability to remotely revoke keys for refunds/abuse.

### Option C: Infinite Grace Period

- Set `maxGracePeriods = Int.max`
- Hacky, doesn't address the design mismatch

## Recommendation

**Option A**. Keeps revocation detection when online but never punishes offline users.

## Additional Concerns

### Anti-Tamper (Time Manipulation Detection)

Lines 275-293 in `renewLease()` check for clock manipulation **before** the API call:

- `hasUptimeDrift()` — checks if wall clock was set backward
- `performTimeValidation()` — checks server time drift

These run before the API call, so they can **invalidate a license while offline** if the user's clock drifts (e.g., traveling across timezones, system clock sync issues). For OTP, time manipulation detection should be **relaxed** — a paid user shouldn't lose access because their clock drifted.

**Recommendation**: Keep anti-tamper for the API validation path but don't invalidate the license — just log a telemetry event. Or increase the drift threshold significantly.

## Affected Files

| File                     | Change                                                             |
| ------------------------ | ------------------------------------------------------------------ |
| `LicenseManager.swift`   | Simplify `handleOfflineValidation()` — always trust cached license |
| `LicenseManager.swift`   | Consider removing/relaxing anti-tamper invalidation                |
| `TimeValidator.swift`    | Grace period logic becomes dead code → remove                      |
| `LicenseTelemetry.swift` | `gracePeriodUsed`/`gracePeriodExceeded` events become dead         |
| `LicenseCache.swift`     | `graceCount` methods become dead                                   |
