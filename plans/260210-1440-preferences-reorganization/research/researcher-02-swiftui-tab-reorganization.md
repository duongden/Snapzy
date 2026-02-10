# SwiftUI Tab Reorganization Research

**Research Focus**: Best practices for reorganizing settings/preferences in SwiftUI macOS app
**Date**: 2026-02-10
**Project**: Snapzy Preferences Restructure (6 tabs → new structure)

---

## 1. SwiftUI TabView Patterns for macOS Preferences

### Standard Implementation
```swift
TabView {
    GeneralView()
        .tabItem { Label("General", systemImage: "gear") }
        .tag(PreferenceTab.general)

    CaptureView()
        .tabItem { Label("Capture", systemImage: "camera") }
        .tag(PreferenceTab.capture)
}
.frame(width: 500, height: 400)
```

### Key Patterns
- **Fixed frame sizing**: macOS preferences need explicit `.frame()` - typically 500-600px width, 400-500px height
- **Tag-based navigation**: Use enum tags for programmatic tab selection
- **Label with SF Symbols**: Standard macOS HIG - text + icon in tabItem
- **Settings Scene (macOS 13+)**: Use `Settings` scene instead of manual window management
  ```swift
  @main
  struct MyApp: App {
      var body: some Scene {
          Settings {
              PreferencesView()
          }
      }
  }
  ```

### Tab Organization Best Practices
- **Max 6-8 tabs**: Beyond this, consider nested navigation or search
- **Logical grouping**: Related settings together (capture settings + post-capture actions)
- **Consistent naming**: General → Specific (General, Capture, Quick Access, Shortcuts, Permissions, About)
- **Icon consistency**: Use SF Symbols throughout, avoid mixing styles

---

## 2. Moving Settings Between Tabs (UserDefaults Safety)

### Critical Rule: NEVER Change UserDefaults Keys
When reorganizing tabs, settings can move between views but **keys must remain unchanged**.

```swift
// WRONG - changing key breaks existing user data
// Old: @AppStorage("showMenuBarIcon") var showIcon: Bool
@AppStorage("generalShowMenuBarIcon") var showIcon: Bool

// CORRECT - same key, different location in UI
@AppStorage("showMenuBarIcon") var showIcon: Bool
```

### Safe Refactoring Strategy
1. **Move, don't rename**: UI location changes, keys stay identical
2. **Centralized key definitions**: Use constants/enum for keys
   ```swift
   enum PreferencesKeys {
       static let showMenuBarIcon = "showMenuBarIcon"
       static let captureFormat = "captureFormat"
   }
   ```
3. **No migration needed**: If keys unchanged, existing values preserved automatically

### When Key Changes ARE Needed
If consolidating duplicate settings or renaming for clarity:
```swift
// Migration on first launch
func migratePreferencesIfNeeded() {
    if UserDefaults.standard.object(forKey: "hasMigratedV2") == nil {
        // Migrate old keys to new keys
        if let oldValue = UserDefaults.standard.value(forKey: "oldKey") {
            UserDefaults.standard.set(oldValue, forKey: "newKey")
        }
        UserDefaults.standard.set(true, forKey: "hasMigratedV2")
    }
}
```

---

## 3. Migration Strategies for Tab Reorganization

### Scenario A: Pure Reorganization (No Key Changes)
**No migration needed** - just move UI components between files.

### Scenario B: Combining Duplicate Settings
Example: Merging "Recording" tab into "Capture" tab
```swift
// Before: separate keys
// Recording tab: "recordingQuality"
// Capture tab: "screenshotQuality"

// After: unified approach
// Keep BOTH keys, don't consolidate (backward compat)
@AppStorage("recordingQuality") var recordingQuality: String
@AppStorage("screenshotQuality") var screenshotQuality: String
```

### Scenario C: Deprecated Settings Removal
```swift
// Mark deprecated, remove in future version
extension UserDefaults {
    @available(*, deprecated, message: "Use newSettingKey")
    var oldSetting: Bool {
        get { bool(forKey: "oldSettingKey") }
        set { set(newValue, forKey: "oldSettingKey") }
    }
}
```

