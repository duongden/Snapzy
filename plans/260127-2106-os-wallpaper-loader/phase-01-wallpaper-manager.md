# Phase 01: SystemWallpaperManager Service

## Context

- **Parent Plan**: [plan.md](plan.md)
- **Dependencies**: None
- **Docs**: [01-codebase-analysis.md](reports/01-codebase-analysis.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-27 |
| Description | Create service to enumerate and manage macOS system wallpapers |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

## Key Insights

- System wallpapers at `/System/Library/Desktop Pictures/`
- Thumbnails available at `.thumbnails/` subfolder (pre-generated HEIC)
- App not sandboxed - full filesystem access
- ~70+ wallpapers in system folder - async loading required

## Requirements

1. Enumerate wallpapers from system directories
2. Provide thumbnail URLs for grid display
3. Cache discovered wallpaper list
4. Filter valid image types (.heic, .jpg, .png)
5. Exclude .madesktop dynamic desktop bundles

## Architecture

```swift
class SystemWallpaperManager: ObservableObject {
    static let shared = SystemWallpaperManager()

    @Published var systemWallpapers: [WallpaperItem] = []
    @Published var isLoading = false

    struct WallpaperItem: Identifiable {
        let id = UUID()
        let fullImageURL: URL
        let thumbnailURL: URL?
        let name: String
    }

    func loadSystemWallpapers() async
    private func enumerateDirectory(_ path: String) -> [URL]
    private func thumbnailURL(for wallpaper: URL) -> URL?
}
```

## Related Code Files

| File | Purpose |
|------|---------|
| `ClaudeShot/Core/Services/SystemWallpaperManager.swift` | New file |
| `ClaudeShot/Features/Annotate/Background/BackgroundStyle.swift` | Reference |

## Implementation Steps

### Step 1: Create SystemWallpaperManager.swift

```swift
// Location: ClaudeShot/Core/Services/SystemWallpaperManager.swift

import Foundation
import Combine

class SystemWallpaperManager: ObservableObject {
    static let shared = SystemWallpaperManager()

    @Published var systemWallpapers: [WallpaperItem] = []
    @Published var isLoading = false

    private let systemWallpaperPaths = [
        "/System/Library/Desktop Pictures",
        "/Library/Desktop Pictures"
    ]

    private let supportedExtensions = ["heic", "jpg", "jpeg", "png"]

    struct WallpaperItem: Identifiable, Hashable {
        let id = UUID()
        let fullImageURL: URL
        let thumbnailURL: URL?
        let name: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(fullImageURL)
        }

        static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
            lhs.fullImageURL == rhs.fullImageURL
        }
    }

    private init() {}

    @MainActor
    func loadSystemWallpapers() async {
        guard !isLoading else { return }
        isLoading = true

        let wallpapers = await Task.detached(priority: .userInitiated) {
            self.enumerateAllDirectories()
        }.value

        systemWallpapers = wallpapers
        isLoading = false
    }

    private func enumerateAllDirectories() -> [WallpaperItem] {
        var items: [WallpaperItem] = []
        let fm = FileManager.default

        for basePath in systemWallpaperPaths {
            guard fm.fileExists(atPath: basePath) else { continue }

            let baseURL = URL(fileURLWithPath: basePath)
            guard let contents = try? fm.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents {
                let ext = url.pathExtension.lowercased()
                guard supportedExtensions.contains(ext) else { continue }

                let name = url.deletingPathExtension().lastPathComponent
                let thumbnail = thumbnailURL(for: url, basePath: basePath)

                items.append(WallpaperItem(
                    fullImageURL: url,
                    thumbnailURL: thumbnail,
                    name: name
                ))
            }
        }

        return items.sorted { $0.name < $1.name }
    }

    private func thumbnailURL(for wallpaper: URL, basePath: String) -> URL? {
        let thumbnailDir = URL(fileURLWithPath: basePath)
            .appendingPathComponent(".thumbnails")
        let thumbnailFile = thumbnailDir
            .appendingPathComponent(wallpaper.deletingPathExtension().lastPathComponent)
            .appendingPathExtension("heic")

        return FileManager.default.fileExists(atPath: thumbnailFile.path)
            ? thumbnailFile
            : nil
    }
}
```

### Step 2: Create Services directory if needed

```bash
mkdir -p ClaudeShot/Core/Services
```

## Todo List

- [ ] Create `ClaudeShot/Core/Services/` directory
- [ ] Create `SystemWallpaperManager.swift`
- [ ] Implement `loadSystemWallpapers()` async method
- [ ] Implement directory enumeration with filtering
- [ ] Implement thumbnail URL resolution
- [ ] Test with actual system wallpaper directory

## Success Criteria

- [ ] Manager discovers wallpapers from system directories
- [ ] Thumbnails resolved when available
- [ ] Loading is async and non-blocking
- [ ] Empty/missing directories handled gracefully

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Large file count | Low | Async loading, pagination if needed |
| Missing thumbnails | Low | Fall back to full image |
| Directory permissions | Low | App not sandboxed |

## Security Considerations

- Read-only access to system directories
- No user data modification
- No network requests

## Next Steps

Proceed to [phase-02-ui-integration.md](phase-02-ui-integration.md) for UI components.
