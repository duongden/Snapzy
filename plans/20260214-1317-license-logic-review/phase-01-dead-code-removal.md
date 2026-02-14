# Phase 01: Dead Code Removal

**Parent:** [plan.md](plan.md)
**Date:** 2026-02-14
**Priority:** High
**Status:** ⬜ Pending

## Overview

Remove code that is defined but never used anywhere in the codebase. These are confirmed dead via thorough `grep` searches.

## Targets

### 1. Remove `LicenseTier` enum (LicenseConstants.swift:3-37)

```swift
// ENTIRE ENUM — never referenced outside this file
enum LicenseTier: String, CaseIterable { ... }
```

**Evidence:** No imports, no references in any `.swift` file outside `LicenseConstants.swift`.

### 2. Remove `LicenseEntitlements` struct (LicenseConstants.swift:39-101)

```swift
// ENTIRE STRUCT + extension — never called
struct LicenseEntitlements { ... }
```

**Evidence:**

- `canAccessFeature()` → `grep` returns 0 hits outside the definition
- `shouldShowProFeatures()` → 0 hits outside the definition
- `LicenseState.entitlements` accessor exists (LicenseState.swift:168-177) but is never read

**Also remove from `LicenseState.swift`:**

```swift
// Lines 168-177: dead accessor
extension LicenseState {
    var entitlements: LicenseEntitlements { ... }
}
```

### 3. Remove `NTPTimeProvider` class (TimeValidator.swift:114-153)

```swift
// Never called from any code path
final class NTPTimeProvider { ... }
```

**Also remove:** `NTPError` enum (TimeValidator.swift:156-183)

### 4. Remove `LicenseConfiguration` struct (Models/LicenseConfiguration.swift)

**Entire file** — duplicated by `LicenseConfig` private struct in `LicenseManager.swift:14-31`. This struct is never used.

### 5. Clean up related error cases + methods

After removing entitlements:

- Remove `shouldShowProFeatures()` from `LicenseManager.swift:497-504`
- Remove `canAccessFeature()` from `LicenseManager.swift:512-514`

## Affected Files

| File                                                    | Action                                                       |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| `Snapzy/Core/License/LicenseConstants.swift`            | Delete entire file                                           |
| `Snapzy/Core/License/Models/LicenseConfiguration.swift` | Delete entire file                                           |
| `Snapzy/Core/License/Security/TimeValidator.swift`      | Remove `NTPTimeProvider` + `NTPError` (keep `TimeValidator`) |
| `Snapzy/Core/License/Models/LicenseState.swift`         | Remove `entitlements` extension                              |
| `Snapzy/Core/License/LicenseManager.swift`              | Remove `shouldShowProFeatures()`, `canAccessFeature()`       |

## Risk Assessment

**Low risk** — removing code that is provably never called. No behavioral change.

## Success Criteria

- Project compiles without errors
- No runtime regressions — same behavior as before
