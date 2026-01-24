//
//  VideoEditorSidebarComponents.swift
//  ClaudeShot
//
//  Dedicated sidebar components for video editor (decoupled from Annotate)
//

import SwiftUI

// MARK: - Section Header

struct VideoSidebarSectionHeader: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.system(size: 11, weight: .semibold))
      .foregroundColor(.secondary)
      .textCase(.uppercase)
  }
}

// MARK: - Gradient Preset Button

struct VideoGradientPresetButton: View {
  let preset: GradientPreset
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: 4)
        .fill(LinearGradient(colors: preset.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .frame(width: 32, height: 32)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Color Swatch Grid

struct VideoColorSwatchGrid: View {
  @Binding var selectedColor: Color?

  private let colors: [Color] = [
    .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray, .white, .black
  ]

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
      ForEach(colors, id: \.self) { color in
        Button {
          selectedColor = color
        } label: {
          Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(
              Circle()
                .stroke(selectedColor == color ? Color.accentColor : Color.secondary.opacity(0.5), lineWidth: selectedColor == color ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
      }
    }
  }
}

// MARK: - Slider Row

struct VideoSliderRow: View {
  let label: String
  @Binding var value: CGFloat
  let range: ClosedRange<CGFloat>

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(label)
          .font(.system(size: 10))
          .foregroundColor(.secondary)
        Spacer()
        Text(String(format: "%.0f", value))
          .font(.system(size: 10))
          .foregroundColor(.secondary.opacity(0.7))
      }
      Slider(value: $value, in: range)
        .controlSize(.small)
    }
  }
}
