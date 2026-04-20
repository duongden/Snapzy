//
//  VideoEditorGIFSettingsPanel.swift
//  Snapzy
//
//  Export settings panel for GIF files in video editor
//  Provides dimension presets and estimated file size
//

import SwiftUI

/// Export settings panel for GIF mode
struct VideoEditorGIFSettingsPanel: View {
  @ObservedObject var state: VideoEditorState

  var body: some View {
    HStack(alignment: .top, spacing: 24) {
      // Dimensions section
      dimensionsSection

      Divider()
        .frame(height: 80)

      // Info section
      infoSection

      Spacer()

      // File size estimate
      fileSizeSection
    }
    .padding(12)
  }

  // MARK: - Dimensions Section

  private var dimensionsSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(L10n.Common.dimensions)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.secondary)

      Picker("", selection: dimensionPresetBinding) {
        ForEach(ExportDimensionPreset.allCases) { preset in
          Text(preset.displayLabel(for: state.naturalSize))
            .tag(preset)
        }
      }
      .pickerStyle(.menu)
      .frame(minWidth: 180)
      .controlSize(.small)

      aspectRatioPresetRow

      if state.exportSettings.dimensionPreset == .custom {
        customDimensionFields
      } else if state.exportSettings.dimensionPreset != .original {
        fileSizeReductionHint
      }
    }
  }

  private var aspectRatioPresetRow: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: "aspectratio")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.accentColor)
            .frame(width: 18, height: 18)
            .background(
              RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.14))
            )

          Text(L10n.Common.aspectRatio)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary)
        }

        Spacer(minLength: 8)

        if let exportAspectRatioText {
          Text(exportAspectRatioText)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
            .monospacedDigit()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
              Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
            )
        }
      }

      HStack(spacing: 4) {
        ForEach(ExportDimensionPreset.aspectRatioPresets) { preset in
          aspectRatioPresetButton(preset)
        }
      }
    }
  }

  private func aspectRatioPresetButton(_ preset: ExportDimensionPreset) -> some View {
    let isSelected = state.exportSettings.dimensionPreset == preset

    return Button {
      var settings = state.exportSettings
      settings.dimensionPreset = preset
      state.updateExportSettings(settings)
    } label: {
      Text(preset.rawValue)
        .font(.system(size: 9, weight: .medium))
        .foregroundColor(isSelected ? .accentColor : .primary)
        .frame(minWidth: 34)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  private var fileSizeReductionHint: some View {
    let size = state.exportSettings.exportSize(from: state.naturalSize)
    let originalPixels = state.naturalSize.width * state.naturalSize.height
    let newPixels = size.width * size.height
    let reduction = originalPixels > 0 ? Int((1.0 - newPixels / originalPixels) * 100) : 0

    return Group {
      if reduction > 0 {
        Text(L10n.VideoEditor.smallerFileSizeHint(reduction))
          .font(.system(size: 9))
          .foregroundColor(.green.opacity(0.8))
      }
    }
  }

  private var exportAspectRatioText: String? {
    state.exportSettings.aspectRatioString(from: state.naturalSize)
  }

  private var customDimensionFields: some View {
    HStack(spacing: 4) {
      TextField("", value: widthBinding, format: .number, prompt: Text(verbatim: "W"))
        .textFieldStyle(.roundedBorder)
        .frame(width: 60)
        .controlSize(.small)
        .accessibilityLabel(L10n.Common.width)

      Button {
        var settings = state.exportSettings
        settings.aspectRatioLocked.toggle()
        state.updateExportSettings(settings)
      } label: {
        Image(systemName: state.exportSettings.aspectRatioLocked ? "lock" : "lock.open")
          .font(.system(size: 9))
          .foregroundColor(state.exportSettings.aspectRatioLocked ? .accentColor : .secondary)
      }
      .buttonStyle(.plain)

      TextField("", value: heightBinding, format: .number, prompt: Text(verbatim: "H"))
        .textFieldStyle(.roundedBorder)
        .frame(width: 60)
        .controlSize(.small)
        .accessibilityLabel(L10n.Common.height)
    }
  }

  // MARK: - Info Section

  private var infoSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(L10n.VideoEditor.gifInfo)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.secondary)

      VStack(alignment: .leading, spacing: 2) {
        if state.naturalSize.width > 0 {
          Text("\(Int(state.naturalSize.width)) × \(Int(state.naturalSize.height))")
            .font(.system(size: 10))
            .foregroundColor(.primary)
        }

        if state.gifFrameCount > 0 {
          Text(L10n.VideoEditor.framesCount(state.gifFrameCount))
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }

        if state.gifDuration > 0 {
          Text(String(format: "%.1fs", state.gifDuration))
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
      }
    }
  }

  // MARK: - File Size Section

  private var fileSizeSection: some View {
    VStack(alignment: .trailing, spacing: 4) {
      Text(L10n.Common.currentSize)
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(.secondary)

      Text(state.fileSizeString)
        .font(.system(size: 14, weight: .semibold))
        .monospacedDigit()

      if state.exportSettings.dimensionPreset != .original,
         state.estimatedFileSize > 0 {
        Text(L10n.Common.estimated)
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)
          .padding(.top, 4)

        Text("~" + ByteCountFormatter.string(fromByteCount: state.estimatedFileSize, countStyle: .file))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.green)
          .monospacedDigit()
      }
    }
  }

  // MARK: - Bindings

  private var dimensionPresetBinding: Binding<ExportDimensionPreset> {
    Binding(
      get: { state.exportSettings.dimensionPreset },
      set: { newValue in
        var settings = state.exportSettings
        settings.dimensionPreset = newValue
        if newValue == .custom {
          settings.customWidth = Int(state.naturalSize.width)
          settings.customHeight = Int(state.naturalSize.height)
        }
        state.updateExportSettings(settings)
      }
    )
  }

  private var widthBinding: Binding<Int> {
    Binding(
      get: { state.exportSettings.customWidth },
      set: { newValue in
        var settings = state.exportSettings
        let oldWidth = settings.customWidth
        settings.customWidth = max(16, newValue)
        if settings.aspectRatioLocked && oldWidth > 0 {
          let ratio = CGFloat(settings.customHeight) / CGFloat(oldWidth)
          settings.customHeight = Int(CGFloat(settings.customWidth) * ratio)
        }
        state.updateExportSettings(settings)
      }
    )
  }

  private var heightBinding: Binding<Int> {
    Binding(
      get: { state.exportSettings.customHeight },
      set: { newValue in
        var settings = state.exportSettings
        let oldHeight = settings.customHeight
        settings.customHeight = max(16, newValue)
        if settings.aspectRatioLocked && oldHeight > 0 {
          let ratio = CGFloat(settings.customWidth) / CGFloat(oldHeight)
          settings.customWidth = Int(CGFloat(settings.customHeight) * ratio)
        }
        state.updateExportSettings(settings)
      }
    )
  }
}
