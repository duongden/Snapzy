//
//  AnnotateCanvasPreset.swift
//  Snapzy
//
//  User-defined presets for annotate canvas effects
//

import AppKit
import Foundation
import SwiftUI

struct AnnotateCanvasPreset: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var payload: AnnotateCanvasPresetPayload
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    name: String,
    payload: AnnotateCanvasPresetPayload,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.payload = payload
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

struct AnnotateCanvasPresetPayload: Codable, Equatable {
  var backgroundStyle: CodableBackgroundStyle
  var padding: CGFloat
  var shadowIntensity: CGFloat
  var cornerRadius: CGFloat

  func approximatelyEquals(
    _ other: AnnotateCanvasPresetPayload,
    tolerance: CGFloat = 0.0001
  ) -> Bool {
    backgroundStyle == other.backgroundStyle &&
      abs(padding - other.padding) <= tolerance &&
      abs(shadowIntensity - other.shadowIntensity) <= tolerance &&
      abs(cornerRadius - other.cornerRadius) <= tolerance
  }
}

struct CodableBackgroundStyle: Codable, Equatable {
  enum Kind: String, Codable {
    case none
    case gradient
    case wallpaper
    case blurred
    case solidColor
  }

  var kind: Kind
  var gradientPresetRawValue: String?
  var urlString: String?
  var solidColorRGBA: RGBAColor?

  init?(from backgroundStyle: BackgroundStyle) {
    switch backgroundStyle {
    case .none:
      kind = .none
      gradientPresetRawValue = nil
      urlString = nil
      solidColorRGBA = nil
    case .gradient(let preset):
      kind = .gradient
      gradientPresetRawValue = preset.rawValue
      urlString = nil
      solidColorRGBA = nil
    case .wallpaper(let url):
      kind = .wallpaper
      gradientPresetRawValue = nil
      urlString = url.absoluteString
      solidColorRGBA = nil
    case .blurred(let url):
      kind = .blurred
      gradientPresetRawValue = nil
      urlString = url.absoluteString
      solidColorRGBA = nil
    case .solidColor(let color):
      guard let rgba = RGBAColor(color: color) else { return nil }
      kind = .solidColor
      gradientPresetRawValue = nil
      urlString = nil
      solidColorRGBA = rgba
    }
  }

  func toBackgroundStyle() -> BackgroundStyle {
    switch kind {
    case .none:
      return .none
    case .gradient:
      guard let raw = gradientPresetRawValue,
            let preset = GradientPreset(rawValue: raw) else {
        return .none
      }
      return .gradient(preset)
    case .wallpaper:
      guard let urlString,
            let url = URL(string: urlString) else {
        return .none
      }
      return .wallpaper(url)
    case .blurred:
      guard let urlString,
            let url = URL(string: urlString) else {
        return .none
      }
      return .blurred(url)
    case .solidColor:
      guard let solidColorRGBA else {
        return .none
      }
      return .solidColor(solidColorRGBA.color)
    }
  }
}

struct RGBAColor: Codable, Equatable {
  var red: Double
  var green: Double
  var blue: Double
  var alpha: Double

  init(red: Double, green: Double, blue: Double, alpha: Double) {
    self.red = min(max(red, 0), 1)
    self.green = min(max(green, 0), 1)
    self.blue = min(max(blue, 0), 1)
    self.alpha = min(max(alpha, 0), 1)
  }

  init?(color: Color) {
    guard let srgb = NSColor(color).usingColorSpace(.sRGB) else {
      return nil
    }

    self.init(
      red: Double(srgb.redComponent),
      green: Double(srgb.greenComponent),
      blue: Double(srgb.blueComponent),
      alpha: Double(srgb.alphaComponent)
    )
  }

  var color: Color {
    Color(
      nsColor: NSColor(
        srgbRed: red,
        green: green,
        blue: blue,
        alpha: alpha
      )
    )
  }
}
