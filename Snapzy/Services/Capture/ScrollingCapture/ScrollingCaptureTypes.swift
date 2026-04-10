//
//  ScrollingCaptureTypes.swift
//  Snapzy
//
//  Shared state and feature toggles for scrolling capture.
//

import AppKit
import ApplicationServices
import Combine
import Foundation

enum ScrollingCapturePhase {
  case ready
  case capturing
  case saving
}

enum ScrollingCaptureFeature {
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: PreferencesKeys.scrollingCaptureEnabled) as? Bool ?? false
  }

  static var defaultAutoScrollEnabled: Bool {
    UserDefaults.standard.object(forKey: PreferencesKeys.scrollingCaptureAutoScrollEnabled) as? Bool ?? false
  }

  static var showHints: Bool {
    UserDefaults.standard.object(forKey: PreferencesKeys.scrollingCaptureShowHints) as? Bool ?? true
  }

  static let maxOutputHeight = 32_768
}

@MainActor
final class ScrollingCaptureSessionModel: ObservableObject {
  @Published var selectedRect: CGRect
  @Published var phase: ScrollingCapturePhase = .ready
  @Published var statusText = "Adjust the region so only the moving content stays inside, then press Start Capture."
  @Published var previewCaption = "Start Capture to lock the first frame"
  @Published var previewImage: NSImage?
  @Published var acceptedFrameCount = 0
  @Published var stitchedPixelHeight = 0
  @Published var autoScrollEnabled: Bool
  @Published var autoScrollAvailable: Bool
  @Published var autoScrollStatusText: String
  @Published var isAutoScrolling = false

  init(selectedRect: CGRect) {
    let autoScrollAvailable = AXIsProcessTrusted()
    self.selectedRect = selectedRect
    self.autoScrollEnabled = ScrollingCaptureFeature.defaultAutoScrollEnabled
    self.autoScrollAvailable = autoScrollAvailable
    self.autoScrollStatusText = autoScrollAvailable
      ? "Auto-scroll can start after the first frame is locked."
      : "Auto-scroll needs Accessibility permission."
  }

  var selectionSummary: String {
    "\(Int(selectedRect.width)) x \(Int(selectedRect.height))"
  }
}
