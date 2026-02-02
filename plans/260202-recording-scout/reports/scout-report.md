# Recording & Area Selection Scout Report

## Core Recording Architecture

### Recording Flow Entry Points
- **StatusBarController.swift** - initiates recording mode from menu bar
- **RecordingCoordinator.swift** - orchestrates entire recording flow
- **ScreenRecordingManager.swift** - core ScreenCaptureKit integration
- **RecordingSession.swift** - thread-safe AVAssetWriter management

### Area Selection System

**Primary Implementation:**
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Core/AreaSelectionWindow.swift`
  - Uses window pooling for instant activation (<150ms vs 400-600ms)
  - Pre-allocates overlay windows for all screens on app launch
  - Supports both screenshot and recording modes via `SelectionMode` enum
  - Controller: `AreaSelectionController.shared`
  - Entry: `startSelection(mode:completion:)` method
  - **No persistence** - selection rect is ephemeral, only passed via callback

**Key Code Sections:**
```swift
// Line 169-202: Start selection with mode
func startSelection(mode: SelectionMode, completion: @escaping AreaSelectionCompletionWithMode)

// Line 73-87: Window pool preparation
func prepareWindowPool()

// Line 129-148: Activation (instant show from pool)
private func activatePooledWindows()
```

### Recording Region Management

**Recording Overlay:**
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Recording/RecordingRegionOverlayWindow.swift`
  - Persistent overlay showing recording area highlight
  - Supports drag/move and resize via 8 handles (edges + corners)
  - Border hidden during actual recording (line 75-78)
  - **Interactive reselection** - click outside rect starts new selection (line 312-317)
  - Delegate pattern for rect updates: `RecordingRegionOverlayDelegate`

**Key Interaction Methods:**
```swift
// Line 69-72: Update highlight rect
func updateHighlightRect(_ rect: CGRect)

// Line 509-533: Delegate callbacks
overlay(didMoveRegionTo:) 
overlay(didResizeRegionTo:)
overlay(didReselectWithRect:)
```

### Recording Coordinator Flow

**RecordingCoordinator.swift** (line 32-69):
1. Receives selected rect from area selection
2. Creates toolbar window anchored to rect (line 37)
3. Shows region overlay across all screens (line 65)
4. Stores rect in `selectedRect` property (line 35)
5. Sets up escape key monitoring (line 68)

**Rect Updates** (line 459-466):
```swift
private func updateSelectedRect(_ rect: CGRect) {
    selectedRect = rect
    for overlay in regionOverlayWindows {
        overlay.updateHighlightRect(rect)
    }
    toolbarWindow?.updateAnchorRect(rect)
}
```

**Capture Mode Toggle** (line 173-186):
- Toolbar button switches between area/fullscreen
- Fullscreen: uses `NSScreen.main.frame` (line 180)
- Area: restarts selection flow (line 184)

### Screen Recording Manager

**Configuration Storage** (line 132-138):
```swift
private var recordingRect: CGRect = .zero
private var videoFormat: VideoFormat = .mov
private var videoQuality: VideoQuality = .high
private var fps: Int = 30
private var captureSystemAudio: Bool = true
private var captureMicrophone: Bool = false
```

**Prepare Recording** (line 149-243):
- Accepts rect parameter
- Stores rect temporarily for recording session
- No persistence to disk - rect discarded after recording

## Settings Storage System

### UserDefaults Keys

**PreferencesKeys.swift** - centralized key definitions:
```swift
// Recording settings (lines 37-43)
static let recordingFormat = "recording.format"
static let recordingFPS = "recording.fps"
static let recordingQuality = "recording.quality"
static let recordingCaptureAudio = "recording.captureAudio"
static let recordingCaptureMicrophone = "recording.captureMicrophone"
static let recordingShortcut = "recordingShortcut"

// General settings (lines 15-18)
static let exportLocation = "exportLocation"
static let playSounds = "playSounds"
static let showMenuBarIcon = "showMenuBarIcon"

// Shortcuts (lines 23-26)
static let shortcutsEnabled = "shortcutsEnabled"
static let fullscreenShortcut = "fullscreenShortcut"
static let areaShortcut = "areaShortcut"
```

### Preferences Manager

**PreferencesManager.swift**:
- Manages complex preferences via JSON encoding
- `afterCaptureActions` - matrix of actions × capture types (line 40)
- Persistence via `UserDefaults.standard` (line 89)
- Singleton: `PreferencesManager.shared`

### Current Persistence Pattern

**Recording settings read from UserDefaults** (RecordingCoordinator.swift lines 57-62, 271-303):
```swift
// Load format preference
if let formatString = UserDefaults.standard.string(forKey: PreferencesKeys.recordingFormat),
   let format = VideoFormat(rawValue: formatString) {
    toolbarWindow?.selectedFormat = format
}

// FPS (default 30)
var fps = UserDefaults.standard.integer(forKey: PreferencesKeys.recordingFPS)
if fps == 0 { fps = 30 }

// Quality (default high)
let qualityString = UserDefaults.standard.string(forKey: PreferencesKeys.recordingQuality) ?? "high"

// Save format on recording start (line 303)
UserDefaults.standard.set(format.rawValue, forKey: PreferencesKeys.recordingFormat)
```

## Recording Area Persistence

**Current State:** NO PERSISTENCE EXISTS

**Observations:**
- Area selection rect only exists during active selection
- Rect stored temporarily in `RecordingCoordinator.selectedRect` (line 21)
- Rect discarded on cleanup (line 455)
- No UserDefaults key for recording area
- No save/restore mechanism for previous recording rect

**Implementation Needed:**
- Add `PreferencesKeys.lastRecordingRect` key
- Encode CGRect to Data (NSCoder/JSON)
- Save on recording completion
- Restore on recording mode activation (optional pre-fill)

## Related UI Components

**Toolbar:**
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Recording/RecordingToolbarWindow.swift`
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Recording/RecordingToolbarView.swift`
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Recording/Components/ToolbarCaptureAreaToggle.swift` - area/fullscreen toggle

**Settings Views:**
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Preferences/Tabs/RecordingSettingsView.swift`
- `/Users/duongductrong/Developer/ZapShot/Snapzy/Features/Preferences/Tabs/ShortcutsSettingsView.swift`

## Key Findings Summary

1. **No rect persistence** - recording area not saved between sessions
2. **Window pooling optimization** - area selection uses pre-allocated windows for speed
3. **Interactive region editing** - drag, resize, reselect supported during pre-record phase
4. **Settings via UserDefaults** - format, FPS, quality, audio persisted
5. **Delegate pattern** - overlay communicates rect changes to coordinator
6. **Mode toggle** - toolbar switches between area/fullscreen dynamically

## Unresolved Questions

None - all recording/area selection systems identified and analyzed.
