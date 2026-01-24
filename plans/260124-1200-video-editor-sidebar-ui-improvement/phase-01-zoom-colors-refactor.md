# Phase 01: Refactor ZoomColors Enum to Use System Colors

## Context

- **Parent Plan:** [plan.md](./plan.md)
- **Dependencies:** None
- **Related Docs:** Apple HIG macOS Colors

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Description | Replace hardcoded RGB colors in ZoomColors enum with macOS semantic system colors |
| Priority | High (foundation for other phases) |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Not Started |

## Key Insights

1. Current `ZoomColors` enum uses hardcoded RGB values that don't respect user's accent color
2. `NSColor.controlAccentColor` adapts to user's System Preferences accent choice
3. Toolbar already uses `Color.white.opacity(0.1)` - maintain consistency

## Requirements

- Replace `ZoomColors.primary` with system accent color
- Replace `ZoomColors.primaryDark` with darker variant of accent
- Keep `ZoomColors.disabled` as semantic gray
- Ensure colors work in both light/dark mode

## Architecture

```swift
// BEFORE
enum ZoomColors {
  static let primary = Color(red: 0.35, green: 0.55, blue: 0.95)
  static let primaryDark = Color(red: 0.25, green: 0.45, blue: 0.85)
  static let disabled = Color(red: 0.45, green: 0.45, blue: 0.50)
  static let selected = Color.white
  static let handleHighlight = Color.white.opacity(0.8)
}

// AFTER
enum ZoomColors {
  static var primary: Color { Color(NSColor.controlAccentColor) }
  static var primaryDark: Color { Color(NSColor.controlAccentColor).opacity(0.85) }
  static let disabled = Color(NSColor.disabledControlTextColor)
  static let selected = Color.white
  static let handleHighlight = Color.white.opacity(0.8)

  // New semantic colors
  static var background: Color { Color(NSColor.controlBackgroundColor) }
  static var separator: Color { Color(NSColor.separatorColor) }
  static var secondaryLabel: Color { Color(NSColor.secondaryLabelColor) }
  static var tertiaryLabel: Color { Color(NSColor.tertiaryLabelColor) }
}
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ZoomBlockView.swift:12-18` | ZoomColors enum definition |

## Implementation Steps

1. Open `ZoomBlockView.swift`
2. Locate `ZoomColors` enum (lines 12-18)
3. Replace static `let` with computed `var` for dynamic colors
4. Add new semantic color properties
5. Verify no compilation errors

## Todo List

- [ ] Update `primary` to use `NSColor.controlAccentColor`
- [ ] Update `primaryDark` to use opacity variant
- [ ] Update `disabled` to use `NSColor.disabledControlTextColor`
- [ ] Add `background`, `separator`, `secondaryLabel`, `tertiaryLabel`
- [ ] Test in both light and dark mode
- [ ] Verify accent color changes reflect immediately

## Success Criteria

- [ ] ZoomColors uses computed properties for system colors
- [ ] Colors adapt when user changes system accent color
- [ ] No hardcoded RGB values for primary colors
- [ ] Builds without warnings

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Color contrast issues | Low | Medium | Test in both modes |
| Performance from computed vars | Very Low | Low | NSColor is cached |

## Security Considerations

None - UI only changes.

## Next Steps

Proceed to Phase 02: ZoomSettingsPopover redesign
