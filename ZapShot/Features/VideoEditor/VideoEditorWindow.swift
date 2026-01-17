//
//  VideoEditorWindow.swift
//  ZapShot
//
//  Dark mode video editor window configuration
//

import AppKit

/// Custom NSWindow for video editing with dark mode appearance
final class VideoEditorWindow: NSWindow {

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
    minSize = NSSize(width: 400, height: 300)
    isReleasedWhenClosed = false
    center()
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}
