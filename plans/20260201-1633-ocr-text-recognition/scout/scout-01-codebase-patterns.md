# Scout Report: Codebase Patterns for OCR Implementation

## Keyboard Shortcuts
| File | Purpose |
|------|---------|
| Core/KeyboardShortcutManager.swift | Main manager for global hotkey registration |
| Core/ShortcutRecorderView.swift | UI component for recording shortcuts |
| Features/Preferences/Tabs/ShortcutsSettingsView.swift | Settings view for configuring shortcuts |
| App/StatusBarController.swift | Contains keyboard shortcut handling logic |

## Screen Capture
| File | Purpose |
|------|---------|
| Core/ScreenCaptureManager.swift | Main capture manager (ScreenCaptureKit/CGWindowListCreateImage) |
| Core/ScreenCaptureViewModel.swift | View model for capture functionality |
| Core/Services/PostCaptureActionHandler.swift | Handles post-capture actions |

## MenuBar
| File | Purpose |
|------|---------|
| App/StatusBarController.swift | Main menu bar/status bar controller |

## Sound/Audio Feedback
| File | Purpose |
|------|---------|
| Features/QuickAccess/QuickAccessSound.swift | Sound effects implementation |
| Features/QuickAccess/QuickAccessManager.swift | Manages quick access with audio feedback |
| Core/Services/PostCaptureActionHandler.swift | Post-capture sound feedback |

## Clipboard/Pasteboard
| File | Purpose |
|------|---------|
| Features/Annotate/Export/AnnotateExporter.swift | Export to clipboard |
| Core/Services/PostCaptureActionHandler.swift | Copy to clipboard after capture |
| Features/QuickAccess/QuickAccessManager.swift | Clipboard operations |

## Key Integration Points
1. **KeyboardShortcutManager** - add OCR shortcut alongside fullscreen/area shortcuts
2. **StatusBarController** - add OCR menu item
3. **QuickAccessSound** - reuse for OCR capture feedback
4. **PostCaptureActionHandler** - pattern for clipboard copy after OCR
