//
//  AreaSelectionBackdrop.swift
//  Snapzy
//
//  Shared models for area selection backdrops and results.
//

import CoreGraphics
import Foundation

typealias AreaSelectionResultCompletion = (AreaSelectionResult?) -> Void

enum AreaSelectionInteractionMode {
  case manualRegion
  case applicationWindow
}

struct AreaSelectionBackdrop {
  let displayID: CGDirectDisplayID
  let image: CGImage
  let scaleFactor: CGFloat
}

struct WindowCaptureTarget: Equatable {
  let windowID: CGWindowID
  let frame: CGRect
  let displayID: CGDirectDisplayID
  let title: String?
  let bundleIdentifier: String?
}

enum AreaSelectionTarget: Equatable {
  case rect(CGRect)
  case window(WindowCaptureTarget)

  var rect: CGRect {
    switch self {
    case .rect(let rect):
      rect
    case .window(let target):
      target.frame
    }
  }

  var windowTarget: WindowCaptureTarget? {
    switch self {
    case .rect:
      nil
    case .window(let target):
      target
    }
  }
}

struct AreaSelectionApplicationConfiguration {
  let prefetchedContentTask: ShareableContentPrefetchTask?
  let excludeOwnApplication: Bool
}

struct AreaSelectionResult {
  let target: AreaSelectionTarget
  let displayID: CGDirectDisplayID
  let mode: SelectionMode

  var rect: CGRect {
    target.rect
  }
}
