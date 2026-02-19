# Phase 04: License Fingerprint Hardening

**Parent:** [plan.md](./plan.md)
**Date:** 2026-02-18
**Priority:** High
**Implementation Status:** COMPLETED
**Review Status:** IMPLEMENTED, BUILD-VERIFIED

## Goal

Remove subprocess-based fingerprint collection and stabilize licensing identity under sandbox.

## Current references

- `Snapzy/Services/License/DeviceFingerprint.swift`
- `Snapzy/Services/License/LicenseManager.swift`
- `Snapzy/Services/License/LicenseCache.swift`

## Problem

Fingerprint currently depends on launching `/usr/sbin/ioreg` and `/usr/sbin/sysctl` via `Process`. Under sandbox this is brittle and can fail silently, causing cache invalidation churn.

## Requirements

1. Replace subprocess fingerprint with sandbox-safe identifier strategy
2. Maintain stable per-device identity across app relaunch
3. Avoid mass accidental license invalidation for existing users

## Proposed approach

- Generate app-scoped stable UUID once, store in Keychain (or existing license keychain namespace)
- Use UUID for device label + cache fingerprint consistency
- Compatibility migration path for old cached entries

## Tasks

- [x] Implement new `DeviceFingerprint` backend (no subprocess)
- [x] Add one-time migration compatibility path from legacy cached fingerprint
- [x] Add diagnostics log line for fingerprint source/version to aid support
- [x] Remove dead subprocess parsing code

## Success criteria

1. Fingerprint generation has zero `Process` usage
2. Licensing activation/validation stable under sandbox
3. Existing licensed users do not get unnecessary forced reactivation

## Risk

- Fingerprint migration bugs can force unexpected license reactivation

## Unresolved questions

1. Confirm backend tolerance for device-label shift from hardware-derived to keychain-derived stable ID.
