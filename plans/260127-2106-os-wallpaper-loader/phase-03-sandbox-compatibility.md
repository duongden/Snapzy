# Phase 03: Sandbox Compatibility

## Context

- **Parent Plan**: [plan.md](plan.md)
- **Dependencies**: [phase-01-wallpaper-manager.md](phase-01-wallpaper-manager.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-27 |
| Description | Add sandbox-safe access with fallback to user selection |
| Priority | Medium |
| Implementation Status | Pending |
| Review Status | Pending |

## Key Insights

- `/System/Library/` generally readable even in sandbox
- Access may fail on some systems or future macOS versions
- Graceful fallback via NSOpenPanel preserves functionality

## Requirements

1. Verify read access before enumeration
2. Fallback to NSOpenPanel if access denied
3. Store user-granted access via security-scoped bookmarks (optional)

## Implementation

### Access Verification

```swift
private func canAccessDirectory(_ path: String) -> Bool {
    FileManager.default.isReadableFile(atPath: path)
}
```

### Fallback UI

If system directories inaccessible, show "Grant Access" button that opens NSOpenPanel pointed at `/System/Library/Desktop Pictures/`.

## Todo List

- [ ] Add access verification to SystemWallpaperManager
- [ ] Add fallback NSOpenPanel method
- [ ] Update UI to show "Grant Access" when needed

## Success Criteria

- [ ] Works when sandbox enabled
- [ ] Fallback triggers when access denied
- [ ] User can manually grant folder access
