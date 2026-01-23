# Fix Video Editor "Replace Original" Saving to Temp File

**Date**: 2026-01-24
**Status**: Ready for Implementation
**Complexity**: Low-Medium

## Problem Summary

When a video is drag-dropped into `VideoEditorEmptyStateView`, the "Replace Original" feature saves to a temp file location instead of the actual original file because:

1. `handleDrop()` uses `loadFileRepresentation` which provides only a temp URL
2. The original file path is never captured from the `NSItemProvider`
3. The `originalURL` in `VideoEditorState` receives the temp copy URL instead of the real source

## Root Cause Analysis

**Current Flow (Broken)**:
```
Drag-drop video -> loadFileRepresentation -> temp URL copied to another temp
-> VideoEditorState(url: tempCopy) -> originalURL = tempCopy (WRONG!)
-> "Replace Original" replaces temp file, not user's actual file
```

**Expected Flow (Fixed)**:
```
Drag-drop video -> extract real URL from NSItemProvider
-> copy to temp for editing -> VideoEditorState(url: tempCopy, originalURL: realPath)
-> "Replace Original" replaces user's actual file (CORRECT!)
```

## Files to Modify

| File | Lines | Changes |
|------|-------|---------|
| `VideoEditorEmptyStateView.swift` | 13, 91-163, 179-194 | Update callback signature, extract original URL |
| `VideoEditorManager.swift` | 97-99, 126-131 | Pass originalURL through callback chain |
| `VideoEditorWindowController.swift` | 21, 35-43, 90-94 | Add originalURL parameter to init and callback |

**No changes needed**: `VideoEditorState.swift` already supports `originalURL` parameter (line 134)

## Implementation Steps

### Step 1: Update VideoEditorEmptyStateView.swift

**1.1 Change callback signature (line 13)**

```swift
// Before
var onVideoDropped: (URL) -> Void

// After
var onVideoDropped: (URL, URL?) -> Void  // (workingURL, originalURL)
```

**1.2 Update handleDrop() to extract original URL (lines 91-163)**

The key insight: `NSItemProvider` from drag-drop contains the original file URL. We can extract it using `loadItem(forTypeIdentifier:options:)` which returns the actual file URL, not a temp copy.

```swift
private func handleDrop(providers: [NSItemProvider]) -> Bool {
  guard let provider = providers.first else {
    print("[VideoEditor Drop] No provider found")
    return false
  }

  print("[VideoEditor Drop] Provider: \(provider)")
  print("[VideoEditor Drop] Registered types: \(provider.registeredTypeIdentifiers)")

  // Find the first video type the provider can load
  guard let videoType = supportedTypes.first(where: {
    provider.hasItemConformingToTypeIdentifier($0.identifier)
  }) else {
    print("[VideoEditor Drop] No supported video type found")
    DispatchQueue.main.async {
      showError(message: "Unsupported file type")
    }
    return false
  }

  print("[VideoEditor Drop] Loading file for type: \(videoType.identifier)")

  // First, extract the original URL using loadItem (provides actual file URL)
  provider.loadItem(forTypeIdentifier: videoType.identifier, options: nil) { item, error in
    if let error = error {
      print("[VideoEditor Drop] loadItem error: \(error)")
      DispatchQueue.main.async {
        self.showError(message: "Failed to load file: \(error.localizedDescription)")
      }
      return
    }

    // Extract original URL from the item
    let originalURL: URL?
    if let url = item as? URL {
      originalURL = url
      print("[VideoEditor Drop] Original URL from loadItem: \(url)")
    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
      originalURL = url
      print("[VideoEditor Drop] Original URL from Data: \(url)")
    } else {
      originalURL = nil
      print("[VideoEditor Drop] Could not extract original URL from item: \(String(describing: item))")
    }

    // Now load file representation to get a working copy
    _ = provider.loadFileRepresentation(forTypeIdentifier: videoType.identifier) { tempURL, repError in
      if let repError = repError {
        print("[VideoEditor Drop] loadFileRepresentation error: \(repError)")
        DispatchQueue.main.async {
          self.showError(message: "Failed to load file: \(repError.localizedDescription)")
        }
        return
      }

      guard let tempURL = tempURL else {
        print("[VideoEditor Drop] No temp URL received")
        DispatchQueue.main.async {
          self.showError(message: "Could not read file")
        }
        return
      }

      print("[VideoEditor Drop] Temp URL: \(tempURL)")

      // Copy temp file to a permanent location before it gets deleted
      let fileName = tempURL.lastPathComponent
      let destURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("VideoEditor_\(UUID().uuidString)")
        .appendingPathComponent(fileName)

      do {
        try FileManager.default.createDirectory(
          at: destURL.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: tempURL, to: destURL)
        print("[VideoEditor Drop] Copied to: \(destURL)")
        print("[VideoEditor Drop] Original URL to preserve: \(originalURL?.path ?? "nil")")

        DispatchQueue.main.async {
          self.validateAndLoad(url: destURL, originalURL: originalURL)
        }
      } catch {
        print("[VideoEditor Drop] Copy error: \(error)")
        DispatchQueue.main.async {
          self.showError(message: "Failed to prepare file: \(error.localizedDescription)")
        }
      }
    }
  }

  return true
}
```

