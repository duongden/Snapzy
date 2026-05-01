//
//  QuickAccessCoreTests.swift
//  SnapzyTests
//
//  Unit tests for Quick Access models and countdown behavior.
//

import AppKit
import XCTest
@testable import Snapzy

@MainActor
final class QuickAccessCoreTests: XCTestCase {

  func testQuickAccessItem_formatsVideoDurationAndOmitsInvalidDurations() {
    let thumbnail = NSImage(size: CGSize(width: 16, height: 16))
    let video = QuickAccessItem(
      url: URL(fileURLWithPath: "/tmp/demo.mov"),
      thumbnail: thumbnail,
      duration: 90.9
    )
    let invalidVideo = QuickAccessItem(
      id: UUID(),
      url: URL(fileURLWithPath: "/tmp/bad.mov"),
      thumbnail: thumbnail,
      capturedAt: Date(),
      itemType: .video,
      duration: -.infinity
    )
    let screenshot = QuickAccessItem(
      url: URL(fileURLWithPath: "/tmp/demo.png"),
      thumbnail: thumbnail
    )

    XCTAssertTrue(video.isVideo)
    XCTAssertEqual(video.formattedDuration, "01:30s")
    XCTAssertNil(invalidVideo.formattedDuration)
    XCTAssertFalse(screenshot.isVideo)
    XCTAssertNil(screenshot.formattedDuration)
  }

  func testQuickAccessProcessingState_identifiesProcessingOnly() {
    XCTAssertFalse(QuickAccessProcessingState.idle.isProcessing)
    XCTAssertTrue(QuickAccessProcessingState.processing(progress: nil).isProcessing)
    XCTAssertTrue(QuickAccessProcessingState.processing(progress: 0.4).isProcessing)
    XCTAssertFalse(QuickAccessProcessingState.complete.isProcessing)
    XCTAssertFalse(QuickAccessProcessingState.failed.isProcessing)
  }

  func testQuickAccessItemEquality_tracksMutablePresentationState() {
    let id = UUID()
    let thumbnail = NSImage(size: CGSize(width: 16, height: 16))
    let capturedAt = Date()
    let thumbnailVersion = UUID()
    let base = QuickAccessItem(
      id: id,
      url: URL(fileURLWithPath: "/tmp/demo.png"),
      thumbnail: thumbnail,
      capturedAt: capturedAt,
      itemType: .screenshot,
      duration: nil,
      thumbnailVersion: thumbnailVersion
    )
    var uploaded = base
    uploaded.cloudURL = URL(string: "https://cdn.example.com/demo.png")

    XCTAssertEqual(base, base)
    XCTAssertNotEqual(base, uploaded)
  }

  func testQuickAccessCountdownTimer_pauseResumePreservesRemainingTime() async throws {
    var didExpire = false
    let expiration = expectation(description: "timer expires after resume")
    let timer = QuickAccessCountdownTimer(duration: 0.08) {
      didExpire = true
      expiration.fulfill()
    }

    timer.start()
    try await Task.sleep(nanoseconds: 30_000_000)
    timer.pause()

    XCTAssertTrue(timer.isPaused)
    XCTAssertFalse(timer.isRunning)

    try await Task.sleep(nanoseconds: 120_000_000)
    XCTAssertFalse(didExpire)

    timer.resume()
    XCTAssertTrue(timer.isRunning)

    await fulfillment(of: [expiration], timeout: 0.5)
    XCTAssertTrue(didExpire)
  }

  func testQuickAccessCountdownTimer_cancelPreventsExpiration() async throws {
    var didExpire = false
    let timer = QuickAccessCountdownTimer(duration: 0.03) {
      didExpire = true
    }

    timer.start()
    timer.cancel()
    try await Task.sleep(nanoseconds: 80_000_000)

    XCTAssertFalse(didExpire)
    XCTAssertFalse(timer.isRunning)
    XCTAssertFalse(timer.isPaused)
  }
}
