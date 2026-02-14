# Phase 02: Trial System Decision

**Parent:** [plan.md](plan.md)
**Date:** 2026-02-14
**Priority:** Medium
**Status:** ⬜ Pending — **Requires User Decision**

## Overview

The trial system offers 30 days of Pro access without a license key. This phase depends on a **business decision**.

## Options

### Option A: REMOVE Trial (Pure OTP)

If users always purchase before downloading (e.g., via Polar checkout → download link), trial is unnecessary.

**Changes:**

- Remove `startTrial()` from `LicenseManager.swift`
- Remove `checkTrialStatus()` from `LicenseManager.swift`
- Remove `calculateTrialDaysRemaining()` from `LicenseManager.swift`
- Remove `.trial(daysRemaining:)` and `.trialExpired` from `LicenseState`
- Remove trial cache methods from `LicenseCache.swift` (`setTrialStart`, `getTrialStart`, `isTrialStarted`)
- Remove `trialStarted` / `trialExpired` from `LicenseTelemetry`
- Remove trial-related UI from `AboutSettingsView.swift`
- Simplify `LicenseOnboardingRootView.swift` (no trial path)
- Remove `LicenseConfig.trialDays` constant

**Impact:** ~60 lines removed across 5 files. Cleaner state machine.

### Option B: KEEP Trial (Try Before You Buy)

If the app is distributed independently (website download, GitHub, Homebrew) and the user discovers it before purchasing, a trial period is useful.

**Changes:** None — keep as-is.

**Note:** The trial code is clean and well-isolated. Keeping it adds minor maintenance burden.

## Recommendation

**If app is sold via Polar checkout → download:** Remove trial (Option A).
**If app is downloadable without purchase:** Keep trial (Option B).

## Question for User

> Do you want users to be able to try the app for 30 days before purchasing, or must they purchase first?
