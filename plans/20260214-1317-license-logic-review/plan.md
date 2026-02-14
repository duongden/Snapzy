# License Logic Review — One Time Payment Alignment

**Date:** 2026-02-14
**Status:** 🟡 Pending Review

## Context

The app uses a "One Time Payment" (lifetime license) model via Polar.sh. The app must work **fully offline** after activation. Audit found a critical offline bug + dead code.

## Phases

| #   | Phase                              | Priority    | Status           | File                                              |
| --- | ---------------------------------- | ----------- | ---------------- | ------------------------------------------------- |
| 4   | Fix Offline License (Critical Bug) | 🔴 Critical | ⬜ Pending       | [phase-04](phase-04-fix-offline-license.md)       |
| 1   | Dead Code Removal                  | 🟡 High     | ⬜ Pending       | [phase-01](phase-01-dead-code-removal.md)         |
| 2   | Trial System Decision              | 🟠 Medium   | ⬜ User Decision | [phase-02](phase-02-trial-system-decision.md)     |
| 3   | Simplify Expiration Logic          | 🟢 Low      | ✅ No Changes    | [phase-03](phase-03-simplify-expiration-logic.md) |

## Critical Finding: Offline Lockout Bug

After ~3 days offline, the app **locks out OTP users** via `handleOfflineValidation()` → `gracePeriodExceeded` → `.invalid(reason: .networkError)`. Fix: always trust cached license when offline.

## What To Keep / Remove / Fix

### ✅ KEEP

- License activation/deactivation, Polar API client
- Lease renewal (best-effort: check revocation when online)
- Cache, telemetry, debugger, device fingerprinting
- Activation UI + onboarding flow

### 🔧 FIX

- `handleOfflineValidation()` — always trust cached license offline
- Anti-tamper — relax to log-only (don't lock out paid users)

### ❌ REMOVE (dead code)

- `LicenseTier`, `LicenseEntitlements`, `NTPTimeProvider`, `LicenseConfiguration`
- Grace period system (constants, `TimeValidator` grace logic, grace count, telemetry events)

### ⚠️ USER DECISION

- Trial system — keep for "try before buy" or remove for pure OTP

## Research

- [System Inventory](research/researcher-01-report.md)
- [Polar OTP Behavior](research/researcher-02-report.md)
- [Offline Analysis (Critical)](research/researcher-03-offline-analysis.md)
