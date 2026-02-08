# Widget Behavior in ScreenCaptureKit Investigation

**Date:** 2026-02-09
**Investigator:** Debug Agent
**Task:** Investigate widget appearance in ScreenCaptureKit on macOS 14+

## Executive Summary

Current implementation uses `SCContentFilter(display:excludingApplications:exceptingWindows:)` which creates filter from scratch for entire display. Default behavior of `SCShareableContent.current` uses `excludingDesktopWindows: true` implicitly. Widget handling requires explicit configuration.

**Critical Finding:** `SCContentFilter(display:excludingApplications:exceptingWindows:)` does NOT automatically exclude desktop widgets. It only excludes specified applications and windows. Default `SCShareableContent.current` hides desktop windows but NOT via the filter creation method.

## Current Implementation Analysis

### 1. ScreenCaptureManager.swift Usage

**Lines 71, 83, 129, 175, 190, 361, 377:**
```swift
let content = try await SCShareableContent.current
```

Uses default behavior which implicitly sets `excludingDesktopWindows: true`. This means desktop widgets are excluded from the shareable content list by default.

**Lines 459-471 (buildFilter method):**
```swift
private func buildFilter(
  display: SCDisplay,
  content: SCShareableContent,
  excludeDesktopIcons: Bool
) -> SCContentFilter {
  if excludeDesktopIcons {
    let iconManager = DesktopIconManager.shared
    let finderApps = iconManager.getFinderApps(from: content)
    let visibleFinderWindows = iconManager.getVisibleFinderWindows(from: content)
    return SCContentFilter(display: display, excludingApplications: finderApps, exceptingWindows: visibleFinderWindows)
  }
  return SCContentFilter(display: display, excludingWindows: [])
}
```

Current implementation only handles Finder (desktop icons). Does NOT handle widgets.

### 2. ScreenRecordingManager.swift Usage

**Line 175:**
```swift
content = try await SCShareableContent.current
```

Same default behavior - excludes desktop widgets from shareable content list.

**Lines 440-443 (setupStream method):**
```swift
let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: exceptedWindows)
```

Excludes own app + optionally Finder. Does NOT explicitly handle widgets.

## Key Technical Findings

### Default Behavior Discrepancy

**`SCShareableContent.current`:**
- Implicitly uses `excludingDesktopWindows: true`
- Desktop widgets NOT included in returned window list
- Wallpaper NOT considered desktop window (rendered by Dock/WallpaperAgent)

**`SCContentFilter(display:excludingApplications:exceptingWindows:)`:**
- Creates filter from scratch for entire display
- Does NOT inherit `excludingDesktopWindows` behavior
- Captures EVERYTHING on display except explicitly excluded apps/windows
- **INCLUDES widgets by default** unless widget processes explicitly excluded

### Alternative API Method

**`SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)`:**
- Explicitly controls desktop window inclusion
- Setting `false` includes desktop widgets in shareable content list
- Allows identifying widget windows programmatically
- **Recommended approach** for widget detection and filtering

## Widget Process Identifiers Research

### Known Widget-Related Processes (macOS 14+)

Based on macOS architecture and WidgetKit framework:

**Likely candidates:**
1. `com.apple.widgetkit.simulator` - WidgetKit simulator process
2. `com.apple.notificationcenterui` - Notification Center widgets (legacy)
3. `com.apple.widgetkitextensionhost` - Widget extension host process
4. `com.apple.chronod` - Widget background updates daemon
5. `WidgetKit` - Generic process name pattern

**Uncertain identifiers requiring runtime verification:**
- Widget bundle IDs vary by app (e.g., `com.example.app.widget`)
- Desktop widgets may run in consolidated host process
- iPhone widgets via Continuity may use different identifier

### Limitations

Web search did not provide definitive runtime process identifiers. **Runtime inspection required** using:

```swift
let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
// Inspect content.windows and content.applications to identify widget processes
for window in content.windows {
  print("Window: \(window.title ?? "nil"), App: \(window.owningApplication?.bundleIdentifier ?? "nil")")
}
```

## Recommendations

### Immediate Actions

1. **Add runtime widget detection:**
   - Use `SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)`
   - Log all window owning application bundle identifiers
   - Identify widget processes on macOS 14+ systems

2. **Update DesktopIconManager:**
   - Add method `getWidgetApps(from: SCShareableContent) -> [SCRunningApplication]`
   - Add method `getWidgetWindows(from: SCShareableContent) -> [SCWindow]`
   - Filter based on discovered bundle identifiers

