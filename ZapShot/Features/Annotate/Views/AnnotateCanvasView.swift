//
//  AnnotateCanvasView.swift
//  ZapShot
//
//  Canvas view displaying the image with annotations
//

import SwiftUI

/// Canvas view for displaying and annotating the image
struct AnnotateCanvasView: View {
  @ObservedObject var state: AnnotateState

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        Color(white: 0.08)

        // Centered, scaled canvas
        canvasContent(in: geometry.size)
          .frame(width: geometry.size.width, height: geometry.size.height)
      }
    }
  }

  private func canvasContent(in containerSize: CGSize) -> some View {
    // Calculate scale to fit image in container
    let scale = calculateFitScale(containerSize: containerSize)
    let displayWidth = displayImageWidth * scale
    let displayHeight = displayImageHeight * scale

    return ZStack {
      // Background layer (gradient, wallpaper, etc.)
      backgroundLayer(scale: scale)

      // Image with effects
      imageLayer(scale: scale)

      // Drawing canvas overlay - must match image position exactly
      CanvasDrawingView(state: state)
        .frame(width: displayWidth, height: displayHeight)
    }
    .scaleEffect(state.zoomLevel)
  }

  private func calculateFitScale(containerSize: CGSize) -> CGFloat {
    let padding: CGFloat = 40 // Margin around image
    let availableWidth = containerSize.width - padding * 2
    let availableHeight = containerSize.height - padding * 2

    let scaleX = availableWidth / displayImageWidth
    let scaleY = availableHeight / displayImageHeight

    return min(scaleX, scaleY, 1.0) // Don't scale up, only down
  }

  // MARK: - Display Size (scaled for display, not raw pixels)

  private var displayImageWidth: CGFloat {
    // NSImage.size returns points, not pixels - this is correct for display
    state.sourceImage.size.width
  }

  private var displayImageHeight: CGFloat {
    state.sourceImage.size.height
  }

  // MARK: - Background Layer

  @ViewBuilder
  private func backgroundLayer(scale: CGFloat) -> some View {
    let bgWidth = (displayImageWidth + state.padding * 2) * scale
    let bgHeight = (displayImageHeight + state.padding * 2) * scale

    switch state.backgroundStyle {
    case .none:
      EmptyView()

    case .gradient(let preset):
      RoundedRectangle(cornerRadius: state.cornerRadius * scale)
        .fill(LinearGradient(
          colors: preset.colors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ))
        .frame(width: bgWidth, height: bgHeight)
        .shadow(
          color: .black.opacity(state.shadowIntensity),
          radius: 20 * scale,
          x: 0,
          y: 10 * scale
        )

    case .wallpaper(let url):
      if let nsImage = NSImage(contentsOf: url) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: bgWidth, height: bgHeight)
          .clipped()
          .cornerRadius(state.cornerRadius * scale)
      }

    case .blurred(let url):
      if let nsImage = NSImage(contentsOf: url) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: bgWidth, height: bgHeight)
          .blur(radius: 20)
          .clipped()
          .cornerRadius(state.cornerRadius * scale)
      }

    case .solidColor(let color):
      RoundedRectangle(cornerRadius: state.cornerRadius * scale)
        .fill(color)
        .frame(width: bgWidth, height: bgHeight)
        .shadow(
          color: .black.opacity(state.shadowIntensity),
          radius: 20 * scale,
          x: 0,
          y: 10 * scale
        )
    }
  }

  // MARK: - Image Layer

  private func imageLayer(scale: CGFloat) -> some View {
    let imgWidth = displayImageWidth * scale
    let imgHeight = displayImageHeight * scale

    return Image(nsImage: state.sourceImage)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: imgWidth, height: imgHeight)
      .cornerRadius(state.cornerRadius * scale)
      .shadow(
        color: .black.opacity(state.backgroundStyle != .none ? state.shadowIntensity : 0),
        radius: 15 * scale,
        x: 0,
        y: 8 * scale
      )
  }
}
