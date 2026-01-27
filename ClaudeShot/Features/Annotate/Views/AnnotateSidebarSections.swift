//
//  AnnotateSidebarSections.swift
//  ClaudeShot
//
//  Section components for the annotation sidebar
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Gradient Section

struct SidebarGradientSection: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SidebarSectionHeader(title: "Gradients")

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
        ForEach(GradientPreset.allCases) { preset in
          GradientPresetButton(
            preset: preset,
            isSelected: state.backgroundStyle == .gradient(preset)
          ) {
            state.backgroundStyle = .gradient(preset)
          }
        }
      }
    }
  }
}

// MARK: - Wallpaper Section

struct SidebarWallpaperSection: View {
  @ObservedObject var state: AnnotateState
  @State private var customWallpapers: [URL] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      SidebarSectionHeader(title: "Wallpapers")

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
        // 3 bundled presets
        ForEach(WallpaperPreset.allCases) { preset in
          WallpaperPresetButton(
            preset: preset,
            isSelected: isPresetSelected(preset)
          ) {
            selectPreset(preset)
          }
        }

        // Custom wallpapers from disk
        ForEach(customWallpapers, id: \.self) { url in
          CustomWallpaperButton(
            url: url,
            isSelected: isUrlSelected(url)
          ) {
            if state.padding <= 0 {
              state.padding = 24
            }
            state.backgroundStyle = .wallpaper(url)
          }
        }

        // Add button
        AddWallpaperButton {
          addWallpaper()
        }
      }
    }
  }

  private func isPresetSelected(_ preset: WallpaperPreset) -> Bool {
    if case .wallpaper(let url) = state.backgroundStyle {
      return url.absoluteString == "preset://\(preset.rawValue)"
    }
    return false
  }

  private func isUrlSelected(_ url: URL) -> Bool {
    if case .wallpaper(let selectedUrl) = state.backgroundStyle {
      return selectedUrl == url
    }
    return false
  }

  private func selectPreset(_ preset: WallpaperPreset) {
    if state.padding <= 0 {
      state.padding = 24
    }
    // Use a special URL scheme for presets
    state.backgroundStyle = .wallpaper(URL(string: "preset://\(preset.rawValue)")!)
  }

  private func addWallpaper() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK, let url = panel.url {
      customWallpapers.append(url)
      if state.padding <= 0 {
        state.padding = 24
      }
      state.backgroundStyle = .wallpaper(url)
    }
  }
}

// MARK: - Blurred Section

struct SidebarBlurredSection: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SidebarSectionHeader(title: "Blurred")

      HStack(spacing: 8) {
        BlurredPlaceholder()
        BlurredPlaceholder()
      }
    }
  }
}

// MARK: - Color Section

struct SidebarColorSection: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SidebarSectionHeader(title: "Plain color")
      ColorSwatchGrid(selectedColor: colorBinding)
    }
  }

  private var colorBinding: Binding<Color?> {
    Binding(
      get: {
        if case .solidColor(let color) = state.backgroundStyle {
          return color
        }
        return nil
      },
      set: { newColor in
        if let color = newColor {
          state.backgroundStyle = .solidColor(color)
        }
      }
    )
  }
}

// MARK: - Sliders Section

struct SidebarSlidersSection: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SliderRow(label: "Padding", value: $state.padding, range: 0...100)
      SliderRow(label: "Inset", value: $state.inset, range: 0...50)

      Toggle("Auto-balance", isOn: $state.autoBalance)
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.8))
        .padding(.leading, 4)

      SliderRow(label: "Shadow", value: $state.shadowIntensity, range: 0...1)
      SliderRow(label: "Corners", value: $state.cornerRadius, range: 0...32)
    }
  }
}

// MARK: - Blur Type Section

struct BlurTypeSection: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SidebarSectionHeader(title: "Blur Type")

      HStack(spacing: 8) {
        ForEach(BlurType.allCases) { blurType in
          BlurTypeButton(
            blurType: blurType,
            isSelected: state.blurType == blurType
          ) {
            state.blurType = blurType
          }
        }
      }

      Text(state.blurType == .pixelated
           ? "Pixelated blur for redacting sensitive content"
           : "Smooth Gaussian blur similar to CSS filter")
        .font(.system(size: 10))
        .foregroundColor(.secondary)
        .padding(.top, 2)
    }
  }
}

struct BlurTypeButton: View {
  let blurType: BlurType
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: blurType.icon)
          .font(.system(size: 16))
          .foregroundColor(isSelected ? .accentColor : .primary)

        Text(blurType.displayName)
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(isSelected ? .accentColor : .secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var backgroundColor: Color {
    if isSelected {
      return Color.accentColor.opacity(0.15)
    } else if isHovering {
      return Color.primary.opacity(0.08)
    }
    return Color.primary.opacity(0.05)
  }
}
