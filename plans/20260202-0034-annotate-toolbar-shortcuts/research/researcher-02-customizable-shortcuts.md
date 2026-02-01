# Research: Customizable Keyboard Shortcuts for Annotation Tools

**Research Date:** 2026-02-02
**Focus:** macOS annotation toolbar keyboard shortcuts implementation patterns

---

## 1. Storage Pattern: UserDefaults

**Key Approach:**
- Store shortcuts as structured data in UserDefaults (recommended limit: <512KB total)
- Use codable structs for shortcut configuration (key code + modifier flags)
- Employ meaningful, namespaced keys to prevent conflicts
- Never store sensitive data; UserDefaults is unencrypted

**Recommended Structure:**
```swift
struct ShortcutConfig: Codable {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let identifier: String
}
```

**Storage Keys Pattern:**
- `snapzy.shortcuts.annotate.arrow`
- `snapzy.shortcuts.annotate.rectangle`
- `snapzy.shortcuts.annotate.text`

**Best Practice:** Use `@AppStorage` property wrapper in SwiftUI for automatic UserDefaults synchronization.

---

## 2. Action Mapping Pattern

**Recommended Architecture:**

1. **Central Registry:** Single source mapping shortcut identifiers to actions
2. **Event Interceptor:** NSEvent monitor for global/local shortcut detection
3. **Action Dispatcher:** Execute corresponding toolbar tool activation

**Implementation Pattern:**
```swift
enum AnnotationTool: String, CaseIterable {
    case arrow, rectangle, ellipse, text, blur, highlight
}

class ShortcutActionMapper {
    private var registry: [ShortcutConfig: AnnotationTool]

    func execute(shortcut: ShortcutConfig) {
        guard let tool = registry[shortcut] else { return }
        activateTool(tool)
    }
}
```

**Global Shortcut Support:** Use third-party package `KeyboardShortcuts` (github.com/sindresorhus/KeyboardShortcuts) for system-wide shortcuts when app is not frontmost.

---

## 3. UI Pattern for Settings

**Based on Existing ShortcutsSettingsView Analysis:**

Current implementation shows:
- ShortcutRecorderView component for user input
- Grouped sections by feature category
- Real-time state binding with `@State`
- KeyboardShortcutManager singleton for coordination

**Enhancement Recommendations:**

1. **Visual Conflict Indicator:** Show warning badge when shortcut conflicts detected
2. **Shortcut Preview:** Display current key combination in human-readable form (e.g., "⌘⇧A")
3. **Search/Filter:** For large shortcut lists, add search functionality
4. **Reset Individual:** Allow per-shortcut reset, not just global reset
5. **Import/Export:** Enable shortcut scheme sharing for teams

**UI Components:**
- Form with grouped sections (already implemented)
- ShortcutRecorderView for capture (already implemented)
- Conflict warning alerts (needs implementation)
- Visual key combination display with symbols

---

## 4. Conflict Detection Strategy

**Challenge:** macOS provides no native API for programmatic conflict detection with system/other apps.

**Practical Approaches:**

1. **Internal Conflicts:** Check against other app shortcuts before saving
2. **Known System Shortcuts:** Maintain hardcoded list of common macOS shortcuts (⌘Q, ⌘W, ⌘C, ⌘V, etc.)
3. **Warning System:** Alert user of potential conflicts; let them decide
4. **Validation on Record:** In ShortcutRecorderView, validate immediately during capture

**Known System Conflicts to Block:**
- ⌘Q (Quit), ⌘W (Close), ⌘H (Hide)
- ⌘C/V/X (Copy/Paste/Cut)
- ⌘Tab (App Switcher)
- ⌘Space (Spotlight)
- Ctrl+Arrow keys (Mission Control)

**Implementation:**
```swift
func validateShortcut(_ shortcut: ShortcutConfig) -> ValidationResult {
    // Check system reserved
    // Check internal duplicates
    // Return warning or error
}
```

---

## 5. Industry Standard Default Shortcuts

**Analysis of CleanShot X, Snagit, XerahS:**

### Annotation Tool Defaults:

| Tool | Recommended Shortcut | Alternative | Source |
|------|---------------------|-------------|---------|
| **Arrow** | A | ⌘1 | Snagit, XerahS |
| **Rectangle** | R | ⌘2 | Snagit, XerahS |
| **Ellipse/Circle** | O | ⌘3 | Common pattern |
| **Line** | L | ⌘4 | Common pattern |
| **Text** | T | ⌘5 | Industry standard |
| **Blur** | B | ⌘6 | Snipaste |
| **Highlight** | H | ⌘7 | Common pattern |
| **Pen/Draw** | P | ⌘8 | Common pattern |
| **Magnify** | M | ⌘9 | Snagit |
| **Select/Move** | V | ⌘0 | XerahS, design tools |

### Editor Actions:

| Action | Shortcut | Notes |
|--------|----------|-------|
| **Open Annotation** | ⌘E | CleanShot X standard |
| **Save** | ⌘S | Universal |
| **Copy** | ⌘C | Universal |
| **Close** | ⌘W | Universal |
| **Undo** | ⌘Z | Universal |
| **Delete Selected** | Delete/Backspace | Universal |
| **Enter Draw Mode** | ⌃⇧D | Snagit |

**Modifier Key Patterns:**
- Single letter keys (A, R, T) for quick tool switching within annotation mode
- ⌘+Number (⌘1-9) as alternatives for users preferring numbered shortcuts
- Avoid Ctrl+Arrow combinations (conflicts with Mission Control)

---

## 6. Recommended Implementation Plan

**Phase 1: Data Layer**
- Define ShortcutConfig struct with Codable conformance
- Create AnnotationToolShortcutManager (similar to KeyboardShortcutManager)
- Implement UserDefaults storage with default values

**Phase 2: Conflict Detection**
- Build validator for system shortcut conflicts
- Implement internal duplicate detection
- Add validation to ShortcutRecorderView

**Phase 3: UI Enhancement**
- Add annotation shortcuts section to ShortcutsSettingsView
- Display conflict warnings inline
- Show visual key preview with macOS symbols

**Phase 4: Event Handling**
- Create NSEvent monitor for annotation window
- Map shortcuts to AnnotationTool enum
- Dispatch to toolbar selection logic

---

## 7. Code Integration Points

**Existing Files to Modify:**
- `ShortcutsSettingsView.swift` - Add annotation tools section
- `KeyboardShortcutManager.swift` - Extend or create parallel manager

**New Files to Create:**
- `AnnotationToolShortcutManager.swift` - Annotation-specific shortcut handling
- `ShortcutValidator.swift` - Conflict detection logic
- `AnnotationTool.swift` - Enum defining all annotation tools

---

## Sources

- [SwiftUI Keyboard Shortcuts Guide](https://itnext.io)
- [UserDefaults Best Practices](https://sarunw.com)
- [KeyboardShortcuts Package](https://github.com)
- [CleanShot X Documentation](https://devontechnologies.com)
- [Snagit Keyboard Shortcuts](https://avid.com)
- [XerahS Annotation Tools](https://github.com)
- [Snipaste Features](https://snipaste.com)
- [macOS Shortcut Conflicts Discussion](https://reddit.com)
- [AppKit NSEvent Handling](https://stackoverflow.com)

---

## Unresolved Questions

1. Should annotation shortcuts work globally (system-wide) or only when annotation window is active?
2. Do we support shortcut "chords" (sequential key presses) or only simultaneous combinations?
3. Should we allow single-key shortcuts (like "A" for arrow) or require modifiers?
4. How to handle shortcut changes when annotation session is active?
