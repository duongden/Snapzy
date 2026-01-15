//
//  FloatingPosition.swift
//  ZapShot
//
//  Screen corner positions for floating panel placement
//

import AppKit
import Foundation

/// Screen corner positions for floating screenshot panel
enum FloatingPosition: String, CaseIterable, Codable {
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight

  /// Calculate origin point for panel placement
  func calculateOrigin(for size: CGSize, on screen: NSScreen, padding: CGFloat = 20) -> CGPoint {
    let frame = screen.visibleFrame

    switch self {
    case .topLeft:
      return CGPoint(x: frame.minX + padding, y: frame.maxY - size.height - padding)
    case .topRight:
      return CGPoint(x: frame.maxX - size.width - padding, y: frame.maxY - size.height - padding)
    case .bottomLeft:
      return CGPoint(x: frame.minX + padding, y: frame.minY + padding)
    case .bottomRight:
      return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding)
    }
  }

  /// Display name for UI
  var displayName: String {
    switch self {
    case .topLeft: return "Top Left"
    case .topRight: return "Top Right"
    case .bottomLeft: return "Bottom Left"
    case .bottomRight: return "Bottom Right"
    }
  }
}
