# Phase 01: Create AnnotateShortcutManager

## Context Links
- [Main Plan](./plan.md)
- [Next: Phase 02 - Keyboard Handling](./phase-02-keyboard-handling.md)

## Overview

Create a dedicated manager for annotation tool shortcuts. Unlike `KeyboardShortcutManager` which uses Carbon hotkeys for global shortcuts, this manager handles local single-key shortcuts that only work within the Annotate window.

## Key Insights

1. **Simpler than global shortcuts** - No Carbon APIs needed; just store Character mappings
2. **Per-tool storage** - Each tool gets its own UserDefaults key for granular customization
3. **Singleton pattern** - Match existing `KeyboardShortcutManager.shared` pattern
4. **Observable** - Use `@Published` so Settings UI updates reactively

## Requirements

- Store shortcut bindings as `[AnnotationToolType: Character]`
- Persist to UserDefaults with namespaced keys
- Provide lookup by key (for keyboard handling) and by tool (for Settings UI)
- Support clearing individual shortcuts (nil = disabled)
- Conflict detection helper method
- Reset to defaults functionality

## Architecture

```swift
@MainActor
final class AnnotateShortcutManager: ObservableObject {
    static let shared = AnnotateShortcutManager()

    @Published private(set) var shortcuts: [AnnotationToolType: Character]

    // Lookup
    func tool(for key: Character) -> AnnotationToolType?
    func shortcut(for tool: AnnotationToolType) -> Character?

    // Mutation
    func setShortcut(_ key: Character?, for tool: AnnotationToolType)
    func resetToDefaults()

    // Validation
    func conflictingTool(for key: Character, excluding: AnnotationToolType) -> AnnotationToolType?
}
```

## Related Code Files

| File | Purpose |
|------|---------|
| `Snapzy/Core/KeyboardShortcutManager.swift` | Reference for singleton pattern, UserDefaults storage |
| `Snapzy/Features/Annotate/State/AnnotationToolType.swift` | Has existing `shortcut` property to use as defaults |

## Implementation Steps

### Step 1: Update AnnotationToolType with defaultShortcut

Rename existing `shortcut` to `defaultShortcut` for clarity:

```swift
// In AnnotationToolType.swift
var defaultShortcut: Character {
    switch self {
    case .selection: return "v"
    case .crop: return "c"
    case .rectangle: return "r"
    case .oval: return "o"
    case .arrow: return "a"
    case .line: return "l"
    case .text: return "t"
    case .highlighter: return "h"
    case .blur: return "b"
    case .counter: return "n"
    case .pencil: return "p"
    case .mockup: return "m"
    }
}
```

### Step 2: Create AnnotateShortcutManager

Create new file `Snapzy/Core/AnnotateShortcutManager.swift`:

```swift
//
//  AnnotateShortcutManager.swift
//  Snapzy
//
//  Manages keyboard shortcuts for annotation tools (local, single-key)
//

import Foundation

/// Manager for annotation tool keyboard shortcuts
@MainActor
final class AnnotateShortcutManager: ObservableObject {

    static let shared = AnnotateShortcutManager()

    /// Current shortcut bindings (tool -> key)
    @Published private(set) var shortcuts: [AnnotationToolType: Character] = [:]

    /// UserDefaults key prefix
    private let keyPrefix = "annotate.shortcut."

    /// Tools that support shortcuts (excludes mockup - internal only)
    static let configurableTools: [AnnotationToolType] = [
        .selection, .crop, .rectangle, .oval, .arrow,
        .line, .text, .highlighter, .blur, .counter, .pencil
    ]

    private init() {
        loadShortcuts()
    }

    // MARK: - Lookup

    /// Get tool for a given key press
    func tool(for key: Character) -> AnnotationToolType? {
        shortcuts.first { $0.value == key }?.key
    }

    /// Get current shortcut for a tool
    func shortcut(for tool: AnnotationToolType) -> Character? {
        shortcuts[tool]
    }

    // MARK: - Mutation

    /// Set shortcut for a tool (nil to clear)
    func setShortcut(_ key: Character?, for tool: AnnotationToolType) {
        if let key = key {
            shortcuts[tool] = key
        } else {
            shortcuts.removeValue(forKey: tool)
        }
        saveShortcut(for: tool)
    }

    /// Reset all shortcuts to defaults
    func resetToDefaults() {
        for tool in Self.configurableTools {
            shortcuts[tool] = tool.defaultShortcut
            saveShortcut(for: tool)
        }
    }

    // MARK: - Validation

    /// Check if key conflicts with another tool's shortcut
    func conflictingTool(for key: Character, excluding tool: AnnotationToolType) -> AnnotationToolType? {
        shortcuts.first { $0.key != tool && $0.value == key }?.key
    }

    // MARK: - Persistence

    private func loadShortcuts() {
        for tool in Self.configurableTools {
            let key = keyPrefix + tool.rawValue
            if let stored = UserDefaults.standard.string(forKey: key),
               let char = stored.first {
                shortcuts[tool] = char
            } else {
                // Use default if not customized
                shortcuts[tool] = tool.defaultShortcut
            }
        }
    }

    private func saveShortcut(for tool: AnnotationToolType) {
        let key = keyPrefix + tool.rawValue
        if let shortcut = shortcuts[tool] {
            UserDefaults.standard.set(String(shortcut), forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
```

## Todo List

- [ ] Rename `shortcut` to `defaultShortcut` in AnnotationToolType.swift
- [ ] Create AnnotateShortcutManager.swift with singleton, storage, lookup methods
- [ ] Add conflict detection method
- [ ] Add resetToDefaults method
- [ ] Test persistence across app restarts

## Success Criteria

- [ ] Manager loads shortcuts from UserDefaults on init
- [ ] `tool(for:)` returns correct tool for key lookup
- [ ] `setShortcut(_:for:)` persists changes immediately
- [ ] `conflictingTool(for:excluding:)` detects duplicates
- [ ] `resetToDefaults()` restores all defaults
- [ ] Compiles without warnings

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Key collision with system shortcuts | Low | Low | Single keys without modifiers don't conflict with system |
| Migration from existing shortcut property | Low | Low | Keep both properties during transition |

## Security Considerations

- No sensitive data stored
- UserDefaults appropriate for user preferences

## Next Steps

After completing this phase, proceed to [Phase 02: Keyboard Handling](./phase-02-keyboard-handling.md) to wire up the manager to the canvas view.
