//
//  VideoEditorWindowController.swift
//  ZapShot
//
//  Controller managing video editor window lifecycle
//

import AppKit
import SwiftUI

/// Manages video editor window lifecycle
@MainActor
final class VideoEditorWindowController: NSWindowController {

  private let item: QuickAccessItem

  init(item: QuickAccessItem) {
    self.item = item

    let screen = NSScreen.main ?? NSScreen.screens.first!
    let windowWidth: CGFloat = 500
    let windowHeight: CGFloat = 350

    let origin = NSPoint(
      x: (screen.frame.width - windowWidth) / 2,
      y: (screen.frame.height - windowHeight) / 2
    )

    let window = VideoEditorWindow(
      contentRect: NSRect(origin: origin, size: NSSize(width: windowWidth, height: windowHeight))
    )

    super.init(window: window)

    setupContent()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupContent() {
    let placeholderView = VideoEditorPlaceholderView(videoName: item.url.lastPathComponent)
    window?.contentView = NSHostingView(rootView: placeholderView)
  }

  func showWindow() {
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
