# Codebase Analysis Report

## Date: 2026-01-27

## Summary

Analysis of current wallpaper implementation and macOS system wallpaper directories for OS wallpaper loading feature.

## Current Implementation

### BackgroundStyle.swift
- Enum `BackgroundStyle` supports `.wallpaper(URL)` case
- `WallpaperPreset` enum: 3 gradient presets (Ocean, Sunset, Forest)
- No file-based wallpaper loading from system

### AnnotateSidebarSections.swift
- `SidebarWallpaperSection`: displays wallpaper options
- `@State private var customWallpapers: [URL]` stores user-added images
- Uses `NSOpenPanel` for manual file selection
- Grid layout via `LazyVGrid` with `GridConfig.backgroundColumns`

### AnnotateSidebarComponents.swift
- `CustomWallpaperButton`: loads image via `NSImage(contentsOf: url)`
- `AddWallpaperButton`: triggers file picker
- All buttons use `.sidebarItemStyle()` modifier

## macOS System Wallpaper Locations

| Path | Description | Access |
|------|-------------|--------|
| `/System/Library/Desktop Pictures/` | System wallpapers | Read-only |
| `/System/Library/Desktop Pictures/.thumbnails/` | Pre-generated thumbnails | Read-only |
| `~/Library/Desktop Pictures/` | User wallpapers | Does not exist by default |
| `/Library/Desktop Pictures/` | Shared wallpapers | May not exist |

### File Formats Found
- `.heic` - Primary format (e.g., `Sonoma.heic`, `iMac Blue.heic`)
- `.madesktop` - Dynamic desktop bundles (skip these)
- Thumbnails available in `.thumbnails/` subfolder

### Sample Files
```
/System/Library/Desktop Pictures/Sonoma.heic
/System/Library/Desktop Pictures/iMac Blue.heic
/System/Library/Desktop Pictures/Radial Sky Blue.heic
```

## Sandbox Status

From `ClaudeShot.entitlements`:
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

**App is NOT sandboxed** - full filesystem access available.

## Technical Considerations

1. **HEIC Support**: NSImage natively supports HEIC on macOS
2. **Thumbnail Strategy**: Use `.thumbnails/` folder for grid display, full image on selection
3. **Async Loading**: Required for smooth UI - system folder has 70+ wallpapers
4. **Memory Management**: Use thumbnail size for grid, lazy load full images
5. **File Filtering**: Include `.heic`, `.jpg`, `.png`; exclude `.madesktop`, hidden files

## Architecture Recommendation

```
┌─────────────────────────────────────────────┐
│         SystemWallpaperManager              │
│  - Singleton service                        │
│  - Async enumeration of system directories  │
│  - Caches discovered wallpaper URLs         │
│  - Provides thumbnails for grid display     │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│      SidebarSystemWallpaperSection          │
│  - New section in sidebar                   │
│  - Uses SystemWallpaperManager              │
│  - LazyVGrid with async image loading       │
│  - Expandable/collapsible for many items    │
└─────────────────────────────────────────────┘
```

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Large number of wallpapers | Medium | Pagination or scroll limit |
| HEIC loading performance | Low | Use thumbnails folder |
| Missing directories | Low | Graceful fallback |
| Permission denied | Low | App not sandboxed |

## Unresolved Questions

1. Should we show ALL system wallpapers or limit to a subset?
2. Should dynamic desktops (`.madesktop`) be supported in the future?
3. Preferred UI: separate section or merged with existing wallpapers?
