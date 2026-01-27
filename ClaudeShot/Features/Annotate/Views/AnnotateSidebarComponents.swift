//
//  AnnotateSidebarComponents.swift
//  ClaudeShot
//
//  Reusable components for the annotation sidebar
//

import SwiftUI

// MARK: - Section Header

struct SidebarSectionHeader: View {
  let title: String

  var body: some View {
    Text(title)
      .font(Typography.sectionHeader)
      .foregroundColor(SidebarColors.labelSecondary)
  }
}

// MARK: - Gradient Preset Button

struct GradientPresetButton: View {
  let preset: GradientPreset
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: Size.radiusMd)
        .fill(LinearGradient(colors: preset.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .sidebarItemStyle(isSelected: isSelected)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Placeholders

struct WallpaperPlaceholder: View {
  var body: some View {
    RoundedRectangle(cornerRadius: Size.radiusMd)
      .fill(Color.gray.opacity(0.3))
      .frame(width: Size.gridItem, height: Size.gridItem)
  }
}

// MARK: - Wallpaper Preset Button

struct WallpaperPresetButton: View {
  let preset: WallpaperPreset
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: Size.radiusMd)
        .fill(preset.gradient)
        .sidebarItemStyle(isSelected: isSelected)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Custom Wallpaper Button

struct CustomWallpaperButton: View {
  let url: URL
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Group {
        if let image = NSImage(contentsOf: url) {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Color.gray.opacity(0.3)
        }
      }
      .sidebarItemStyle(isSelected: isSelected)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Add Wallpaper Button

struct AddWallpaperButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "plus")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.primary.opacity(0.5))
        .actionButtonStyle()
    }
    .buttonStyle(.plain)
  }
}

struct BlurredPlaceholder: View {
  var body: some View {
    RoundedRectangle(cornerRadius: Size.radiusMd)
      .fill(Color.gray.opacity(0.2))
      .frame(width: Size.gridItem, height: Size.gridItem)
      .blur(radius: 2)
  }
}

// MARK: - Color Swatch Grid

struct ColorSwatchGrid: View {
  @Binding var selectedColor: Color?

  private let colors: [[Color]] = [
    [.red, .orange, .yellow, .green, .blue, .purple, .pink],
    [.gray, .white, .black, Color(white: 0.3), Color(white: 0.5), Color(white: 0.7), Color(white: 0.9)]
  ]

  var body: some View {
    VStack(spacing: Spacing.sm) {
      ForEach(0..<colors.count, id: \.self) { row in
        HStack(spacing: Spacing.sm) {
          ForEach(0..<colors[row].count, id: \.self) { col in
            ColorSwatch(
              color: colors[row][col],
              isSelected: selectedColor == colors[row][col]
            ) {
              selectedColor = colors[row][col]
            }
          }
        }
      }
    }
  }
}

struct ColorSwatch: View {
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Circle()
        .fill(color)
        .colorSwatchStyle(isSelected: isSelected)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Slider Row

struct SliderRow: View {
  let label: String
  @Binding var value: CGFloat
  let range: ClosedRange<CGFloat>

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xs) {
      Text(label)
        .font(Typography.labelMedium)
        .foregroundColor(SidebarColors.labelSecondary)

      Slider(value: $value, in: range)
        .controlSize(.small)
    }
  }
}

// MARK: - Alignment Grid

struct AlignmentGrid: View {
  @Binding var selected: ImageAlignment
  var onAlignmentChange: ((ImageAlignment) -> Void)? = nil

  private let alignments: [[ImageAlignment]] = [
    [.topLeft, .top, .topRight],
    [.left, .center, .right],
    [.bottomLeft, .bottom, .bottomRight]
  ]

  var body: some View {
    VStack(spacing: 2) {
      ForEach(0..<3, id: \.self) { row in
        HStack(spacing: 2) {
          ForEach(0..<3, id: \.self) { col in
            AlignmentCell(
              alignment: alignments[row][col],
              isSelected: selected == alignments[row][col]
            ) {
              let newAlignment = alignments[row][col]
              selected = newAlignment
              onAlignmentChange?(newAlignment)
            }
          }
        }
      }
    }
    .padding(Spacing.xs)
    .background(SidebarColors.itemDefault)
    .cornerRadius(Size.radiusSm)
  }
}

struct AlignmentCell: View {
  let alignment: ImageAlignment
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Rectangle()
        .fill(backgroundColor)
        .frame(width: 20, height: 20)
        .cornerRadius(Size.radiusXs)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var backgroundColor: Color {
    if isSelected { return .accentColor }
    if isHovering { return SidebarColors.itemHover }
    return Color.secondary.opacity(0.3)
  }
}
