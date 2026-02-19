# Commit Split Proposal (Sandbox Enablement)

**Date:** 2026-02-19  
**Session ID:** 260219-0027

## Scope note

- Exclude unrelated local state file:
  - `Snapzy.xcodeproj/project.xcworkspace/xcuserdata/duongductrong.xcuserdatad/UserInterfaceState.xcuserstate`

## Commit 1: sandbox core implementation

**Message**
`feat(app-sandbox): enable sandbox and migrate file access flows`

**Files**

1. `Snapzy/Snapzy.entitlements`
2. `Snapzy.xcodeproj/project.pbxproj`
3. `Snapzy/Services/FileAccess/SandboxFileAccessManager.swift`
4. `Snapzy/Features/Preferences/Models/PreferencesKeys.swift`
5. `Snapzy/Features/Preferences/Components/PreferencesGeneralSettingsView.swift`
6. `Snapzy/Features/Onboarding/Components/OnboardingPermissionsView.swift`
7. `Snapzy/Features/Capture/CaptureViewModel.swift`
8. `Snapzy/Services/Capture/ScreenCaptureManager.swift`
9. `Snapzy/Services/Capture/ScreenRecordingManager.swift`
10. `Snapzy/Features/Recording/RecordingCoordinator.swift`
11. `Snapzy/Features/Annotate/Services/AnnotateExporter.swift`
12. `Snapzy/Features/Annotate/Components/AnnotateToolbarView.swift`
13. `Snapzy/Features/Annotate/Managers/AnnotateWindowController.swift`
14. `Snapzy/Features/VideoEditor/Services/VideoEditorExporter.swift`
15. `Snapzy/Features/VideoEditor/Managers/VideoEditorWindowController.swift`
16. `Snapzy/Services/Wallpaper/SystemWallpaperManager.swift`
17. `Snapzy/Services/License/DeviceFingerprint.swift`
18. `Snapzy/Services/License/LicenseManager.swift`

**Stage command**

```bash
git add \
  Snapzy/Snapzy.entitlements \
  Snapzy.xcodeproj/project.pbxproj \
  Snapzy/Services/FileAccess/SandboxFileAccessManager.swift \
  Snapzy/Features/Preferences/Models/PreferencesKeys.swift \
  Snapzy/Features/Preferences/Components/PreferencesGeneralSettingsView.swift \
  Snapzy/Features/Onboarding/Components/OnboardingPermissionsView.swift \
  Snapzy/Features/Capture/CaptureViewModel.swift \
  Snapzy/Services/Capture/ScreenCaptureManager.swift \
  Snapzy/Services/Capture/ScreenRecordingManager.swift \
  Snapzy/Features/Recording/RecordingCoordinator.swift \
  Snapzy/Features/Annotate/Services/AnnotateExporter.swift \
  Snapzy/Features/Annotate/Components/AnnotateToolbarView.swift \
  Snapzy/Features/Annotate/Managers/AnnotateWindowController.swift \
  Snapzy/Features/VideoEditor/Services/VideoEditorExporter.swift \
  Snapzy/Features/VideoEditor/Managers/VideoEditorWindowController.swift \
  Snapzy/Services/Wallpaper/SystemWallpaperManager.swift \
  Snapzy/Services/License/DeviceFingerprint.swift \
  Snapzy/Services/License/LicenseManager.swift
```

**Commit command**

```bash
git commit -m "feat(app-sandbox): enable sandbox and migrate file access flows"
```

## Commit 2: plan and QA documentation

**Message**
`docs(plan): update sandbox phases and add QA worksheets`

**Files**

1. `plans/260218-2356-app-sandbox-enablement/plan.md`
2. `plans/260218-2356-app-sandbox-enablement/phase-01-entitlements-and-build-config.md`
3. `plans/260218-2356-app-sandbox-enablement/phase-02-file-access-foundation.md`
4. `plans/260218-2356-app-sandbox-enablement/phase-03-feature-flow-migration.md`
5. `plans/260218-2356-app-sandbox-enablement/phase-04-license-fingerprint-hardening.md`
6. `plans/260218-2356-app-sandbox-enablement/phase-05-verification-and-rollout.md`
7. `plans/260218-2356-app-sandbox-enablement/260219-0022-phase-05-qa-checklist.md`
8. `plans/260218-2356-app-sandbox-enablement/260219-0027-manual-qa-session.md`
9. `plans/260218-2356-app-sandbox-enablement/260219-0027-commit-split-proposal.md`

**Stage command**

```bash
git add plans/260218-2356-app-sandbox-enablement
```

**Commit command**

```bash
git commit -m "docs(plan): update sandbox phases and add QA worksheets"
```

## Post-commit verification

```bash
git status --short
git log --oneline -n 2
```

## Unresolved questions

1. Distribution target policy still undecided (MAS-first vs Developer ID-first).
2. Need decision on dedicated beta cycle before production rollout.
3. Need backend confirmation that device-label format shift is accepted.
