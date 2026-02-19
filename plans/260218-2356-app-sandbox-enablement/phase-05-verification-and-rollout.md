# Phase 05: Verification + Rollout

**Parent:** [plan.md](./plan.md)
**Date:** 2026-02-18
**Priority:** Critical
**Implementation Status:** IN PROGRESS
**Review Status:** BUILD VERIFIED, FULL QA PENDING

## Goal

Validate sandbox behavior end-to-end and roll out safely.

## Verification matrix

1. App launch, onboarding, permissions prompt flow
2. Screenshot full/area save to chosen export folder
3. Recording save + GIF conversion + quick access actions
4. Annotate save to original + save as copy
5. Video editor replace original + save as copy
6. Wallpaper loading (system + manually granted folder)
7. License activate/validate/deactivate with network on/off
8. Sparkle check-for-updates
9. Diagnostics log write/read/open folder
10. No first-time permission request appears outside onboarding except explicit recovery path

## Tasks

- [x] Add test checklist doc in this plan folder (manual QA script)
- [x] Run sandbox-enabled build
- [ ] Capture runtime sandbox deny logs across core flows
- [ ] Fix all deny logs that impact core user flows
- [x] Add fallback UX copy where write access can fail
- [x] Verify onboarding includes all required first-time permission asks
- [ ] Gate rollout: Debug -> internal Release -> public Release

## Rollout strategy

1. Enable sandbox in Debug first; stabilize
2. Promote to Release config after QA passes
3. Ship with release note callout: first-run folder regrant may be required

## Exit criteria

- Zero P0/P1 regressions in capture/record/export/license/update flows
- No persistent sandbox deny logs in expected user paths
- Migration from legacy save path verified on clean + upgraded setups

## Risk

- Hidden runtime denies often appear only in real-user file locations; QA coverage must include non-Desktop paths

## Unresolved questions

1. Do we require dedicated beta cycle before production rollout?
