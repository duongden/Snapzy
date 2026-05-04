//
//  MicrophoneAudioCapturer.swift
//  Snapzy
//
//  Independent microphone capture using AVCaptureSession.
//  Works on macOS 13+ — not gated to macOS 15 like ScreenCaptureKit's built-in mic output.
//

import AVFoundation
import CoreMedia
import Foundation

/// Delegate for receiving captured microphone samples.
protocol MicrophoneAudioCapturerDelegate: AnyObject {
  /// Called on the capturer's internal queue for each captured sample buffer.
  func microphoneCapturer(_ capturer: MicrophoneAudioCapturer, didOutput sampleBuffer: CMSampleBuffer)
}

/// Captures microphone audio via AVCaptureSession, delivering CMSampleBuffer objects
/// that can be written directly to an AVAssetWriter audio input.
final class MicrophoneAudioCapturer: NSObject {

  weak var delegate: MicrophoneAudioCapturerDelegate?

  private var captureSession: AVCaptureSession?
  private let sessionQueue = DispatchQueue(
    label: "com.trongduong.snapzy.microphone.session",
    qos: .userInteractive
  )
  private let dataOutputQueue = DispatchQueue(
    label: "com.trongduong.snapzy.microphone.data",
    qos: .userInteractive
  )

  private var isRunning = false

  /// Whether the capturer is currently running.
  var running: Bool {
    sessionQueue.sync { isRunning }
  }

  // MARK: - Lifecycle

  /// Start capturing from the default microphone device.
  /// Call from any queue; session setup happens on an internal queue.
  func start() {
    sessionQueue.async { [weak self] in
      guard let self, !self.isRunning else { return }
      self.isRunning = true
      self.setupAndStartSession()
    }
  }

  /// Stop capturing.
  func stop() {
    sessionQueue.async { [weak self] in
      guard let self, self.isRunning else { return }
      self.isRunning = false
      self.captureSession?.stopRunning()
      self.captureSession = nil
    }
  }

  // MARK: - Private

  private func setupAndStartSession() {
    let session = AVCaptureSession()
    captureSession = session

    // Find the default audio capture device.
    guard let device = AVCaptureDevice.default(for: .audio) else {
      DiagnosticLogger.shared.log(.warning, .recording, "MicrophoneAudioCapturer: no default audio device found")
      isRunning = false
      captureSession = nil
      return
    }

    do {
      let input = try AVCaptureDeviceInput(device: device)
      guard session.canAddInput(input) else {
        DiagnosticLogger.shared.log(.warning, .recording, "MicrophoneAudioCapturer: cannot add device input")
        isRunning = false
        captureSession = nil
        return
      }
      session.addInput(input)
    } catch {
      DiagnosticLogger.shared.logError(.recording, error, "MicrophoneAudioCapturer: failed to create device input")
      isRunning = false
      captureSession = nil
      return
    }

    let output = AVCaptureAudioDataOutput()
    output.setSampleBufferDelegate(self, queue: dataOutputQueue)
    guard session.canAddOutput(output) else {
      DiagnosticLogger.shared.log(.warning, .recording, "MicrophoneAudioCapturer: cannot add data output")
      isRunning = false
      captureSession = nil
      return
    }
    session.addOutput(output)

    session.startRunning()
    DiagnosticLogger.shared.log(.info, .recording, "MicrophoneAudioCapturer: session started", context: [
      "device": device.localizedName
    ])
  }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

extension MicrophoneAudioCapturer: AVCaptureAudioDataOutputSampleBufferDelegate {

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard sampleBuffer.isValid else { return }
    delegate?.microphoneCapturer(self, didOutput: sampleBuffer)
  }
}