3. **Extend buildFilter method:**
   ```swift
   if excludeDesktopIcons {
     let iconManager = DesktopIconManager.shared
     let finderApps = iconManager.getFinderApps(from: content)
     let widgetApps = iconManager.getWidgetApps(from: content) // NEW
     let excludedApps = finderApps + widgetApps
     let visibleFinderWindows = iconManager.getVisibleFinderWindows(from: content)
     return SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: visibleFinderWindows)
   }
   ```

### Testing Protocol

1. Create macOS 14+ test environment
2. Add desktop widgets (Weather, Clock, Calendar, etc.)
3. Run detection script to log all processes
4. Capture screenshots with/without widget exclusion
5. Verify widgets properly filtered

### Risk Assessment

**Low Risk:**
- Widget exclusion isolated to preference-controlled code path
- Existing Finder exclusion proven working
- Similar implementation pattern

**Potential Issues:**
- Widget bundle IDs may vary by macOS version
- Consolidated widget host process may require different approach
- iPhone widgets via Continuity unknown behavior

## Unresolved Questions

1. **What are definitive widget process bundle identifiers on macOS 14/15?**
   - Requires runtime inspection on actual system
   - May vary between macOS versions

2. **Do iPhone widgets via Continuity use different processes?**
   - Testing on system with iPhone Continuity required
   - May need separate identification logic

3. **Are widgets in SCWindow list individual or consolidated?**
   - May be single host process with multiple windows
   - Or individual processes per widget
   - Affects filtering strategy

4. **Does widget visibility state matter?**
   - Widgets can be hidden in "Desktop & Stage Manager" settings
   - Hidden widgets may not appear in SCShareableContent
   - Needs verification

## Next Steps

1. Run widget detection script on macOS 14+ system
2. Document discovered bundle identifiers
3. Implement widget filtering in DesktopIconManager
4. Update both capture and recording flows
5. Test with multiple widget types
6. Update user preferences to clarify "desktop icons" includes widgets

---

**Sources:**
- [Apple Developer - ScreenCaptureKit](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZB5X1YKQzL6QEVy40DBdYXMT2RjwCtUi004ebbbXEa51DibhIXxUbGTLWgqB6_lDuNXAYUEZVmxHx3eEUbeL4iT91EPRCbrFf39PAUkMSpU-71DvvfuLK6UlgdiFqeQwvLS1SPQhYCIt9E9KpnT18hWR2ixLUAxTVOjS3Kqn01xu17G0N7dPlKzSgPKtXCOJWCK8St7dq)
- [Chromium Bug - Desktop Capture](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFQmV3XFo1Ri-Ohlk6caAVsIlp90MT15VYeN8F4lx6hC1_brfNG9JYVHErmCp3gywl-Y63NIODFVSeP_S1w-l7Sph1xKygLskuYFSw0bSGZHPhb-xfvG-UzV4R16oDBgw==)
- [Engadget - macOS Sonoma Widgets](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFRbdWId_ovR5br_G-D9HhAWUM7MZAlVOPyvxucmP_iko_JN5_YSpNFJWiWSl90ooSoZpQLihF6SFZAZUUpcTNv5HhY-T_pL5T4pW57K5igc6EL1EDPbmBqy2Vnx_MRO8LTr09x_QXMjfnpdHxPU_ko2nfH016FxEAEEUtjVJcgdVALGb8KA_HeF9gQ3KY=)
- [Apple Support - macOS Sonoma Widgets](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHnr4WW4zNxNKRL8J0sMI6wd33TPFltD2KMlzNgDw_K3Qaz_ek4gWWn8P2brE94jLRmUVeQmocV-Xp446IzSyQZrTFMnR2V8Uu0SvSH8yBxhRoPXUhejews0Km65JLgTHJTMnFlDjeIJVU=)
- [StackOverflow - WidgetKit Configuration](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHsqAmzGwcx6KpQCGxix9uChvgKZRnyn22SNhBN8WklMyLzXCnKR0Q0F4GvUSBBHGiwYMw6DObLhGcIopYO8p8vxhSmo6NPBKnb9pK5Fymr2Fv7JhmRBATaNJ0aSron1M2B9FeWC7LJ0aHzMRcuV3I9uRVcN3WoxKLGdeg92a_vxpkT6LGQbQxJNdmmKpPn)
