# Phase 02: Update AnnotateWindow

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** Phase 01 (Create Extension)
- **Blocked By:** phase-01-create-extension.md

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-26 |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

**Description:** Refactor AnnotateWindow to use new traffic light extension, removing duplicated positioning logic.

## Key Insights

1. Current `layoutIfNeeded()` override contains 30+ lines of positioning code
2. After refactor, it will call single extension method
3. Keep `layoutIfNeeded()` override but delegate to extension

## Requirements

1. Remove inline traffic light positioning logic
2. Call `layoutTrafficLights()` from `layoutIfNeeded()`
3. Maintain exact same visual behavior

## Architecture

```swift
// Before (AnnotateWindow.swift)
override func layoutIfNeeded() {
    super.layoutIfNeeded()
    // 25 lines of positioning code
}

// After
override func layoutIfNeeded() {
    super.layoutIfNeeded()
    layoutTrafficLights()
}
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Features/Annotate/Window/AnnotateWindow.swift` | Target file |
| `ClaudeShot/Core/NSWindow+TrafficLights.swift` | New extension |

## Implementation Steps

- [ ] Import extension (automatic via same module)
- [ ] Replace inline logic with `layoutTrafficLights()` call
- [ ] Remove unused local variables
- [ ] Test visual appearance matches original

## Todo List

```
[ ] Simplify layoutIfNeeded() in AnnotateWindow.swift
[ ] Verify traffic light positioning unchanged
[ ] Build and run to confirm no regressions
```

## Success Criteria

- AnnotateWindow compiles successfully
- Traffic light buttons positioned identically to before
- Code reduced from ~30 lines to ~2 lines in layoutIfNeeded()

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Visual regression | Low | Medium | Manual visual testing |

## Security Considerations

None.

## Next Steps

- VideoEditorWindow can adopt extension when it needs traffic light customization
- Other windows (RecordingToolbarWindow, etc.) can also adopt as needed
