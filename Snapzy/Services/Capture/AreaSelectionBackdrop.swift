//
//  AreaSelectionBackdrop.swift
//  Snapzy
//
//  Shared models for area selection backdrops and results.
//

import CoreGraphics
import Foundation

typealias AreaSelectionResultCompletion = (AreaSelectionResult?) -> Void

struct AreaSelectionBackdrop {
  let displayID: CGDirectDisplayID
  let image: CGImage
  let scaleFactor: CGFloat
}

struct AreaSelectionResult {
  let rect: CGRect
  let displayID: CGDirectDisplayID
  let mode: SelectionMode
}
