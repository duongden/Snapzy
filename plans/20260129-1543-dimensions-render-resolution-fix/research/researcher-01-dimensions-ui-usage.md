# Research: Dimensions UI Frame Usage

**Date:** 2026-01-29
**Focus:** Identify where dimension settings incorrectly affect UI layout vs render resolution

---

## Key Findings

### 1. VideoExportSettingsPanel - NO UI Frame Issues Found

**File:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/VideoEditor/Views/VideoExportSettingsPanel.swift`

**Analysis:** Settings panel correctly uses dimension values ONLY for:
- Export calculations (lines 112-115)
- Display labels (lines 93, 240-242)
- Custom field bindings (lines 261-291)

**NO problematic `.frame()` modifiers using dimension settings detected.**

Hard-coded UI frames (safe):
- Line 20: `.frame(height: 80)` - Divider
- Line 26: `.frame(height: 80)` - Divider
- Line 98: `.frame(minWidth: 160)` - Picker control
- Line 130: `.frame(width: 60)` - Width TextField
- Line 146: `.frame(width: 60)` - Height TextField
- Line 186: `.frame(width: 28, height: 24)` - Audio button
- Line 205: `.frame(width: 80)` - Volume slider
- Line 212: `.frame(width: 32, alignment: .trailing)` - Volume label

### 2. Dimension Flow (Settings Panel)

**Dimension Preset Binding (lines 246-259):**
```swift
private var dimensionPresetBinding: Binding<ExportDimensionPreset> {
  Binding(
    get: { state.exportSettings.dimensionPreset },
    set: { newValue in
      var settings = state.exportSettings
      settings.dimensionPreset = newValue
      if newValue == .custom {
        settings.customWidth = Int(state.naturalSize.width)
        settings.customHeight = Int(state.naturalSize.height)
      }
      state.updateExportSettings(settings)
    }
  )
}
```

**Width/Height Bindings (lines 261-291):**
- Update `settings.customWidth/customHeight`
- Call `state.updateExportSettings(settings)`
- Handle aspect ratio locking

**Critical:** Settings panel only READS dimensions for display/calculation, doesn't apply to UI frames.

### 3. Search Results Summary

**`.frame()` modifier search:** 143KB output, mostly ContentView.swift and unrelated components
- No matches for `exportWidth|exportHeight|renderWidth|renderHeight|videoWidth|videoHeight`
- No matches for `@State` declarations with dimension/resolution naming
- No matches for `.frame(width: *exportSettings` or `.frame(height: *exportSettings`

### 4. Missing Investigation Areas

**Not found in 5 tool calls:**
- VideoEditor main view structure
- VideoEditorState.swift dimension property usage in UI
- Any view that might use `state.exportSettings.exportSize()` in `.frame()` modifiers
- Player/preview components that might incorrectly use export dimensions

---

## Conclusions

**VideoExportSettingsPanel:** Clean - no UI frame bugs detected.

**Bug likely resides in:**
1. VideoEditor main view that hosts the settings panel
2. Preview/player components using export dimensions for UI sizing
3. State bindings that propagate dimension changes to view frames

**Next steps:**
- Search VideoEditor view hierarchy for `.frame()` usage with state dimensions
- Check VideoEditorState for @Published properties that might trigger UI resizing
- Examine preview/player views for incorrect dimension binding

---

## Code References

**VideoExportSettingsPanel.swift:**
- Lines 84-109: dimensionsSection (UI only)
- Lines 91-98: Picker with preset labels
- Lines 126-149: Custom dimension TextFields (60px fixed width)
- Lines 246-291: Bindings that update state.exportSettings

**No dimension-to-UI-frame binding detected in this file.**
