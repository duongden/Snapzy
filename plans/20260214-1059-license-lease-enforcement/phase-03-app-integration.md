# Phase 03 — App Integration & Enforcement

**Parent**: [plan.md](plan.md)
**Dependencies**: [Phase 01](phase-01-lease-model-and-cache.md), [Phase 02](phase-02-lease-lifecycle-engine.md)
**Date**: 2026-02-14
**Priority**: High
**Implementation Status**: ⬜ Not Started
**Review Status**: ⬜ Pending

## Overview

Wire the lease engine into the app lifecycle: foreground re-validation, license invalidation notification ​→ forced license screen, and add the notification name extension.

## Key Insights

- AppDelegate is the right place for app lifecycle hooks
- `NSWorkspace.didActivateApplicationNotification` fires when Snapzy becomes frontmost
- Foreground check calls `renewLease()` which short-circuits if lease valid → no redundant API calls
- Notification-driven architecture decouples LicenseManager from UI

## Requirements

1. Validate lease when app returns to foreground
2. Show License Activation screen immediately when license is invalidated
3. Don't trigger redundant API calls on rapid Cmd+Tab switches

## Related Code Files

- [SnapzyApp.swift](file:///Users/duongductrong/Developer/ZapShot/Snapzy/App/SnapzyApp.swift) — modify

## Implementation Steps

### Step 1: Add notification name

```swift
extension Notification.Name {
    static let licenseInvalidated = Notification.Name("licenseInvalidated")
}
```

Add to the existing `Notification.Name` extension in `SnapzyApp.swift`.

### Step 2: Add lifecycle observers in `applicationDidFinishLaunching`

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // ... existing setup code ...

    // Validate license on launch (renew lease if expired)
    Task { await LicenseManager.shared.renewLease() }

    // Re-validate when app comes to foreground
    NSWorkspace.shared.notificationCenter.addObserver(
        self,
        selector: #selector(appDidActivate(_:)),
        name: NSWorkspace.didActivateApplicationNotification,
        object: nil
    )

    // Force license screen when license invalidated
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleLicenseInvalidated),
        name: .licenseInvalidated,
        object: nil
    )
}
```

### Step 3: Implement handler methods

```swift
@objc private func appDidActivate(_ notification: Notification) {
    // Only trigger when OUR app becomes active
    guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
          app.bundleIdentifier == Bundle.main.bundleIdentifier else { return }

    Task { await LicenseManager.shared.renewLease() }
}

@objc private func handleLicenseInvalidated() {
    SplashWindowController.shared.showLicenseActivation()
}
```

## Todo

- [ ] Add `.licenseInvalidated` notification name
- [ ] Add `NSWorkspace.didActivateApplicationNotification` observer
- [ ] Add `.licenseInvalidated` observer
- [ ] Implement `appDidActivate` with bundle ID guard
- [ ] Implement `handleLicenseInvalidated` → show license screen
- [ ] Add launch-time `renewLease()` call

## Success Criteria

- Switching to Snapzy via Cmd+Tab triggers lease check (no-op if valid)
- Disabling license in Polar → within 15 min, License Activation screen appears
- Rapidly Cmd+Tab switching doesn't flood API (lease short-circuit)

## Risk Assessment

- **Low**: Simple observer pattern, well-tested macOS APIs
- `appDidActivate` filters by bundle ID → won't trigger for other apps activating

## Security Considerations

- Notification is internal (`NotificationCenter.default`) — no external manipulation
- `showLicenseActivation()` presents non-closable window (existing behavior)

## Next Steps

→ [Phase 04 — Verification](phase-04-verification.md)
