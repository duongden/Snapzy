//
//  AnnotateExporter.swift
//  ZapShot
//
//  Export functionality for annotated images
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Handles exporting annotated images
@MainActor
final class AnnotateExporter {

  static func saveAs(state: AnnotateState, closeWindow: Bool = true) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png, .jpeg]
    panel.nameFieldStringValue = generateFileName(from: state.sourceURL)
    panel.canCreateDirectories = true

    if panel.runModal() == .OK, let url = panel.url {
      save(state: state, to: url)
      if closeWindow {
        NSApp.keyWindow?.close()
      }
    }
  }

  /// Save annotated image to original file location (overwrite)
  static func saveToOriginal(state: AnnotateState) {
    save(state: state, to: state.sourceURL)
  }

  static func save(state: AnnotateState, to url: URL) {
    guard let image = renderFinalImage(state: state) else { return }

    let format: NSBitmapImageRep.FileType = url.pathExtension.lowercased() == "jpg" ? .jpeg : .png

    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let data = bitmap.representation(using: format, properties: [:])
    else { return }

    try? data.write(to: url)
    NSSound(named: "Pop")?.play()
  }

  static func copyToClipboard(state: AnnotateState) {
    guard let image = renderFinalImage(state: state) else { return }

    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([image])
    NSSound(named: "Pop")?.play()
  }

  static func share(state: AnnotateState, from view: NSView) {
    guard let image = renderFinalImage(state: state) else { return }

    let picker = NSSharingServicePicker(items: [image])
    picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
  }

  // MARK: - Private

  private static func generateFileName(from url: URL) -> String {
    let baseName = url.deletingPathExtension().lastPathComponent
    return "\(baseName)_annotated"
  }

  private static func renderFinalImage(state: AnnotateState) -> NSImage? {
    let imageSize = state.sourceImage.size
    let padding = state.backgroundStyle != .none ? state.padding : 0
    let totalSize = NSSize(
      width: imageSize.width + padding * 2,
      height: imageSize.height + padding * 2
    )

    let image = NSImage(size: totalSize)
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
      image.unlockFocus()
      return nil
    }

    // Draw background
    drawBackground(state: state, in: context, size: totalSize)

    // Draw source image
    let imageRect = NSRect(
      x: padding,
      y: padding,
      width: imageSize.width,
      height: imageSize.height
    )

    if state.cornerRadius > 0 {
      let path = NSBezierPath(roundedRect: imageRect, xRadius: state.cornerRadius, yRadius: state.cornerRadius)
      path.addClip()
    }

    state.sourceImage.draw(in: imageRect)

    // Reset clip
    context.resetClip()

    // Draw annotations
    let renderer = AnnotationRenderer(context: context)
    for annotation in state.annotations {
      // Offset annotations by padding
      var offsetAnnotation = annotation
      offsetAnnotation.bounds = annotation.bounds.offsetBy(dx: padding, dy: padding)
      renderer.draw(offsetAnnotation)
    }

    image.unlockFocus()
    return image
  }

  private static func drawBackground(state: AnnotateState, in context: CGContext, size: NSSize) {
    let rect = CGRect(origin: .zero, size: size)

    switch state.backgroundStyle {
    case .none:
      break

    case .gradient(let preset):
      let colors = preset.colors.map { NSColor($0).cgColor }
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: nil
      )
      if let gradient = gradient {
        context.drawLinearGradient(
          gradient,
          start: .zero,
          end: CGPoint(x: size.width, y: size.height),
          options: []
        )
      }

    case .solidColor(let color):
      context.setFillColor(NSColor(color).cgColor)
      context.fill(rect)

    case .wallpaper(let url), .blurred(let url):
      if let wallpaper = NSImage(contentsOf: url) {
        wallpaper.draw(in: rect)
        if case .blurred = state.backgroundStyle {
          // Apply blur effect would require CIFilter
        }
      }
    }
  }
}
