# Phase 01: Create VideoEditorBottomBar Component

## Context
- Parent: [plan.md](plan.md)
- Dependencies: None

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Priority | High |
| Implementation Status | ⬜ Pending |
| Review Status | ⬜ Pending |

## Description
Create new `VideoEditorBottomBar.swift` view with Cancel and Convert buttons.

## Key Insights
- Follow existing toolbar pattern from `VideoEditorToolbarView.swift`
- Use `WindowSpacingConfiguration` for consistent padding
- Convert button uses `.borderedProminent` style (like current Save)
- Cancel button uses plain/secondary style

## Requirements
1. HStack layout with Spacer between buttons
2. Cancel button: left, plain style, calls `onCancel`
3. Convert button: right, `.borderedProminent`, calls `onConvert`
4. Convert button always enabled (no disabled state)
5. ⌘S keyboard shortcut on Convert button

## Related Code Files
- Reference: [VideoEditorToolbarView.swift](../../ClaudeShot/Features/VideoEditor/Views/VideoEditorToolbarView.swift) - Button styling patterns
- Target: `ClaudeShot/Features/VideoEditor/Views/VideoEditorBottomBar.swift`

## Implementation Steps

### Step 1: Create file structure
```swift
// VideoEditorBottomBar.swift
import SwiftUI

struct VideoEditorBottomBar: View {
  var onCancel: () -> Void
  var onConvert: () -> Void

  var body: some View {
    // ...
  }
}
```

### Step 2: Implement layout
```swift
var body: some View {
  HStack {
    // Cancel button (left)
    Button("Cancel", action: onCancel)
      .buttonStyle(.plain)
      .foregroundColor(.secondary)

    Spacer()

    // Convert button (right)
    Button("Convert", action: onConvert)
      .buttonStyle(.borderedProminent)
      .keyboardShortcut("s", modifiers: [.command])
  }
  .padding(.horizontal, WindowSpacingConfiguration.default.toolbarHPadding)
  .padding(.vertical, 12)
}
```

### Step 3: Add Divider at top
Add `Divider()` above HStack to separate from content

## Todo List
- [ ] Create `VideoEditorBottomBar.swift` file
- [ ] Implement Cancel button with plain style
- [ ] Implement Convert button with borderedProminent style
- [ ] Add ⌘S keyboard shortcut
- [ ] Use WindowSpacingConfiguration for padding
- [ ] Add #Preview

## Success Criteria
- [ ] Bottom bar renders with proper spacing
- [ ] Cancel button positioned left
- [ ] Convert button positioned right with primary styling
- [ ] Convert button always clickable (no disabled state)
- [ ] ⌘S triggers Convert action

## Risk Assessment
- Low risk - isolated new component

## Security Considerations
- None - UI only
