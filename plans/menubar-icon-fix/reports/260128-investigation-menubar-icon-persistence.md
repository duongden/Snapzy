# Menubar Icon Persistence Investigation Report

**Date:** 2026-01-28
**Issue:** Red recording dot (●) persists after recording stops
**Status:** Root cause identified

## Root Cause Analysis

### PRIMARY ISSUE: State Update Timing Race Condition

**File:** `ScreenRecordingManager.swift:306-335` (stopRecording method)
**File:** `ScreenRecordingManager.swift:338-357` (cancelRecording method)

The `cleanup()` call that resets `state = .idle` happens AFTER async operations complete, but StatusBarController observes state changes immediately. The issue is in the execution flow:

```swift
func stopRecording() async -> URL? {
    guard state == .recording || state == .paused else { return nil }

    session.isCapturing = false

    state = .stopping  // ❌ StatusBarController sees .stopping, shows recording icon

    timer?.invalidate()
    timer = nil

    if let activeStream = stream {
        try await activeStream.stopCapture()  // Async operation
    }
    stream = nil

    session.finishInputs()
    await session.finishWriting()  // Async operation

    let url = outputURL

    cleanup()  // ✅ Sets state = .idle HERE, but only AFTER all async work

    return url
}
```

### State Observation Chain

1. **StatusBarController.swift:111-118** - Observes state changes:
   ```swift
   recorder.$state
       .receive(on: RunLoop.main)
       .sink { [weak self] state in
           self?.updateStatusIcon(for: state)
       }
       .store(in: &cancellables)
   ```

2. **StatusBarController.swift:120-169** - Updates icon based on state:
   ```swift
   switch state {
   case .recording:
       iconName = "record.circle.fill"
       useTemplate = false
   case .paused:
       iconName = "pause.circle.fill"
       useTemplate = false
   case .preparing, .stopping:  // ❌ .stopping shows recording icon
       iconName = "record.circle"
       useTemplate = false
   case .idle:  // ✅ Only this resets to normal icon
       iconName = "camera.aperture"
       useTemplate = true
   ```

### Why Icon Persists

1. User stops recording → calls `ScreenRecordingManager.stopRecording()`
2. State immediately set to `.stopping` (line 311)
3. StatusBarController receives `.stopping` state → shows `record.circle` icon (red dot)
4. Async operations execute (stream stop, session finish)
5. `cleanup()` finally sets `state = .idle` (line 552)
6. StatusBarController receives `.idle` state → SHOULD reset icon

### The Race Condition

The icon SHOULD reset when `cleanup()` sets `state = .idle`, but inspection shows potential issues:

**TIMING ISSUE:** Between steps 2-5, if any async operation delays or StatusBarController's Combine subscription doesn't fire for `.idle` transition, icon stays red.

**OBSERVATION:** The previous fix moved `cleanup()` inside Task blocks in RecordingCoordinator (lines 99-101, 107-109), but this doesn't address the CORE issue - ScreenRecordingManager's state still transitions through `.stopping` before `.idle`.

## State Flow Trace

### Normal Stop Flow
```
RecordingCoordinator.stopRecording()
  → calls ScreenRecordingManager.stopRecording()
    → state = .stopping ━━━━━━━━━━┓
    → [async stream stop]          ┃
    → [async session finish]       ┃ StatusBarController observes
    → cleanup()                    ┃ Shows red icon for .stopping
      → state = .idle ━━━━━━━━━━━━┫
                                   ┗━━ Should reset to normal icon
```

### StatusBar Click Stop Flow
```
StatusBarController.stopRecording() (line 43-54)
  → calls ScreenRecordingManager.stopRecording()
    → [same flow as above]
  → calls RecordingCoordinator.cancel() (line 52)
    → calls ScreenRecordingManager.cancelRecording() AGAIN
      → But state is already .stopping, guard fails
```

## Secondary Issues Found

### 1. Potential Double Cleanup
**File:** `StatusBarController.swift:43-54`

```swift
func stopRecording() {
    Task {
        let url = await ScreenRecordingManager.shared.stopRecording()
        if let url = url {
            NSSound(named: "Glass")?.play()
            await QuickAccessManager.shared.addVideo(url: url)
        }
        RecordingCoordinator.shared.cancel()  // ❌ Calls cancelRecording again
    }
}
```

After `stopRecording()` completes and sets state to `.idle`, calling `RecordingCoordinator.cancel()` attempts `cancelRecording()` which will fail the guard check (state != recording/paused).

### 2. State Transition Not Guaranteed
**File:** `ScreenRecordingManager.swift:549-554`

```swift
private func cleanup() {
    session.reset()
    outputURL = nil
    state = .idle  // ✅ Sets to idle
    elapsedSeconds = 0
}
```

