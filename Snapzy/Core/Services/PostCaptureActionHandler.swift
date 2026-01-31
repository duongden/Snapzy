//
//  PostCaptureActionHandler.swift
//  Snapzy
//
//  Executes post-capture actions based on user preferences
//

import AppKit
import Foundation

/// Handles execution of post-capture actions based on user preferences
@MainActor
final class PostCaptureActionHandler {

  static let shared = PostCaptureActionHandler()

  private let preferencesManager = PreferencesManager.shared
  private let quickAccessManager = QuickAccessManager.shared

  private init() {}

  // MARK: - Public API

  /// Execute all enabled post-capture actions for a screenshot
  func handleScreenshotCapture(url: URL) async {
    await executeActions(for: .screenshot, url: url)
  }

  /// Execute all enabled post-capture actions for a video recording
  func handleVideoCapture(url: URL) async {
    await executeActions(for: .recording, url: url)
  }

  // MARK: - Private

  private func executeActions(for captureType: CaptureType, url: URL) async {
    // Save action is handled by the capture managers themselves (file already saved)
    // We just need to execute the other enabled actions

    // Show Quick Access Overlay
    if preferencesManager.isActionEnabled(.showQuickAccess, for: captureType) {
      switch captureType {
      case .screenshot:
        await quickAccessManager.addScreenshot(url: url)
      case .recording:
        await quickAccessManager.addVideo(url: url)
      }
    }

    // Copy file to clipboard
    if preferencesManager.isActionEnabled(.copyFile, for: captureType) {
      copyToClipboard(url: url, isVideo: captureType == .recording)
    }
  }

  /// Copy file to clipboard (image data for screenshots, file URL for videos)
  private func copyToClipboard(url: URL, isVideo: Bool) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    if isVideo {
      // For videos, copy the file URL
      pasteboard.writeObjects([url as NSURL])
    } else {
      // For images, copy the actual image data
      if let image = NSImage(contentsOf: url) {
        pasteboard.writeObjects([image])
      }
    }

    // Play feedback sound
    NSSound(named: "Pop")?.play()
  }
}
