# Phase 02: UI Integration & Components

## Context

- **Parent Plan**: [plan.md](plan.md)
- **Dependencies**: [phase-01-wallpaper-manager.md](phase-01-wallpaper-manager.md)

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-27 |
| Description | Integrate system wallpapers into sidebar UI |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

## Requirements

1. New "System Wallpapers" section in sidebar
2. Async thumbnail loading with placeholder
3. Grid layout matching existing wallpaper section
4. Selection applies wallpaper to canvas background

## Related Code Files

| File | Action |
|------|--------|
| `AnnotateSidebarSections.swift` | Add `SidebarSystemWallpaperSection` |
| `AnnotateSidebarComponents.swift` | Add `SystemWallpaperButton` |
| `AnnotateSidebarView.swift` | Include new section |

## Implementation Steps

### Step 1: Add SystemWallpaperButton component

```swift
// In AnnotateSidebarComponents.swift

struct SystemWallpaperButton: View {
    let item: SystemWallpaperManager.WallpaperItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AsyncImage(url: item.thumbnailURL ?? item.fullImageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.opacity(0.3)
                case .empty:
                    ProgressView().scaleEffect(0.5)
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
            .sidebarItemStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}
```

### Step 2: Add SidebarSystemWallpaperSection

```swift
// In AnnotateSidebarSections.swift

struct SidebarSystemWallpaperSection: View {
    @ObservedObject var state: AnnotateState
    @StateObject private var manager = SystemWallpaperManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SidebarSectionHeader(title: "System Wallpapers")

            if manager.isLoading {
                HStack { ProgressView().scaleEffect(0.7); Spacer() }
            } else if manager.systemWallpapers.isEmpty {
                Text("No wallpapers found")
                    .font(Typography.labelSmall)
                    .foregroundColor(SidebarColors.labelSecondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: GridConfig.gap), count: GridConfig.backgroundColumns), spacing: GridConfig.gap) {
                    ForEach(manager.systemWallpapers) { item in
                        SystemWallpaperButton(
                            item: item,
                            isSelected: isSelected(item)
                        ) {
                            selectWallpaper(item)
                        }
                    }
                }
            }
        }
        .task { await manager.loadSystemWallpapers() }
    }

    private func isSelected(_ item: SystemWallpaperManager.WallpaperItem) -> Bool {
        if case .wallpaper(let url) = state.backgroundStyle {
            return url == item.fullImageURL
        }
        return false
    }

    private func selectWallpaper(_ item: SystemWallpaperManager.WallpaperItem) {
        if state.padding <= 0 { state.padding = 24 }
        state.backgroundStyle = .wallpaper(item.fullImageURL)
    }
}
```

### Step 3: Update AnnotateSidebarView

Add section after existing wallpaper section:
```swift
SidebarSystemWallpaperSection(state: state)
```

## Todo List

- [ ] Add `SystemWallpaperButton` to AnnotateSidebarComponents.swift
- [ ] Add `SidebarSystemWallpaperSection` to AnnotateSidebarSections.swift
- [ ] Include new section in AnnotateSidebarView.swift
- [ ] Test thumbnail loading and selection

## Success Criteria

- [ ] System wallpapers display in grid
- [ ] Thumbnails load without blocking UI
- [ ] Selection updates canvas background
- [ ] Loading state shown during enumeration
