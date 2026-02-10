# Phase 2: Create Capture Tab

**Status:** Pending | **Depends on:** Phase 1 (SettingRow extraction) | **Blocks:** Phase 3, Phase 6

## Context

- [Scout report](./scout/scout-01-preferences-files.md) -- current file inventory and section mapping
- [UX research](./research/researcher-01-macos-preferences-ux.md) -- task-oriented grouping rationale
- Current "Capture" section lives in `GeneralSettingsView.swift` (lines 58-68)
- Current "Post-Capture Actions" section lives in `GeneralSettingsView.swift` (lines 70-72)
- All recording settings live in `RecordingSettingsView.swift` (entire file, 188 lines)

## Overview

Create a new `CaptureSettingsView.swift` that consolidates all capture-related settings into one tab: screenshot behavior (from General), recording config (from Recording), and after-capture actions (from General). This eliminates the "See General tab" cross-reference anti-pattern in the current Recording tab.

## Requirements

- Combine screenshot behavior settings (hide desktop icons, hide desktop widgets) from GeneralSettingsView
- Move all recording settings (format, FPS, quality, behavior, audio) from RecordingSettingsView
- Move after-capture action matrix from GeneralSettingsView
- Remove the "Save Location" section from Recording (it pointed to General; storage stays in General tab)
- Use shared `SettingRow` from Phase 1 -- no private `settingRow` copy
- All `@AppStorage` keys remain identical (same `PreferencesKeys.*` constants)
- Microphone permission handling logic moves intact from RecordingSettingsView

## Related Files

| File | Action |
|------|--------|
| `Tabs/CaptureSettingsView.swift` | CREATE -- new combined capture tab |
| `Tabs/GeneralSettingsView.swift` | Source -- "Capture" section (lines 58-68), "Post-Capture Actions" section (lines 70-72) |
| `Tabs/RecordingSettingsView.swift` | Source -- entire file contents (will be deleted in Phase 6) |
| `Components/AfterCaptureMatrixView.swift` | Referenced -- used as-is, no changes |
| `Components/SettingRow.swift` | Referenced -- use shared component from Phase 1 |
| `PreferencesKeys.swift` | Referenced -- NO changes, same keys |

## Implementation Steps

### Step 1: Create `Tabs/CaptureSettingsView.swift`

Create new file at `Snapzy/Features/Preferences/Tabs/CaptureSettingsView.swift`.

Structure with 3 sections:

