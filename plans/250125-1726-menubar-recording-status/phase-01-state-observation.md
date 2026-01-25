# Phase 01: State Observation Setup

## Context Links
- Main plan: [plan.md](./plan.md)
- Technical analysis: [reports/01-technical-analysis.md](./reports/01-technical-analysis.md)

## Overview
Create observable state bridge between ScreenRecordingManager and status bar UI. Enable reactive updates when recording state changes.

## Key Insights
- ScreenRecordingManager already publishes `state` via `@Published`
- Need to observe from non-SwiftUI context (NSStatusItem)
- Combine subscription required for AppKit integration

## Requirements
1. Observable recording state accessible from StatusBarController
2. Reactive icon updates when state changes
3. No polling - event-driven updates only

## Architecture

```
ScreenRecordingManager (@Published state)
         |
         v
    Combine Publisher
         |
         v
  StatusBarController (sink subscriber)
         |
         v
    NSStatusItem.button.image
```

## Related Files
- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/Core/ScreenRecordingManager.swift`
- `/Users/duongductrong/Developer/ZapShot/ClaudeShot/App/ClaudeShotApp.swift`

## Implementation Steps

### Step 1: Create StatusBarController skeleton
```swift
// ClaudeShot/App/StatusBarController.swift
import AppKit
import Combine

@MainActor
final class StatusBarController: ObservableObject {
  static let shared = StatusBarController()

  private var statusItem: NSStatusItem?
  private var cancellables = Set<AnyCancellable>()
  private let recorder = ScreenRecordingManager.shared

  private init() {}

  func setup() {
    setupStatusItem()
    observeRecordingState()
  }
}
```

### Step 2: Setup state observation
```swift
private func observeRecordingState() {
  recorder.$state
    .receive(on: RunLoop.main)
    .sink { [weak self] state in
      self?.updateStatusIcon(for: state)
    }
    .store(in: &cancellables)
}
```

### Step 3: Icon update method
```swift
private func updateStatusIcon(for state: RecordingState) {
  let iconName: String
  switch state {
  case .recording, .paused:
    iconName = "record.circle.fill"
  default:
    iconName = "camera.aperture"
  }

  statusItem?.button?.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "ClaudeShot")
}
```

## Todo List
- [ ] Create StatusBarController.swift file
- [ ] Add Combine subscription to ScreenRecordingManager.$state
- [ ] Implement updateStatusIcon method
- [ ] Test state transitions: idle -> preparing -> recording -> stopping -> idle
- [ ] Verify icon updates reactively

## Success Criteria
- Icon changes to `record.circle.fill` when recording starts
- Icon reverts to `camera.aperture` when recording stops
- No delay between state change and icon update
- No memory leaks from subscription

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Main thread issues | Low | High | Use `receive(on: RunLoop.main)` |
| Subscription leak | Low | Medium | Store in cancellables set |

## Security Considerations
None - UI state observation only.

## Next Steps
Proceed to Phase 02: Dynamic Icon Implementation
