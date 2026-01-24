//
//  VideoBackgroundSidebarView.swift
//  ClaudeShot
//
//  Background customization sidebar for video editor
//

import SwiftUI

/// Sidebar content for video background and padding customization
struct VideoBackgroundSidebarView: View {
  @ObservedObject var state: VideoEditorState

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 12) {
        noneButton
        gradientSection
        colorSection

        Divider().background(Color(nsColor: .separatorColor))

        slidersSection

        Spacer(minLength: 20)
      }
      .padding(12)
    }
    .frame(maxHeight: .infinity)
  }

  // MARK: - None Button

  private var noneButton: some View {
    Button {
      state.backgroundStyle = .none
      state.backgroundPadding = 0
    } label: {
      Text("None")
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(state.backgroundStyle == .none ? Color.blue.opacity(0.3) : Color.primary.opacity(0.1))
        )
    }
    .buttonStyle(.plain)
  }

  // MARK: - Gradient Section

  private var gradientSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      SidebarSectionHeader(title: "Gradients")

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
        ForEach(GradientPreset.allCases) { preset in
          GradientPresetButton(
            preset: preset,
            isSelected: state.backgroundStyle == .gradient(preset)
          ) {
            if state.backgroundPadding <= 0 {
              state.backgroundPadding = 24
            }
            state.backgroundStyle = .gradient(preset)
          }
        }
      }
    }
  }

  // MARK: - Color Section

  private var colorSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      SidebarSectionHeader(title: "Colors")
      CompactColorSwatchGrid(selectedColor: colorBinding)
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
          if state.backgroundPadding <= 0 {
            state.backgroundPadding = 24
          }
          state.backgroundStyle = .solidColor(color)
        }
      }
    )
  }

  // MARK: - Sliders Section

  private var slidersSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      CompactSliderRow(
        label: "Padding",
        value: Binding(
          get: { state.backgroundPadding },
          set: { newValue in
            state.backgroundPadding = newValue
            // Auto-apply white background when padding increases from 0
            if newValue > 0 && state.backgroundStyle == .none {
              state.backgroundStyle = .solidColor(.white)
            }
          }
        ),
        range: 0...100
      )
      CompactSliderRow(label: "Shadow", value: $state.backgroundShadowIntensity, range: 0...1)
      CompactSliderRow(label: "Corners", value: $state.backgroundCornerRadius, range: 0...32)
    }
  }
}