```swift
//
//  CaptureSettingsView.swift
//  Snapzy
//
//  Capture preferences tab combining screenshot behavior, recording settings,
//  and post-capture actions
//

import AVFoundation
import SwiftUI

struct CaptureSettingsView: View {
  // Screenshot behavior (from GeneralSettingsView)
  @AppStorage(PreferencesKeys.hideDesktopIcons) private var hideDesktopIcons = false
  @AppStorage(PreferencesKeys.hideDesktopWidgets) private var hideDesktopWidgets = false

  // Recording settings (from RecordingSettingsView)
  @AppStorage(PreferencesKeys.recordingFormat) private var format = "mov"
  @AppStorage(PreferencesKeys.recordingFPS) private var fps = 30
  @AppStorage(PreferencesKeys.recordingQuality) private var quality = "high"
  @AppStorage(PreferencesKeys.recordingCaptureAudio) private var captureAudio = true
  @AppStorage(PreferencesKeys.recordingCaptureMicrophone) private var captureMicrophone = false
  @AppStorage(PreferencesKeys.recordingRememberLastArea) private var rememberLastArea = true

  @State private var showPermissionDeniedAlert = false

  private var isMicAvailable: Bool {
    if #available(macOS 15.0, *) { return true }
    return false
  }

  var body: some View {
    Form {
      screenshotBehaviorSection
      recordingSection
      afterCaptureSection
    }
    .formStyle(.grouped)
    .alert("Microphone Access Required", isPresented: $showPermissionDeniedAlert) {
      Button("Open System Settings") { openMicrophoneSettings() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Snapzy needs microphone permission. Please enable it in System Settings > Privacy & Security > Microphone.")
    }
  }

  // MARK: - Screenshot Behavior Section
  // Moved from GeneralSettingsView "Capture" section

  private var screenshotBehaviorSection: some View {
    Section("Screenshot Behavior") {
      SettingRow(icon: "eye.slash", title: "Hide desktop icons", description: "Temporarily hide icons during capture") {
        Toggle("", isOn: $hideDesktopIcons)
          .labelsHidden()
      }
      SettingRow(icon: "widget.small", title: "Hide desktop widgets", description: "Temporarily hide widgets during capture") {
        Toggle("", isOn: $hideDesktopWidgets)
          .labelsHidden()
      }
    }
  }

  // MARK: - Recording Section
  // Moved from RecordingSettingsView (Format, Quality, Behavior, Audio sections combined)

  private var recordingSection: some View {
    Group {
      Section("Recording") {
        SettingRow(icon: "film", title: "Video Format", description: "MOV offers better quality. MP4 provides wider compatibility.") {
          Picker("", selection: $format) {
            Text("MOV").tag("mov")
            Text("MP4").tag("mp4")
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .frame(width: 120)
        }

        SettingRow(icon: "gauge.with.dots.needle.33percent", title: "Frame Rate", description: "Higher FPS for smoother motion") {
          Picker("", selection: $fps) {
            Text("30 FPS").tag(30)
            Text("60 FPS").tag(60)
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .frame(width: 140)
        }

        SettingRow(icon: "sparkles", title: "Quality", description: "Higher quality = larger file size") {
          Picker("", selection: $quality) {
            Text("High").tag("high")
            Text("Medium").tag("medium")
            Text("Low").tag("low")
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .frame(width: 180)
        }

        SettingRow(icon: "rectangle.dashed", title: "Remember Last Area", description: "Restore previous recording area on next capture") {
          Toggle("", isOn: $rememberLastArea)
            .labelsHidden()
        }
      }

      Section("Audio") {
        SettingRow(icon: "speaker.wave.3.fill", title: "System Audio", description: "Capture sounds from apps") {
          Toggle("", isOn: $captureAudio)
            .labelsHidden()
        }

        SettingRow(icon: "mic.fill", title: "Microphone", description: microphoneDescription) {
          Toggle("", isOn: Binding(
            get: { captureMicrophone },
            set: { newValue in
              if newValue { handleMicrophoneEnable() }
              else { captureMicrophone = false }
            }
          ))
          .labelsHidden()
          .disabled(!captureAudio || !isMicAvailable)
        }
      }
    }
  }

  // MARK: - After Capture Section
  // Moved from GeneralSettingsView "Post-Capture Actions" section

  private var afterCaptureSection: some View {
    Section("After Capture") {
      AfterCaptureMatrixView()
    }
  }

  // MARK: - Helpers (moved from RecordingSettingsView)

  private var microphoneDescription: String {
    if !isMicAvailable { return "Requires macOS 15.0+" }
    return "Capture your voice"
  }

  private func handleMicrophoneEnable() {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    switch status {
    case .notDetermined:
      Task {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
          if granted { captureMicrophone = true }
          else { showPermissionDeniedAlert = true }
        }
      }
    case .authorized:
      captureMicrophone = true
    case .denied, .restricted:
      showPermissionDeniedAlert = true
    @unknown default:
      captureMicrophone = true
    }
  }

  private func openMicrophoneSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
      NSWorkspace.shared.open(url)
    }
  }
}

#Preview {
  CaptureSettingsView()
    .frame(width: 600, height: 500)
}
```

### Step 2: Verify no key changes

Cross-check all `@AppStorage` keys used in the new file against `PreferencesKeys.swift`:
- `hideDesktopIcons` -- same
- `hideDesktopWidgets` -- same
- `recordingFormat` -- same
- `recordingFPS` -- same
- `recordingQuality` -- same
- `recordingCaptureAudio` -- same
- `recordingCaptureMicrophone` -- same
- `recordingRememberLastArea` -- same

### Step 3: Build and verify

Run the app, navigate to the new Capture tab (will be wired in Phase 6), confirm all controls render and bind correctly.

## Todo List

- [ ] Create `Tabs/CaptureSettingsView.swift` with all 3 sections
- [ ] Verify all `@AppStorage` keys match `PreferencesKeys.swift` exactly
- [ ] Confirm `AfterCaptureMatrixView` renders correctly in new location
- [ ] Confirm microphone permission flow works (enable/deny/restricted)
- [ ] Build succeeds with no warnings

## Success Criteria

- New `CaptureSettingsView.swift` exists with 3 sections: Screenshot Behavior, Recording, After Capture
- File uses shared `SettingRow` component (no private copy)
- All `@AppStorage` keys are identical to originals
- Microphone permission alert and System Settings link work
- File stays under 200 lines per development rules
