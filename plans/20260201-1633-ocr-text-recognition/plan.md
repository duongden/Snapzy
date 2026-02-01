# OCR Text Recognition Implementation Plan

**Date:** 2026-02-01
**Status:** Completed ✅
**Priority:** High
**Target:** macOS 14.0+

## Overview

Add native OCR text recognition to Snapzy using Vision framework's `VNRecognizeTextRequest`. User selects screen area, text is extracted and copied to clipboard with audio feedback.

## Architecture

```
[Shortcut/Menu] --> [AreaSelectionController] --> [OCRService] --> [Clipboard + Sound]
```

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | OCR Service | ✅ Completed | [phase-01-ocr-service.md](./phase-01-ocr-service.md) |
| 2 | Shortcut Integration | ✅ Completed | [phase-02-shortcut-integration.md](./phase-02-shortcut-integration.md) |
| 3 | MenuBar Integration | ✅ Completed | [phase-03-menubar-integration.md](./phase-03-menubar-integration.md) |
| 4 | Sound & Clipboard | ✅ Completed | [phase-04-sound-clipboard.md](./phase-04-sound-clipboard.md) |

## Key Decisions

- **Vision Framework**: Native, on-device, privacy-first OCR
- **Recognition Level**: `.accurate` mode with language correction
- **Default Shortcut**: Cmd+Shift+2 (follows existing Cmd+Shift+3/4/5 pattern)
- **Feedback**: Glass sound on success, Basso on failure

## Dependencies

- Existing `AreaSelectionController` for region selection
- Existing `KeyboardShortcutManager` pattern for hotkey registration
- Existing `QuickAccessSound` for audio feedback
- Screen Recording permission (already required)

## Success Criteria

1. OCR captures text from selected screen region
2. Recognized text copied to clipboard
3. Shortcut customizable in Settings
4. Menu item visible in StatusBar
5. Audio feedback on completion

## Estimated Effort

- Phase 1: 2-3 hours (OCR service core)
- Phase 2: 1-2 hours (shortcut integration)
- Phase 3: 0.5-1 hour (menu item)
- Phase 4: 0.5-1 hour (polish)
- **Total: 4-7 hours**
