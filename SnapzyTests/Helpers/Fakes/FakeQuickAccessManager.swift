//
//  FakeQuickAccessManager.swift
//  SnapzyTests
//
//  Records QuickAccessManaging calls for assertion.
//

import Foundation
@testable import Snapzy

@MainActor
final class FakeQuickAccessManager: QuickAccessManaging {
  private(set) var addedScreenshots: [URL] = []
  private(set) var addedVideos: [URL] = []

  func addScreenshot(url: URL) async {
    addedScreenshots.append(url)
  }

  func addVideo(url: URL) async {
    addedVideos.append(url)
  }
}