This cleanup is NOT marked `@MainActor` explicitly in its definition, but the class is `@MainActor`. However, it's called from within async context after awaits - there's potential for state update to not propagate immediately to observers.

### 3. Icon Update Logic Issue
**File:** `StatusBarController.swift:133-135`

```swift
case .preparing, .stopping:
    iconName = "record.circle"
    useTemplate = false
```

Both `.preparing` AND `.stopping` show the same recording-style icon. This means ANY time state is `.stopping`, icon appears as recording (red dot).

## Why Previous Fix Didn't Work

The previous fix moved `cleanup()` inside Task blocks in RecordingCoordinator's `cancel()` and `deleteRecording()` methods:

```swift
// RecordingCoordinator.swift:97-102
func cancel() {
    Task {
        await recorder.cancelRecording()
        cleanup()  // RecordingCoordinator cleanup
    }
}
```

But this only cleans up RecordingCoordinator's UI (toolbar, overlays). It doesn't affect ScreenRecordingManager's state transition timing.

The icon persistence happens because:
1. ScreenRecordingManager sets `state = .stopping` BEFORE cleanup
2. StatusBarController immediately shows recording icon for `.stopping`
3. State eventually becomes `.idle` but observer may not fire/update

## Recommended Fix

### Option 1: Skip .stopping State for Icon (SIMPLE)
**File:** `StatusBarController.swift:120-169`

Change icon update logic to treat `.stopping` same as `.idle`:

```swift
private func updateStatusIcon(for state: RecordingState) {
    guard let button = statusItem?.button else { return }

    let iconName: String
    let useTemplate: Bool

    switch state {
    case .recording:
        iconName = "record.circle.fill"
        useTemplate = false
    case .paused:
        iconName = "pause.circle.fill"
        useTemplate = false
    case .preparing:
        iconName = "record.circle"
        useTemplate = false
    case .stopping, .idle:  // Treat stopping same as idle
        iconName = "camera.aperture"
        useTemplate = true
    }
    // ... rest of method
}
```

**Pros:** Minimal change, immediate visual fix
**Cons:** Doesn't address underlying race condition, `.stopping` visually appears as idle

### Option 2: Set .idle Immediately Before Async Ops (BETTER)
**File:** `ScreenRecordingManager.swift:306-335`

Reset state to `.idle` BEFORE async operations:

```swift
func stopRecording() async -> URL? {
    guard state == .recording || state == .paused else { return nil }

    session.isCapturing = false

    // DON'T set to .stopping
    timer?.invalidate()
    timer = nil

    // Capture references before cleanup
    let activeStream = stream
    let shouldFinish = session.assetWriter != nil
    let url = outputURL

    // Reset state IMMEDIATELY so StatusBarController updates
    cleanup()  // Sets state = .idle NOW

    // Then do async cleanup (state already idle)
    if let activeStream = activeStream {
        try? await activeStream.stopCapture()
    }

    if shouldFinish {
        session.finishInputs()
        await session.finishWriting()
    }

    return url
}
```

**Pros:** Fixes race condition, icon resets immediately
**Cons:** State shows `.idle` while async cleanup ongoing (but this is acceptable)

### Option 3: Explicit State Reset in StatusBarController (SAFEST)
**File:** `StatusBarController.swift:43-54`

Ensure state is explicitly reset after stop:

```swift
func stopRecording() {
    Task {
        let url = await ScreenRecordingManager.shared.stopRecording()

        // Explicitly ensure state is idle
        if ScreenRecordingManager.shared.state != .idle {
            // Force update if needed (should not happen with proper fix)
            await MainActor.run {
                updateStatusIcon(for: .idle)
            }
        }

        if let url = url {
            NSSound(named: "Glass")?.play()
            await QuickAccessManager.shared.addVideo(url: url)
        }
        RecordingCoordinator.shared.cancel()
    }
}
```

**Pros:** Defensive programming, guarantees icon reset
**Cons:** Workaround rather than root cause fix

## Unresolved Questions

1. Is there a specific scenario where Combine publisher doesn't fire for `.idle` transition?
2. Should `.stopping` state exist at all, or can it be removed?
3. Is there explicit requirement for UI to show "stopping" state visually?
4. Why does StatusBarController call RecordingCoordinator.cancel() after stopRecording completes?

## Recommendation

**IMPLEMENT OPTION 2** - Move cleanup() before async operations in ScreenRecordingManager.

This addresses root cause by ensuring state = .idle happens synchronously before any async work, guaranteeing StatusBarController receives state update immediately.

Then **ADD OPTION 3** as defensive measure to ensure icon always resets even if state observation fails.

Also **REMOVE** redundant RecordingCoordinator.cancel() call from StatusBarController.stopRecording() (line 52).
