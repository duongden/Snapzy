//
//  AnnotationItem.swift
//  ZapShot
//
//  Model representing a single annotation element
//

import CoreGraphics
import Foundation
import SwiftUI

/// Single annotation element on the canvas
struct AnnotationItem: Identifiable, Equatable {
  let id: UUID
  var type: AnnotationType
  var bounds: CGRect
  var properties: AnnotationProperties

  init(type: AnnotationType, bounds: CGRect, properties: AnnotationProperties) {
    self.id = UUID()
    self.type = type
    self.bounds = bounds
    self.properties = properties
  }

  static func == (lhs: AnnotationItem, rhs: AnnotationItem) -> Bool {
    lhs.id == rhs.id
  }
}

/// Types of annotations
enum AnnotationType: Equatable {
  case path([CGPoint])
  case rectangle
  case oval
  case arrow(start: CGPoint, end: CGPoint)
  case line(start: CGPoint, end: CGPoint)
  case text(String)
  case highlight([CGPoint])
  case blur
  case counter(Int)
}

/// Visual properties for an annotation
struct AnnotationProperties: Equatable {
  var strokeColor: Color
  var fillColor: Color
  var strokeWidth: CGFloat
  var fontSize: CGFloat
  var fontName: String

  init(
    strokeColor: Color = .red,
    fillColor: Color = .clear,
    strokeWidth: CGFloat = 3,
    fontSize: CGFloat = 16,
    fontName: String = "SF Pro"
  ) {
    self.strokeColor = strokeColor
    self.fillColor = fillColor
    self.strokeWidth = strokeWidth
    self.fontSize = fontSize
    self.fontName = fontName
  }
}