### Version-Based Migration Pattern
```swift
enum PreferencesVersion: Int {
    case v1 = 1  // Original 6 tabs
    case v2 = 2  // Reorganized structure

    static var current: PreferencesVersion { .v2 }
}

func runMigrations() {
    let savedVersion = UserDefaults.standard.integer(forKey: "preferencesVersion")

    if savedVersion < PreferencesVersion.v2.rawValue {
        // Run v2 migrations
        migrateToV2()
        UserDefaults.standard.set(PreferencesVersion.v2.rawValue, forKey: "preferencesVersion")
    }
}
```

---

## 4. SwiftUI Form & .formStyle(.grouped) Best Practices

### macOS-Specific Form Styling
```swift
Form {
    Section {
        Toggle("Launch at login", isOn: $launchAtLogin)
        Picker("Appearance", selection: $appearance) {
            Text("Light").tag(Appearance.light)
            Text("Dark").tag(Appearance.dark)
        }
    } header: {
        Text("General")
    }
}
.formStyle(.grouped)  // macOS native grouped style
.padding()
```

### Key Patterns
- **`.formStyle(.grouped)`**: Native macOS look, sections with rounded backgrounds
- **Explicit padding**: Add `.padding()` to Form for proper margins
- **Section headers**: Use `header:` for grouping, not separate Text views
- **Control alignment**: Forms auto-align labels and controls
- **Picker style**: Use `.pickerStyle(.menu)` for compact dropdowns

### Layout Best Practices
```swift
Section {
    LabeledContent("Save to") {
        HStack {
            Text(savePath).lineLimit(1)
            Button("Choose...") { selectFolder() }
        }
    }

    Toggle("Include timestamp", isOn: $includeTimestamp)
}
```

- **LabeledContent**: For custom control layouts (vs Toggle/Picker)
- **Consistent spacing**: Let Form handle, avoid manual VStack spacing
- **Help text**: Use `.help()` modifier for tooltips

---

## 5. Shared Component Extraction Patterns

### Reusable Settings Row
```swift
struct SettingsRow<Content: View>: View {
    let label: String
    let icon: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        LabeledContent {
            content()
        } label: {
            if let icon {
                Label(label, systemImage: icon)
            } else {
                Text(label)
            }
        }
    }
}

// Usage
SettingsRow(label: "Format", icon: "photo") {
    Picker("", selection: $format) {
        Text("PNG").tag("png")
        Text("JPEG").tag("jpeg")
    }
    .labelsHidden()
}
```

### Extraction Strategies

#### 1. View Modifiers for Consistent Styling
```swift
extension View {
    func settingsSection() -> some View {
        self.padding(.vertical, 8)
    }

    func settingsPicker() -> some View {
        self.pickerStyle(.menu)
            .frame(maxWidth: 200)
    }
}
```

#### 2. Preference Sections as Separate Views
```swift
struct GeneralAppearanceSection: View {
    @AppStorage("appearance") var appearance = "auto"

    var body: some View {
        Section("Appearance") {
            // Controls here
        }
    }
}

// Compose in main view
struct GeneralView: View {
    var body: some View {
        Form {
            GeneralAppearanceSection()
            GeneralStartupSection()
            GeneralStorageSection()
        }
        .formStyle(.grouped)
    }
}
```

#### 3. Shared Control Groups
```swift
struct ShortcutRecorder: View {
    @Binding var shortcut: String
    let label: String

    var body: some View {
        LabeledContent(label) {
            // Shortcut recording UI
        }
    }
}
```

---

## Implementation Recommendations for Snapzy

### Tab Structure
```
1. General (gear)
   - Startup: launch at login, show icon
   - Appearance: theme, window behavior
   - Storage: save location, naming
   - Updates: auto-check, beta channel
   - Help: links, resources

2. Capture (camera)
   - Screenshot: format, quality, delay
   - Recording: codec, fps, audio
   - Post-Capture: auto-copy, notifications

3. Quick Access (overlay icon)
   - Unchanged from current

4. Shortcuts (keyboard icon)
   - Unchanged from current

5. Permissions (lock icon)
   - Screen recording status
   - Accessibility status
   - Request buttons

6. About (info circle)
   - Version, build
   - Credits, links
```

### Migration Checklist
- [ ] Audit all `@AppStorage` keys - document current state
- [ ] Move UI components to new tabs - NO key changes
- [ ] Extract common patterns (SettingsRow, section views)
- [ ] Test with existing UserDefaults data
- [ ] Verify no settings lost/reset
- [ ] Update any documentation/help text

### Unresolved Questions
None - pure reorganization requires no migration if keys remain unchanged.
