//
//  AnnotateCanvasPresetStore.swift
//  Snapzy
//
//  Persistence for annotate canvas presets
//

import Foundation

@MainActor
final class AnnotateCanvasPresetStore {
  static let shared = AnnotateCanvasPresetStore()

  private let defaults = UserDefaults.standard
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  private init() {
    encoder.outputFormatting = []
  }

  func loadPresets() -> [AnnotateCanvasPreset] {
    guard let data = defaults.data(forKey: PreferencesKeys.annotateCanvasPresets) else {
      return []
    }

    do {
      let decoded = try decoder.decode([AnnotateCanvasPreset].self, from: data)
      return decoded.sorted(by: { $0.updatedAt > $1.updatedAt })
    } catch {
      defaults.removeObject(forKey: PreferencesKeys.annotateCanvasPresets)
      return []
    }
  }

  func savePresets(_ presets: [AnnotateCanvasPreset]) {
    do {
      let data = try encoder.encode(presets)
      defaults.set(data, forKey: PreferencesKeys.annotateCanvasPresets)
    } catch {
      print("Failed to save annotate canvas presets: \(error.localizedDescription)")
    }
  }
}
