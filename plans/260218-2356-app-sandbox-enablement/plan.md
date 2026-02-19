# Plan: App Sandbox Enablement

**Date:** 2026-02-18
**Status:** IN PROGRESS
**Priority:** High
**Scope:** Entitlements + filesystem + license identity + verification rollout

## Summary

Enable App Sandbox for Snapzy without breaking capture/recording/export/license/update flows. Current state is not sandbox-safe: sandbox is OFF, network entitlement missing, file access is path-based (not bookmark/scoped), and license fingerprint uses subprocess calls.

## Why now

- Reduce security risk surface
- Align with hardened runtime posture
- Prepare for stricter distribution requirements

## Current blockers (from codebase audit)

1. Sandbox disabled in target settings and entitlements
2. Network entitlement missing while app uses URLSession + Sparkle
3. Export location persisted as plain path string, no security-scoped bookmarks
4. Replace-original flows write directly to external files
5. Device fingerprint uses `Process` + `/usr/sbin/ioreg` and `/usr/sbin/sysctl`

## Phase Breakdown

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Entitlements + Build Config | COMPLETED | [phase-01](./phase-01-entitlements-and-build-config.md) |
| 2 | Sandbox File Access Foundation | COMPLETED | [phase-02-file-access-foundation.md](./phase-02-file-access-foundation.md) |
| 3 | Feature Flow Migration | COMPLETED | [phase-03-feature-flow-migration.md](./phase-03-feature-flow-migration.md) |
| 4 | License Fingerprint Hardening | COMPLETED | [phase-04-license-fingerprint-hardening.md](./phase-04-license-fingerprint-hardening.md) |
| 5 | Verification + Rollout | IN PROGRESS | [phase-05-verification-and-rollout.md](./phase-05-verification-and-rollout.md) |

## Target files (expected)

- `Snapzy/Snapzy.entitlements`
- `Snapzy.xcodeproj/project.pbxproj`
- `Snapzy/Features/Preferences/Models/PreferencesKeys.swift`
- `Snapzy/Features/Preferences/Components/PreferencesGeneralSettingsView.swift`
- `Snapzy/Features/Capture/CaptureViewModel.swift`
- `Snapzy/Services/Capture/ScreenCaptureManager.swift`
- `Snapzy/Services/Capture/ScreenRecordingManager.swift`
- `Snapzy/Features/Annotate/Services/AnnotateExporter.swift`
- `Snapzy/Features/VideoEditor/Services/VideoEditorExporter.swift`
- `Snapzy/Services/Wallpaper/SystemWallpaperManager.swift`
- `Snapzy/Services/License/DeviceFingerprint.swift`
- `Snapzy/Services/License/LicenseCache.swift`
- `Snapzy/Services/License/LicenseManager.swift`

## Out of scope

- Re-architect capture pipeline
- UI redesign
- License backend contract changes

## Success criteria

1. App launches and runs with `ENABLE_APP_SANDBOX = YES`
2. Capture + recording save work with user-selected writable folder
3. Annotate/video "replace original" works for user-granted files
4. Licensing + Sparkle update checks work inside sandbox
5. No regressions in OCR, clipboard, hotkeys, onboarding permissions

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Path-only storage breaks writes after sandbox enabled | High | Migrate to bookmark-backed storage with fallback picker |
| Fingerprint change invalidates cached license | High | Add compatibility migration + graceful re-validation |
| Drag/drop URLs lose write rights | Medium | Normalize via security-scoped access + save-as fallback |

## Confirmed Decisions (2026-02-18)

1. Distribution target is **TBD** (not decided yet). Plan keeps implementation compatible with both MAS and Developer ID where practical.
2. Export folder permission will be requested in **Onboarding** with **Desktop/Snapzy as default**.
3. Permission UX will be shown in **Onboarding flow** for any required permission; runtime fallback prompt remains only for cases where permission is missing/revoked.

## Permission policy

1. Any new permission required by sandbox migration must be introduced in onboarding first.
2. Runtime permission dialogs are recovery-only (revoked, reset, or skipped onboarding).
3. Onboarding must keep sensible defaults and clear skip/continue behavior.

## Unresolved questions

1. Distribution target is still undecided (MAS vs Developer ID focus for rollout policy).
2. Do we require a dedicated beta cycle before production rollout?
