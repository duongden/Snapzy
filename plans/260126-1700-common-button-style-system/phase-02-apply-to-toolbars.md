# Phase 2: Apply to Toolbar Views

**Parent Plan:** [plan.md](./plan.md)
**Research:** [Existing Button Analysis](./research/researcher-02-existing-button-analysis.md)

## Overview

Replace existing `.bordered` and `.borderedProminent` button styles with new `CommonButtonStyle` in toolbar views.

## Requirements

1. Update AnnotateToolbarView actionButtons
2. Update VideoEditorToolbarView Save button
3. Maintain visual consistency with current appearance
4. Preserve keyboard shortcuts and disabled states

## Files to Update

### 1. AnnotateToolbarView.swift

**Path:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/Annotate/Views/AnnotateToolbarView.swift`

**Current Code (lines 131-146):**
```swift
private var actionButtons: some View {
    HStack(spacing: 8) {
        Button("Save as...") {
            saveAs()
        }
        .buttonStyle(.bordered)
        .rounded()

        Button("Done") {
            done()
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .rounded()
    }
}
```

**Updated Code:**
```swift
private var actionButtons: some View {
    HStack(spacing: 8) {
        Button("Save as...") {
            saveAs()
        }
        .buttonStyle(.secondary)

        Button("Done") {
            done()
        }
        .buttonStyle(.primary)
    }
}
```

**Changes:**
- Remove `.rounded()` - CommonButtonStyle includes 6pt corner radius
- Remove `.tint(.blue)` - `.primary` uses accentColor by default
- Replace `.bordered` with `.secondary`
- Replace `.borderedProminent` with `.primary`

### 2. VideoEditorToolbarView.swift

**Path:** `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Features/VideoEditor/Views/VideoEditorToolbarView.swift`

**Current Code (lines 158-167):**
```swift
// Save button (primary)
Button(action: onSave) {
    Text("Save")
        .font(.system(size: 13, weight: .medium))
        .frame(minWidth: 60)
}
.buttonStyle(.borderedProminent)
.keyboardShortcut("s", modifiers: [.command])
.disabled(!state.hasUnsavedChanges)
```

**Updated Code:**
```swift
// Save button (primary)
Button(action: onSave) {
    Text("Save")
        .frame(minWidth: 60)
}
.buttonStyle(.primary)
.keyboardShortcut("s", modifiers: [.command])
.disabled(!state.hasUnsavedChanges)
```

**Changes:**
- Remove manual `.font()` - CommonButtonStyle sets font based on size
- Keep `.frame(minWidth: 60)` for consistent button width
- Replace `.borderedProminent` with `.primary`
- Preserve keyboard shortcut and disabled state

## Implementation Steps

### Step 1: Update AnnotateToolbarView

1. Open `AnnotateToolbarView.swift`
2. Locate `actionButtons` computed property (line 131)
3. Replace implementation with updated code
4. Build and verify appearance

### Step 2: Update VideoEditorToolbarView

1. Open `VideoEditorToolbarView.swift`
2. Locate `rightSection` computed property (line 144)
3. Find Save button (line 158)
4. Replace implementation with updated code
5. Build and verify appearance

### Step 3: Visual Verification

Compare before/after screenshots:
- Button height matches (28pt)
- Corner radius consistent (6pt)
- Blue fill color for primary
- Outlined appearance for secondary
- Hover states work
- Pressed states work
- Disabled state reduces opacity

## Testing Checklist

- [ ] AnnotateToolbarView builds without errors
- [ ] VideoEditorToolbarView builds without errors
- [ ] "Save as..." button has outlined appearance
- [ ] "Done" button has blue filled appearance
- [ ] "Save" button has blue filled appearance
- [ ] Keyboard shortcut Cmd+S still works
- [ ] Disabled state grays out Save button
- [ ] Hover shows visual feedback
- [ ] Press reduces opacity

## Rollback Plan

If issues arise, revert to original button styles:
```swift
// AnnotateToolbarView
.buttonStyle(.bordered)
.rounded()
// and
.buttonStyle(.borderedProminent)
.tint(.blue)
.rounded()

// VideoEditorToolbarView
.buttonStyle(.borderedProminent)
```

## Success Criteria

1. Both toolbar files compile without errors
2. Visual appearance matches or improves current design
3. All interactive states (hover, press, disabled) work
4. No regression in functionality (save actions, keyboard shortcuts)