**1.3 Update validateAndLoad() (lines 179-194)**

```swift
// Before
private func validateAndLoad(url: URL) {
  // ... validation ...
  onVideoDropped(url)
}

// After
private func validateAndLoad(url: URL, originalURL: URL? = nil) {
  guard FileManager.default.fileExists(atPath: url.path) else {
    showError(message: "File not found")
    return
  }

  guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
        type.conforms(to: .movie) || type.conforms(to: .video) else {
    showError(message: "Please select a valid video file")
    return
  }

  onVideoDropped(url, originalURL)
}
```

**1.4 Update browseForVideo() call (line 174)**

```swift
// Before
validateAndLoad(url: url)

// After
validateAndLoad(url: url, originalURL: url)  // Browse uses original directly
```

### Step 2: Update VideoEditorWindowController.swift

**2.1 Update callback signature (line 21)**

```swift
// Before
var onVideoLoaded: ((URL) -> Void)?

// After
var onVideoLoaded: ((URL, URL?) -> Void)?
```

**2.2 Add new initializer with originalURL (after line 43)**

```swift
/// Initialize with URL and optional original URL (for drag & drop with temp copy)
init(url: URL, originalURL: URL?) {
  self.sourceURL = url
  self.state = VideoEditorState(url: url, originalURL: originalURL)
  self.isEmptyState = false

  super.init(window: Self.createWindow())
  window?.delegate = self
  setupContent()
}
```

**2.3 Update setupEmptyContent() callback (lines 90-94)**

```swift
// Before
private func setupEmptyContent() {
  let emptyView = VideoEditorEmptyStateView { [weak self] url in
    self?.onVideoLoaded?(url)
  }
  window?.contentView = NSHostingView(rootView: emptyView)
}

// After
private func setupEmptyContent() {
  let emptyView = VideoEditorEmptyStateView { [weak self] url, originalURL in
    self?.onVideoLoaded?(url, originalURL)
  }
  window?.contentView = NSHostingView(rootView: emptyView)
}
```

### Step 3: Update VideoEditorManager.swift

**3.1 Update openEditor(for url:) to accept originalURL (line 57-86)**

```swift
/// Open video editor for a video URL directly
func openEditor(for url: URL, originalURL: URL? = nil) {
  guard isVideoFile(url) else { return }

  // Reuse existing window if open
  if let existing = urlWindowControllers[url] {
    existing.showWindow()
    return
  }

  let controller = VideoEditorWindowController(url: url, originalURL: originalURL)
  urlWindowControllers[url] = controller

  // Remove from tracking when window closes
  if let window = controller.window {
    let observer = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.cleanupURLWindow(for: url)
      }
    }
    urlObservers[url] = observer
  }

  controller.showWindow()
}
```

**3.2 Update handleVideoLoaded() (lines 126-131)**

```swift
// Before
private func handleVideoLoaded(url: URL, from controller: VideoEditorWindowController) {
  emptyWindowController = nil
  controller.window?.close()
  openEditor(for: url)
}

// After
private func handleVideoLoaded(url: URL, originalURL: URL?, from controller: VideoEditorWindowController) {
  emptyWindowController = nil
  controller.window?.close()
  openEditor(for: url, originalURL: originalURL)
}
```

**3.3 Update openEmptyEditor() callback (lines 97-99)**

```swift
// Before
controller.onVideoLoaded = { [weak self] url in
  self?.handleVideoLoaded(url: url, from: controller)
}

// After
controller.onVideoLoaded = { [weak self] url, originalURL in
  self?.handleVideoLoaded(url: url, originalURL: originalURL, from: controller)
}
```

## Testing Checklist

- [ ] **Drag-drop video**: Verify `originalURL` points to actual file location, not temp
- [ ] **Browse button**: Verify `originalURL` equals the selected file path
- [ ] **Replace Original (drag-drop)**: Confirm file replaced at original location
- [ ] **Replace Original (browse)**: Confirm file replaced correctly
- [ ] **Save as Copy**: Verify still works for both flows
- [ ] **Console logs**: Check `[ReplaceOriginal] Original URL (target):` shows correct path

## Expected Behavior After Fix

| Action | sourceURL | originalURL | Replace Original Target |
|--------|-----------|-------------|------------------------|
| Drag-drop | Temp copy | User's original file | User's original file |
| Browse | User's file | User's file | User's file |

## Unresolved Questions

None - the implementation path is clear.
