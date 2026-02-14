# Phase 03: Simplify Expiration Logic

**Parent:** [plan.md](plan.md)
**Date:** 2026-02-14
**Priority:** Low
**Status:** ⬜ Pending

## Overview

For OTP via Polar, `expiresAt` is always `nil` (perpetual license). The current code handles this correctly (`isExpired` returns `false` when `nil`), but some UI/state logic references expiration in ways that will never trigger.

## Proposed Changes

### 1. Clean up `LicenseState.statusDescription` (LicenseState.swift:69-100)

Current code checks `daysRemaining` for licensed state and shows "Expires today", "Valid - X days remaining", etc. For OTP, `daysRemaining` is always `nil`, so it always falls through to "Valid". The expiration branches are dead paths.

**Recommendation:** Keep as-is. The code is defensive and will work correctly if Polar ever returns an expiry date (e.g., promotional key). No harm.

### 2. Clean up `LicenseState.daysRemaining` (LicenseState.swift:54-67)

Same reasoning — harmless, defensive code.

**Recommendation:** Keep.

### 3. Remove `licenseExpired` error case? (LicenseError.swift:11)

Never thrown by any code path for OTP. But it's part of the error enum and could be useful for future key types.

**Recommendation:** Keep. Error enums should be comprehensive.

### 4. Remove `License.isExpired` / `License.isValid`? (License.swift:20-27)

`isValid` checks `status == .granted && !isExpired`. For OTP, `isExpired` is always `false`, so `isValid` simplifies to `status == .granted`. But the code is correct and defensive.

**Recommendation:** Keep.

## Summary

**No changes recommended in this phase.** All expiration-related code handles OTP correctly (treating `nil` expiry as "never expires"). Removing it would reduce defensiveness without meaningful simplification.

## Risk Assessment

N/A — no changes proposed.
