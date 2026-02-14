# Phase 04 — Verification

**Parent**: [plan.md](plan.md)
**Dependencies**: [Phase 01](phase-01-lease-model-and-cache.md), [Phase 02](phase-02-lease-lifecycle-engine.md), [Phase 03](phase-03-app-integration.md)
**Date**: 2026-02-14
**Priority**: High
**Implementation Status**: ⬜ Not Started
**Review Status**: ⬜ Pending

## Overview

Manual verification of the complete lease enforcement system. No unit test infrastructure exists; testing is manual with debug logging.

## Test Matrix

| #   | Scenario                           | Expected Behavior                                     | Validates                   |
| --- | ---------------------------------- | ----------------------------------------------------- | --------------------------- |
| 1   | Fresh launch, no license           | Shows License Activation screen                       | No-license path             |
| 2   | Activate valid key                 | License granted, lease created, features enabled      | Activation + lease creation |
| 3   | Keep app open 15+ min              | Background sync renews lease (debug log)              | Background sync timer       |
| 4   | Disable key in Polar, wait ≤15 min | License Activation screen appears automatically       | Revocation detection        |
| 5   | Quit, disable key, relaunch        | Launch detects expired/invalid lease → license screen | Startup validation          |
| 6   | Valid license, go offline          | App works within lease window                         | Offline-first               |
| 7   | Offline for 2+ days                | Grace period exhausted → license screen               | Grace period enforcement    |
| 8   | Set system clock backward 1 hour   | Uptime drift detected → invalidated                   | Anti-tamper                 |
| 9   | Re-activate after invalidation     | Normal operation resumes, new lease created           | Recovery path               |
| 10  | Rapid Cmd+Tab switching            | No API flood (lease short-circuit)                    | API efficiency              |

## Debug Tips

> [!TIP]
> For faster testing, temporarily set these values in `LicenseManager`:
>
> ```swift
> private let leaseDuration: TimeInterval = 60          // 1 min
> private let backgroundSyncInterval: TimeInterval = 15 // 15 sec
> ```

Check console output for:

- `=== LEASE: Created new lease ===`
- `=== LEASE: Still valid, skipping API ===`
- `=== LEASE: Expired, renewing ===`
- `=== LICENSE INVALIDATED: [reason] ===`

## Success Criteria

- All 10 test scenarios pass
- No API calls during active use within valid lease
- License screen is non-dismissable without valid key
- Features disabled in status bar menu after invalidation

## Next Steps

None — feature complete after verification passes.
