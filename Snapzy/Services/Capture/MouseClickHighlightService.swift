//
//  MouseClickHighlightService.swift
//  Snapzy
//
//  Detects global mouse clicks and forwards them to the click highlight overlay
//  so they appear in screen recordings.
//

import AppKit
import Foundation

@MainActor
final class MouseClickHighlightService {

  private var globalMonitor: Any?
  private var localMonitor: Any?
  private var recordingRect: CGRect = .zero
  private var isRunning = false

  /// Called on each detected click with the screen-space position
  var onClickDetected: ((NSPoint) -> Void)?

  func start(recordingRect: CGRect) {
    guard !isRunning else { return }
    isRunning = true
    self.recordingRect = recordingRect

    // Global monitor — clicks when Snapzy is NOT the key app
    globalMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] event in
      MainActor.assumeIsolated {
        self?.handleClick(event)
      }
    }

    // Local monitor — clicks when Snapzy IS the key app
    localMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] event in
      MainActor.assumeIsolated {
        self?.handleClick(event)
      }
      return event
    }
  }

  func stop() {
    isRunning = false

    if let monitor = globalMonitor {
      NSEvent.removeMonitor(monitor)
      globalMonitor = nil
    }

    if let monitor = localMonitor {
      NSEvent.removeMonitor(monitor)
      localMonitor = nil
    }

    onClickDetected = nil
  }

  func updateRecordingRect(_ rect: CGRect) {
    recordingRect = rect
  }

  private func handleClick(_ event: NSEvent) {
    let location = NSEvent.mouseLocation

    // Only fire for clicks inside the recording area
    guard recordingRect.contains(location) else { return }

    onClickDetected?(location)
  }
}
