# Researcher 02 — macOS License Lease Patterns, Offline Validation, Anti-Tamper

## Short-lived Lease Pattern

### Concept

- Server issues a "lease" (time-boxed permission) on each successful validation
- App operates locally within the lease window — zero API calls
- When lease expires, app must renew from server or enter grace period
- Grace period has hard limits to prevent indefinite offline abuse

### Lease Duration Trade-offs

| Duration | API Calls/Day | Revocation Delay | Offline Tolerance |
| -------- | ------------- | ---------------- | ----------------- |
| 15 min   | ~96           | 15 min           | Poor              |
| 1 hour   | ~24           | 1 hour           | Good              |
| 4 hours  | ~6            | 4 hours          | Very Good         |
| 24 hours | ~1            | 24 hours         | Excellent         |

**Recommendation**: 1 hour lease + 15 min background sync = best balance.
Background sync catches revocations within 15 min, but lease allows 1h offline without any API call.

## Hybrid Validation (Offline-First)

1. **App launch** → check local lease → if valid, start immediately (no API call)
2. **Lease expired** → attempt server renewal → if online, renew; if offline, enter grace
3. **Background timer** → proactive renewal before lease expires → zero UX impact
4. **Grace period** → max 2 days, max 3 uses → prevents extended offline abuse

### Grace Period Anti-Cheat

**Threat**: User sets system clock backward to extend grace period indefinitely.

**Countermeasures** (already partially implemented in `TimeValidator`):

1. Store `serverTime` from last validation as anchor
2. Compare `Date()` against `serverTime` — if drift > 5 min, flag manipulation
3. Store monotonic boot time (`ProcessInfo.processInfo.systemUptime`) — cannot be faked
4. Compare elapsed boot time vs elapsed wall clock — large discrepancy = manipulation
5. Max grace count (existing: 2) prevents unlimited offline usage even without time check

**Additional countermeasure for lease**:

- Store `ProcessInfo.processInfo.systemUptime` alongside lease `grantedAt`
- On lease expiry check: compute expected elapsed = `currentUptime - storedUptime`
- If wall clock elapsed is much less than uptime elapsed → clock was set backward
- This is unforgeable — macOS uptime always increases monotonically

## Anti-Tamper for macOS

### Practical measures for a desktop app:

1. **Keychain storage** — license key + activation ID already in Keychain (done)
2. **Cache in UserDefaults** — acceptable for non-sensitive lease data (expiry timestamp)
3. **Time validation** — NTP check via `sntp` (existing `NTPTimeProvider`) + server time anchor
4. **System uptime** — `ProcessInfo.processInfo.systemUptime` as monotonic reference
5. **Code signing** — macOS already validates at launch (not in-app override needed)

### What NOT to do:

- Don't implement custom obfuscation (diminishing returns on macOS)
- Don't use invasive DRM (hurts UX, macOS ecosystem norms discourage it)
- Don't check debugger attachment (legitimate develop use, false positives)

## Key Recommendations

1. Store monotonic uptime alongside lease for anti-clock-tamper
2. 1h lease + 15min background sync = good balance for all three goals
3. Grace period should be generous enough (2 days) for legitimate offline use
4. Handle rate limit (429) gracefully — extend lease by retry-after duration, don't invalidate
5. Never block the user synchronously on API call — always offline-first
