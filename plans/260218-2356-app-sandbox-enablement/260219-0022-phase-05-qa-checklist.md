# Phase 05 QA Checklist Report

**Plan:** [plan.md](./plan.md)  
**Phase:** [phase-05-verification-and-rollout.md](./phase-05-verification-and-rollout.md)  
**Date:** 2026-02-19  
**Timestamp:** 260219-0022

## Automated verification (this run)

1. Sandbox entitlements present and enabled (`plutil -p Snapzy/Snapzy.entitlements`)  
   Result: PASS
2. Build settings set for sandbox (`ENABLE_APP_SANDBOX = YES`, `ENABLE_USER_SELECTED_FILES = readwrite`)  
   Result: PASS
3. Debug build with sandbox-enabled target (`xcodebuild ... -configuration Debug ... CODE_SIGNING_ALLOWED=NO`)  
   Result: PASS (`BUILD SUCCEEDED`)
4. Release build with sandbox-enabled target (`xcodebuild ... -configuration Release ... CODE_SIGNING_ALLOWED=NO`)  
   Result: PASS (`BUILD SUCCEEDED`)
5. Subprocess fingerprint risk scan in license path (`rg "Process\\(|ioreg|sysctl" Snapzy/Services/License/DeviceFingerprint.swift`)  
   Result: PASS (no matches)
6. Onboarding includes required save-folder permission step  
   Result: PASS (`Snapzy/Features/Onboarding/Components/OnboardingPermissionsView.swift`)
7. Replace-original fallback UX scan  
   Result: PASS (`Save as Copy` prompts and permission-denied handling present)

## Manual verification matrix (required before release)

1. App launch, onboarding, permissions prompt flow  
   Status: PENDING MANUAL
2. Screenshot full/area save to chosen export folder  
   Status: PENDING MANUAL
3. Recording save + GIF conversion + quick access actions  
   Status: PENDING MANUAL
4. Annotate save to original + save as copy  
   Status: PENDING MANUAL
5. Video editor replace original + save as copy  
   Status: PENDING MANUAL
6. Wallpaper loading (system + manually granted folder)  
   Status: PENDING MANUAL
7. License activate/validate/deactivate with network on/off  
   Status: PENDING MANUAL
8. Sparkle check-for-updates  
   Status: PENDING MANUAL
9. Diagnostics log write/read/open folder  
   Status: PENDING MANUAL
10. No first-time permission request appears outside onboarding except recovery paths  
    Status: PENDING MANUAL

## Manual QA script

1. Remove app state (`UserDefaults` domain + onboarding state), launch app, verify onboarding asks Screen Recording + Save Folder.
2. In onboarding, pick default `Desktop/Snapzy`, complete onboarding, relaunch app.
3. Capture full and area screenshots; confirm files save without re-prompt.
4. Start/stop recording with and without microphone; verify output + quick actions.
5. Open image from external folder, test annotate `Save` and `Save As`; verify denial alert path if folder access revoked.
6. Open video from external folder, test `Replace Original`; on denial verify `Save as Copy` path appears and succeeds.
7. Clear default wallpaper dirs simulation (or use non-default source), grant folder access in picker, relaunch, verify wallpaper restore from bookmark.
8. Run license activate/validate/deactivate with network available and unavailable; verify no fingerprint churn after relaunch.
9. Trigger Sparkle update check and confirm network call succeeds.
10. Review Console sandbox deny logs while executing all flows; no persistent deny allowed for core paths.

## Known warnings (non-blocking for this phase run)

1. Existing project warning: Info.plist in Copy Bundle Resources.
2. Existing Swift concurrency warnings in multiple files (pre-existing; not introduced by sandbox work).

## Rollout gate recommendation

1. Keep rollout at `Debug -> internal Release -> public Release`.
2. Require one focused manual QA pass on sandbox paths before public release.

## Unresolved questions

1. Distribution target policy still undecided (MAS-first vs Developer ID-first).
2. Need decision on dedicated beta cycle before production rollout.
3. Need backend confirmation that device-label format shift is accepted.
