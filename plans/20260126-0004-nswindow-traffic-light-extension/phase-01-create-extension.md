# Phase 01: Create Traffic Light Extension

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** None
- **Reference:** `ClaudeShot/Core/NSWindow+CornerRadius.swift` (existing pattern)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-26 |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

**Description:** Create new NSWindow extension for traffic light button positioning with configurable parameters.

## Key Insights

1. Current implementation in `AnnotateWindow.swift:70-101` uses hardcoded values
2. Traffic light buttons: close, miniaturize, zoom (standard macOS)
3. Positioning centers buttons vertically with toolbar items
4. Horizontal spacing follows macOS standard (12px from left, 8px between buttons)

## Requirements

1. Create `NSWindow+TrafficLights.swift` in Core folder
2. Define configuration struct for toolbar dimensions
3. Provide sensible defaults matching current AnnotateWindow values
4. Support custom horizontal positioning (optional)

## Architecture

```swift
// Configuration struct
struct TrafficLightConfiguration {
    var toolbarGap: CGFloat = 4
    var toolbarTopPadding: CGFloat = 0
    var toolbarItemHeight: CGFloat = 28
    var horizontalOffset: CGFloat = 12
    var buttonSpacing: CGFloat = 8
}

// Extension method
extension NSWindow {
    func layoutTrafficLights(config: TrafficLightConfiguration = .init())
}
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Core/NSWindow+CornerRadius.swift` | Reference pattern |
| `ClaudeShot/Features/Annotate/Window/AnnotateWindow.swift` | Source of current logic |

## Implementation Steps

- [ ] Create `NSWindow+TrafficLights.swift` file
- [ ] Define `TrafficLightConfiguration` struct with defaults
- [ ] Implement `layoutTrafficLights(config:)` method
- [ ] Add documentation comments

## Todo List

```
[ ] Create file at ClaudeShot/Core/NSWindow+TrafficLights.swift
[ ] Define TrafficLightConfiguration struct
[ ] Implement layoutTrafficLights method
[ ] Add default configuration static property
```

## Success Criteria

- Extension compiles without errors
- Method signature allows flexible configuration
- Default values match current AnnotateWindow behavior

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Private API concerns | Low | Medium | Using public standardWindowButton API |

## Security Considerations

None - UI positioning only.

## Next Steps

After completion, proceed to Phase 02 to update AnnotateWindow.
