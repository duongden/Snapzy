# Phase 02: Implement Keyboard Handling

## Context Links
- [Main Plan](./plan.md)
- [Previous: Phase 01 - Shortcut Manager](./phase-01-shortcut-manager.md)
- [Next: Phase 03 - Settings UI](./phase-03-settings-ui.md)

## Overview

Add keyboard event handling to the Annotate canvas to switch tools using single-key shortcuts. Uses SwiftUI's `.onKeyPress()` modifier (macOS 14+).

## Key Insights

1. **Text editing guard** - Must check `state.editingTextAnnotationId != nil` before handling
2. **Focus management** - Canvas needs focus to receive key events
3. **Event propagation** - Return `.handled` to consume event, `.ignored` to pass through

## Requirements

- Handle key presses only when Annotate window is active
- Skip shortcut handling during text annotation editing
- Switch `state.selectedTool` when matching key pressed
- Support lowercase key matching (case-insensitive)

## Related Code Files

| File | Purpose |
|------|---------|
| `Snapzy/Features/Annotate/Views/AnnotateCanvasView.swift` | Add keyboard handling |
| `Snapzy/Features/Annotate/State/AnnotateState.swift` | Check `editingTextAnnotationId` |
| `Snapzy/Core/AnnotateShortcutManager.swift` | Lookup tool for key |

## Implementation Steps

### Step 1: Add onKeyPress modifier to AnnotateCanvasView

In `AnnotateCanvasView.swift`, add keyboard handling to the main body:

```swift
var body: some View {
    GeometryReader { geometry in
        ZStack {
            if state.hasImage {
                canvasContent(in: geometry.size)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                AnnotateDropZoneView(isDragOver: $isDragOver)
            }
        }
        .onScrollWheelZoom { delta in
            guard state.hasImage else { return }
            let newZoom = state.zoomLevel + delta * 0.1
            state.zoomLevel = min(max(newZoom, 0.25), 3.0)
        }
        .onDrop(of: [.fileURL, .image], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        // NEW: Keyboard shortcut handling
        .onKeyPress { keyPress in
            handleToolShortcut(keyPress)
        }
        .overlay(alignment: .bottom) {
            if showDropError {
                dropErrorBanner
            }
        }
    }
}
```

### Step 2: Add shortcut handling method

Add this method to `AnnotateCanvasView`:

```swift
// MARK: - Keyboard Shortcuts

/// Handle tool switching keyboard shortcuts
private func handleToolShortcut(_ keyPress: KeyPress) -> KeyPress.Result {
    // Skip if editing text annotation
    guard state.editingTextAnnotationId == nil else {
        return .ignored
    }

    // Skip if no image loaded
    guard state.hasImage else {
        return .ignored
    }

    // Get lowercase character for case-insensitive matching
    guard let char = keyPress.characters.lowercased().first else {
        return .ignored
    }

    // Look up tool for this key
    guard let tool = AnnotateShortcutManager.shared.tool(for: char) else {
        return .ignored
    }

    // Special handling for crop tool
    if tool == .crop {
        state.selectedTool = .crop
        if state.cropRect == nil && state.hasImage {
            state.initializeCrop()
        } else if state.cropRect != nil {
            state.isCropActive = true
        }
    } else {
        state.selectedTool = tool
    }

    return .handled
}
```

## Todo List

- [ ] Add `.onKeyPress()` modifier to AnnotateCanvasView body
- [ ] Implement `handleToolShortcut(_:)` method
- [ ] Add text editing guard check
- [ ] Add special crop tool handling (matches existing toolbar behavior)
- [ ] Test all 11 tool shortcuts

## Success Criteria

- [ ] Pressing 'v' switches to selection tool
- [ ] Pressing 'r' switches to rectangle tool
- [ ] Shortcuts ignored when editing text annotation
- [ ] Shortcuts ignored when no image loaded
- [ ] Crop tool initializes crop rect like toolbar button

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Focus issues | Medium | Medium | Canvas is main view, should have focus by default |
| Conflict with TextField | Low | Medium | Text editing guard prevents this |

## Next Steps

Proceed to [Phase 03: Settings UI](./phase-03-settings-ui.md).
