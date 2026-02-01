# SwiftUI Keyboard Handling Research - macOS In-App Shortcuts

**Date:** 2026-02-02
**Context:** Implementing single-key shortcuts (V, R, etc.) for annotation tool selection in Snapzy
**Target:** macOS 14.0+ (Sonoma), SwiftUI

## Approach Comparison

### 1. `.keyboardShortcut()` Modifier

**Usage:**
```swift
Button("Selection Tool") {
    state.selectedTool = .selection
}
.keyboardShortcut("v", modifiers: [])
```

**Pros:**
- Pure SwiftUI, declarative
- Automatic accessibility support
- Localization-aware (keyboard layout adaptation)
- Simple implementation

**Cons:**
- Requires Button/View as target
- May default to Command (⌘) modifier if not explicit
- Can interfere with text input fields
- Limited to focusable controls

**Best For:** Standard shortcuts with modifier keys in toolbar/menu contexts

---

### 2. `.onKeyPress()` Modifier (macOS 14+)

**Usage:**
```swift
struct AnnotateView: View {
    @FocusState private var isFocused: Bool
    @ObservedObject var state: AnnotateState

    var body: some View {
        canvas
            .focusable()
            .focused($isFocused)
            .onKeyPress { keyPress in
                guard !state.isEditingText else { return .ignored }

                switch keyPress.charactersIgnoringModifiers.lowercased() {
                case "v":
                    state.selectedTool = .selection
                    return .handled
                case "r":
                    state.selectedTool = .rectangle
                    return .handled
                case "o":
                    state.selectedTool = .oval
                    return .handled
                case "a":
                    state.selectedTool = .arrow
                    return .handled
                case "l":
                    state.selectedTool = .line
                    return .handled
                case "t":
                    state.selectedTool = .text
                    return .handled
                case "h":
                    state.selectedTool = .highlighter
                    return .handled
                case "b":
                    state.selectedTool = .blur
                    return .handled
                case "p":
                    state.selectedTool = .pencil
                    return .handled
                default:
                    return .ignored
                }
            }
    }
}
```

**Advanced with phases:**
```swift
.onKeyPress(phases: .down) { keyPress in
    // Only trigger on key down, not repeats
    return handleKeyPress(keyPress)
}
```

**Pros:**
- Pure SwiftUI solution
- Fine-grained control (phases: .down, .up, .repeat)
- Returns .handled/.ignored for event propagation control
- Modern, declarative API
- Can check modifier state via keyPress.modifiers

**Cons:**
- Requires view focus (.focusable() + @FocusState)
- macOS 14+ only
- Focus management complexity
- View must be actively focused

**Best For:** Context-aware shortcuts in focused views (canvas/editor areas)

---

### 3. NSEvent Local Monitor

**Usage:**
```swift
class KeyboardMonitor: ObservableObject {
    private var monitor: Any?
    var onKeyPress: ((String) -> Void)?

    init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Skip if modifier keys pressed
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifiers = !modifiers.subtracting([.capsLock, .numericPad, .function]).isEmpty

            guard !hasModifiers,
                  let chars = event.charactersIgnoringModifiers?.lowercased()
            else { return event }

            self?.onKeyPress?(chars)
            return event
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// In AnnotateView
@StateObject private var keyMonitor = KeyboardMonitor()

.onAppear {
    keyMonitor.onKeyPress = { char in
        guard !state.isEditingText else { return }

        switch char {
        case "v": state.selectedTool = .selection
        case "r": state.selectedTool = .rectangle
        case "o": state.selectedTool = .oval
        // ... etc
        default: break
        }
    }
}
```

**Checking modifier flags:**
```swift
let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
let hasModifiers = !modifiers.subtracting([.capsLock, .numericPad, .function]).isEmpty
```

**Pros:**
- Works without explicit focus requirements
- App-wide key monitoring
- Maximum control over event handling
- Can filter modifier keys precisely
- Works regardless of SwiftUI view hierarchy

**Cons:**
- AppKit bridging required
- Manual lifecycle management (monitor cleanup)
- More boilerplate code
- Not SwiftUI-native
- Must handle text field conflicts manually

**Best For:** App-wide shortcuts that need to work regardless of focus state

---

## Recommended Approach for Snapzy Annotation Tools

**Hybrid Strategy:**

1. **Primary: `.onKeyPress()` on canvas view** - Modern, SwiftUI-native
   - Attach to main canvas/content area
   - Check `state.isEditingText` to avoid conflicts
   - Return `.handled` to stop propagation

2. **Fallback: NSEvent monitor** if focus management proves complex
   - Use for window-level shortcuts
   - Filter out events when text fields active

**Implementation Priority:**
```swift
// Recommended structure
struct AnnotateCanvasView: View {
    @FocusState private var isCanvasFocused: Bool
    @ObservedObject var state: AnnotateState

    var body: some View {
        ZStack {
            // Canvas content
        }
        .focusable()
        .focused($isCanvasFocused)
        .onKeyPress(phases: .down) { keyPress in
            handleToolShortcut(keyPress)
        }
        .onAppear {
            isCanvasFocused = true // Auto-focus canvas
        }
    }

    private func handleToolShortcut(_ keyPress: KeyPress) -> KeyPress.Result {
        guard !state.isEditingText else { return .ignored }

        let key = keyPress.charactersIgnoringModifiers.lowercased()
        // Map keys to tools...
        return .handled
    }
}
```

---

## Key Mappings Suggestion

| Key | Tool | Mnemonic |
|-----|------|----------|
| V | Selection | "V" arrow shape |
| R | Rectangle | Rectangle |
| O | Oval | Oval |
| A | Arrow | Arrow |
| L | Line | Line |
| T | Text | Text |
| H | Highlighter | Highlighter |
| B | Blur | Blur |
| C | Counter | Counter |
| P | Pencil | Pencil |
| Esc | Deselect | Cancel action |
| ⌘Z | Undo | Standard |
| ⌘⇧Z | Redo | Standard |

---

## Text Input Conflict Handling

**Critical:** Must prevent shortcuts when editing text fields.

```swift
// In AnnotateState
@Published var isEditingText: Bool = false

// In text tool view
TextField("Enter text", text: $text, onEditingChanged: { editing in
    state.isEditingText = editing
})
```

---

## Sources

- [SwiftUI keyboardShortcut - Sarunw](https://sarunw.com)
- [SwiftUI keyboard shortcuts - SwiftWithMajid](https://swiftwithmajid.com)
- [Apple KeyboardShortcut Documentation](https://developer.apple.com/documentation/swiftui/keyboardshortcut)
- [SwiftUI onKeyPress - Avanderlee](https://avanderlee.com)
- [CreateWithSwift onKeyPress Guide](https://createwithswift.com)
- [NSEvent Monitoring - Swiftjectivec](https://swiftjectivec.com)
- [Stack Overflow: KeyEquivalent without modifiers](https://stackoverflow.com)

---

## Unresolved Questions

1. Performance impact of `.onKeyPress()` vs NSEvent monitor in complex canvas views?
2. Focus restoration after modal dialogs (e.g., color picker) - does canvas auto-refocus?
3. Accessibility: Should shortcuts be announced via VoiceOver?
