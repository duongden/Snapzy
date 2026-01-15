//
//  AnnotateWindow.swift
//  ZapShot
//
//  Dark mode annotation window with proper styling
//

import AppKit

/// Custom NSWindow for annotation editing with dark mode appearance
final class AnnotateWindow: NSWindow {

  init(contentRect: NSRect) {
    super.init(
      contentRect: contentRect,
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    configure()
  }

  private func configure() {
    appearance = NSAppearance(named: .darkAqua)
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    backgroundColor = NSColor(white: 0.12, alpha: 1)
    minSize = NSSize(width: 800, height: 600)
    isReleasedWhenClosed = false
    center()
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}
