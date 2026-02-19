# Phase 01: Entitlements + Build Config

**Parent:** [plan.md](./plan.md)
**Date:** 2026-02-18
**Priority:** Critical
**Implementation Status:** COMPLETED
**Review Status:** IMPLEMENTED, VERIFIED BY DEBUG BUILD

## Goal

Turn sandbox ON in project config and entitlements with minimum required capabilities.

## Current references

- `Snapzy.xcodeproj/project.pbxproj` (`ENABLE_APP_SANDBOX = NO`)
- `Snapzy/Snapzy.entitlements` (`com.apple.security.app-sandbox = false`)

## Requirements

1. Enable App Sandbox for Debug and Release target config
2. Keep microphone entitlement enabled
3. Add network client entitlement for licensing + Sparkle traffic
4. Keep file access principle minimal; user-selected file access only

## Proposed entitlement set

- `com.apple.security.app-sandbox = true`
- `com.apple.security.network.client = true`
- `com.apple.security.files.user-selected.read-write = true`
- `com.apple.security.device.audio-input = true`

## Tasks

- [x] Update target build settings: `ENABLE_APP_SANDBOX = YES` (Debug/Release)
- [x] Update `Snapzy/Snapzy.entitlements` with required keys above
- [x] Confirm no extra entitlements are added without need
- [x] Build once with sandbox enabled to identify immediate compile/runtime blockers

## Success criteria

1. Entitlements signed with sandbox enabled
2. App launches under sandbox
3. License HTTP calls and Sparkle checks are not denied by sandbox

## Risk

- Missing entitlement can produce runtime-deny behavior difficult to spot without log inspection

## Notes

1. Implementation enabled sandbox for both Debug and Release configurations.
