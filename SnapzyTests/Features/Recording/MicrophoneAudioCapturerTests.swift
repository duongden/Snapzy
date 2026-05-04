//
//  MicrophoneAudioCapturerTests.swift
//  SnapzyTests
//
//  Tests for MicrophoneAudioCapturer initialization and lifecycle.
//

import AVFoundation
import XCTest
@testable import Snapzy

@MainActor
final class MicrophoneAudioCapturerTests: XCTestCase {

  private var mockDelegate: MockMicrophoneAudioCapturerDelegate!

  override func setUp() {
    super.setUp()
    mockDelegate = MockMicrophoneAudioCapturerDelegate()
  }

  override func tearDown() {
    mockDelegate = nil
    super.tearDown()
  }

  func testMicrophoneAudioCapturerInitialization() {
    let capturer = MicrophoneAudioCapturer()
    XCTAssertNotNil(capturer)
    XCTAssertFalse(capturer.running)
  }

  func testMicrophoneAudioCapturerStartStop() {
    let capturer = MicrophoneAudioCapturer()

    // Start should not crash even without permission
    capturer.start()

    // Wait briefly for session queue to process
    let expectation = self.expectation(description: "Wait for session queue")
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)

    // Stop should not crash
    capturer.stop()

    // Wait for stop to complete
    let stopExpectation = self.expectation(description: "Wait for stop")
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
      stopExpectation.fulfill()
    }
    wait(for: [stopExpectation], timeout: 1.0)

    XCTAssertFalse(capturer.running)
  }

  func testMicrophoneAudioCapturerDelegate() {
    let capturer = MicrophoneAudioCapturer()
    capturer.delegate = mockDelegate

    XCTAssertTrue(capturer.delegate === mockDelegate)
  }

  func testMicrophonePermissionStatusCanBeChecked() {
    // Verify we can query the authorization status without crashing
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    XCTAssertTrue([
      .notDetermined,
      .restricted,
      .denied,
      .authorized
    ].contains(status))
  }
}

// MARK: - Mock Delegate

private class MockMicrophoneAudioCapturerDelegate: MicrophoneAudioCapturerDelegate {
  var receivedSamples: [CMSampleBuffer] = []

  func microphoneCapturer(_ capturer: MicrophoneAudioCapturer, didOutput sampleBuffer: CMSampleBuffer) {
    receivedSamples.append(sampleBuffer)
  }
}
