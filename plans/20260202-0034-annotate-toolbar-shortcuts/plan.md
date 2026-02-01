# Annotate Toolbar Keyboard Shortcuts - Implementation Plan

## Summary

Add customizable single-key keyboard shortcuts for switching annotation tools in the Annotate editor. Shortcuts work only when the Annotate window is active and are disabled during text editing. Users can customize bindings via Settings.

## Status: Implementation Complete

| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Create AnnotateShortcutManager | ✅ Done |
| 02 | Implement keyboard handling in canvas | ✅ Done |
| 03 | Add Settings UI integration | ✅ Done |

## Key Decisions

1. **Local shortcuts only** - Use `.onKeyPress()` modifier (macOS 14+) instead of Carbon hotkeys since these only work within the Annotate window
2. **Single Character storage** - Store shortcuts as `Character` (not full ShortcutConfig) since no modifiers needed
3. **Separate manager** - Create `AnnotateShortcutManager` to avoid polluting `KeyboardShortcutManager` which handles global Carbon hotkeys
4. **Text editing guard** - Check `editingTextAnnotationId != nil` before handling shortcuts
5. **Conflict detection** - Warn on duplicate keys; allow clearing shortcuts

## Default Shortcuts

| Tool | Key | Mnemonic |
|------|-----|----------|
| Selection | V | Visual pointer (Photoshop standard) |
| Rectangle | R | Rectangle |
| Oval | O | Oval |
| Arrow | A | Arrow |
| Line | L | Line |
| Text | T | Text |
| Highlighter | H | Highlighter |
| Blur | B | Blur |
| Counter | N | Number |
| Pencil | P | Pencil |
| Crop | C | Crop |

## Architecture Overview

```
AnnotateShortcutManager (new)
  - Stores: [AnnotationToolType: Character]
  - UserDefaults: annotate.shortcut.{toolName}
  - Methods: shortcut(for:), setShortcut(_:for:), resetToDefaults()

AnnotateCanvasView (modified)
  - Add .onKeyPress() modifier
  - Check !isEditingText before handling
  - Call state.selectedTool = matchedTool

ShortcutsSettingsView (modified)
  - Add "Annotation Tools" section
  - Reuse SingleKeyRecorderView (new, simpler than ShortcutRecorderView)
  - Conflict detection UI
```

## Files to Create/Modify

| File | Action |
|------|--------|
| `Snapzy/Core/AnnotateShortcutManager.swift` | Create |
| `Snapzy/Core/SingleKeyRecorderView.swift` | Create |
| `Snapzy/Features/Annotate/Views/AnnotateCanvasView.swift` | Modify |
| `Snapzy/Features/Preferences/Tabs/ShortcutsSettingsView.swift` | Modify |
| `Snapzy/Features/Annotate/State/AnnotationToolType.swift` | Modify (add defaultShortcut) |

## Estimated Effort

- Phase 01: ~1 hour (manager + storage)
- Phase 02: ~30 min (keyboard handling)
- Phase 03: ~1.5 hours (UI + conflict detection)
- **Total: ~3 hours**

## Phase Documents

- [Phase 01: Shortcut Manager](./phase-01-shortcut-manager.md)
- [Phase 02: Keyboard Handling](./phase-02-keyboard-handling.md)
- [Phase 03: Settings UI](./phase-03-settings-ui.md)
