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
    let clock = ManualQuickAccessCountdownTimerClock()
    let timer = QuickAccessCountdownTimer(duration: 0.08, clock: clock) {
      didExpire = true
      expiration.fulfill()
    }

    timer.start()
    await clock.waitForSleepCallCount(1)
    clock.advance(by: 0.03)
    timer.pause()

    XCTAssertTrue(timer.isPaused)
    XCTAssertFalse(timer.isRunning)

    clock.advance(by: 0.12)
    await Task.yield()
    XCTAssertFalse(didExpire)

    timer.resume()
    XCTAssertTrue(timer.isRunning)

    await clock.waitForSleepCallCount(2)
    clock.advance(by: 0.05)

    await fulfillment(of: [expiration], timeout: 1.0)
    XCTAssertTrue(didExpire)
  }

  func testQuickAccessCountdownTimer_cancelPreventsExpiration() async throws {
    var didExpire = false
    let clock = ManualQuickAccessCountdownTimerClock()
    let timer = QuickAccessCountdownTimer(duration: 0.03, clock: clock) {
      didExpire = true
    }

    timer.start()
    await clock.waitForSleepCallCount(1)
    timer.cancel()
    clock.advance(by: 0.08)
    await Task.yield()

    XCTAssertFalse(didExpire)
    XCTAssertFalse(timer.isRunning)
    XCTAssertFalse(timer.isPaused)
  }
}

@MainActor
private final class ManualQuickAccessCountdownTimerClock: QuickAccessCountdownTimerClock {
  private struct SleepRequest {
    let wakeTime: TimeInterval
    let continuation: CheckedContinuation<Void, Never>
  }

  private(set) var now: TimeInterval = 0
  private var sleepRequests: [SleepRequest] = []
  private var sleepCallCount = 0
  private var sleepCallWaiters: [(expectedCount: Int, continuation: CheckedContinuation<Void, Never>)] = []

  func sleep(for duration: TimeInterval) async {
    await withCheckedContinuation { continuation in
      sleepCallCount += 1
      resumeSatisfiedSleepCallWaiters()

      let wakeTime = now + max(0, duration)
      guard wakeTime > now else {
        continuation.resume()
        return
      }

      sleepRequests.append(SleepRequest(wakeTime: wakeTime, continuation: continuation))
    }
  }

  func advance(by duration: TimeInterval) {
    now += duration

    var readyContinuations: [CheckedContinuation<Void, Never>] = []
    sleepRequests.removeAll { request in
      guard request.wakeTime <= now else { return false }
      readyContinuations.append(request.continuation)
      return true
    }

    readyContinuations.forEach { $0.resume() }
  }

  func waitForSleepCallCount(_ expectedCount: Int) async {
    guard sleepCallCount < expectedCount else { return }

    await withCheckedContinuation { continuation in
      sleepCallWaiters.append((expectedCount, continuation))
    }
  }

  private func resumeSatisfiedSleepCallWaiters() {
    var readyContinuations: [CheckedContinuation<Void, Never>] = []
    sleepCallWaiters.removeAll { waiter in
      guard sleepCallCount >= waiter.expectedCount else { return false }
      readyContinuations.append(waiter.continuation)
      return true
    }

    readyContinuations.forEach { $0.resume() }
  }
}
