# Phase 03: Settings UI Integration

## Context Links
- [Main Plan](./plan.md)
- [Previous: Phase 02 - Keyboard Handling](./phase-02-keyboard-handling.md)

## Overview

Add "Annotation Tools" section to ShortcutsSettingsView with customizable single-key shortcuts. Create a simpler recorder component since annotation shortcuts don't require modifiers.

## Key Insights

1. **Simpler recorder** - SingleKeyRecorderView only captures one character, no modifiers
2. **Conflict warnings** - Show inline warning when duplicate key detected
3. **Clear option** - Allow removing shortcut entirely (disable for that tool)
4. **Reuse patterns** - Follow existing ShortcutRecorderView styling

## Requirements

- Add "Annotation Tools" section below existing sections
- Show all 11 configurable tools with current shortcut
- Allow recording new single-key shortcut
- Show conflict warning if key already used
- Support clearing shortcut (backspace/delete)
- Reset annotation shortcuts with existing "Reset to Defaults" button

## Related Code Files

| File | Purpose |
|------|---------|
| `Snapzy/Features/Preferences/Tabs/ShortcutsSettingsView.swift` | Add section |
| `Snapzy/Core/ShortcutRecorderView.swift` | Reference for styling |
| `Snapzy/Core/AnnotateShortcutManager.swift` | Data source |

## Implementation Steps

### Step 1: Create SingleKeyRecorderView

Create `Snapzy/Core/SingleKeyRecorderView.swift`:

```swift
//
//  SingleKeyRecorderView.swift
//  Snapzy
//
//  SwiftUI view for recording single-key shortcuts (no modifiers)
//

import AppKit
import SwiftUI

/// View for recording single-key shortcuts
struct SingleKeyRecorderView: View {
    let tool: AnnotationToolType
    @Binding var shortcut: Character?
    let onChanged: (Character?) -> Void
    let conflictingTool: AnnotationToolType?

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(tool.rawValue.capitalized)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // Conflict warning
            if let conflict = conflictingTool {
                Label("Used by \(conflict.rawValue)", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button {
                startRecording()
            } label: {
                Text(displayText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 40)
            }
            .buttonStyle(ShortcutButtonStyle(isRecording: isRecording))
        }
        .padding(.vertical, 2)
        .onDisappear { stopRecording() }
    }

    private var displayText: String {
        if isRecording { return "..." }
        if let key = shortcut { return String(key).uppercased() }
        return "-"
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            // Delete/Backspace clears shortcut
            if event.keyCode == 51 || event.keyCode == 117 {
                shortcut = nil
                onChanged(nil)
                stopRecording()
                return nil
            }

            // Get character (lowercase for consistency)
            if let char = event.charactersIgnoringModifiers?.lowercased().first,
               char.isLetter {
                shortcut = char
                onChanged(char)
                stopRecording()
                return nil
            }

            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
```

### Step 2: Update ShortcutsSettingsView

Add annotation tools section and state:

```swift
// Add to ShortcutsSettingsView properties
@StateObject private var annotateManager = AnnotateShortcutManager.shared

// Add new section after "Tools Shortcuts" section (inside if shortcutsEnabled)
Section("Annotation Tool Shortcuts") {
    Text("Single-key shortcuts for switching tools in the annotation editor.")
        .font(.caption)
        .foregroundColor(.secondary)

    ForEach(AnnotateShortcutManager.configurableTools, id: \.self) { tool in
        let binding = Binding<Character?>(
            get: { annotateManager.shortcut(for: tool) },
            set: { annotateManager.setShortcut($0, for: tool) }
        )

        SingleKeyRecorderView(
            tool: tool,
            shortcut: binding,
            onChanged: { _ in },
            conflictingTool: conflictForTool(tool)
        )
    }

    Text("Click to record. Press Backspace to clear. Esc to cancel.")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.top, 4)
}

// Add helper method
private func conflictForTool(_ tool: AnnotationToolType) -> AnnotationToolType? {
    guard let key = annotateManager.shortcut(for: tool) else { return nil }
    return annotateManager.conflictingTool(for: key, excluding: tool)
}

// Update resetToDefaults() to include annotation shortcuts
private func resetToDefaults() {
    // ... existing resets ...
    annotateManager.resetToDefaults()
}
```

## Todo List

- [ ] Create SingleKeyRecorderView.swift
- [ ] Add @StateObject for AnnotateShortcutManager in ShortcutsSettingsView
- [ ] Add "Annotation Tool Shortcuts" section
- [ ] Implement conflict detection display
- [ ] Update resetToDefaults() to include annotation shortcuts
- [ ] Test recording, clearing, and conflict detection

## Success Criteria

- [ ] All 11 tools displayed in Settings
- [ ] Clicking shows "..." recording state
- [ ] Typing letter assigns shortcut
- [ ] Backspace clears shortcut
- [ ] Escape cancels recording
- [ ] Conflict warning shows when duplicate key used
- [ ] Reset to Defaults resets annotation shortcuts too

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| UI clutter | Low | Low | Collapsed section, minimal per-row UI |
| Recording conflicts with form | Low | Medium | Event monitor consumes events |

## Security Considerations

- No sensitive data involved
- Standard user preference storage

## Next Steps

After all phases complete:
1. Build and test full flow
2. Verify shortcuts work in Annotate editor
3. Verify settings persistence across restarts
