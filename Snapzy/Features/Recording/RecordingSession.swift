//
//  RecordingSession.swift
//  Snapzy
//
//  Thread-safe session class for managing AVAssetWriter during screen recording.
//  Separated from ScreenRecordingManager to ensure complete isolation from @MainActor.
//

import AVFoundation
import CoreMedia
import Foundation
import ScreenCaptureKit

/// A thread-safe class that holds the AVAssetWriter components.
/// This allows safe access from any thread without crossing @MainActor boundaries.
/// Implements lazy start: session begins when first sample buffer arrives to sync timestamps.
final class RecordingSession: @unchecked Sendable {
  struct VideoWriteStats {
    let receivedFrames: Int
    let appendedFrames: Int
    let droppedFramesDueToBackpressure: Int
    let failedAppendFrames: Int
  }

  private let lock = NSLock()

  private var _assetWriter: AVAssetWriter?
  private var _videoInput: AVAssetWriterInput?
  private var _pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
  private var _audioInput: AVAssetWriterInput?
  private var _microphoneInput: AVAssetWriterInput?
  private var _sessionStarted = false
  private var _isCapturing = false
  private var _firstTimestamp: CMTime?  // Track first video timestamp for timeline alignment
  private var _onFirstVideoFrame: (() -> Void)?
  private var _videoFramesReceived = 0
  private var _videoFramesAppended = 0
  private var _videoFramesDroppedBackpressure = 0
  private var _videoFramesFailedAppend = 0
  private var _expectedVideoWidth: Int?
  private var _expectedVideoHeight: Int?
  private var _didLogMissingPixelBuffer = false
  private var _didLogFrameDimensionMismatch = false
  private var _didLogVideoAppendFailure = false
  private var _didLogAudioAppendFailure = false
  private var _didLogMicrophoneAppendFailure = false

  init() {}
  
  var assetWriter: AVAssetWriter? {
    get { lock.withLock { _assetWriter } }
    set { lock.withLock { _assetWriter = newValue } }
  }
  
  var videoInput: AVAssetWriterInput? {
    get { lock.withLock { _videoInput } }
    set { lock.withLock { _videoInput = newValue } }
  }

  var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor? {
    get { lock.withLock { _pixelBufferAdaptor } }
    set { lock.withLock { _pixelBufferAdaptor = newValue } }
  }

  var audioInput: AVAssetWriterInput? {
    get { lock.withLock { _audioInput } }
    set { lock.withLock { _audioInput = newValue } }
  }

  var microphoneInput: AVAssetWriterInput? {
    get { lock.withLock { _microphoneInput } }
    set { lock.withLock { _microphoneInput = newValue } }
  }
  
  var sessionStarted: Bool {
    get { lock.withLock { _sessionStarted } }
    set { lock.withLock { _sessionStarted = newValue } }
  }
  
  var isCapturing: Bool {
    get { lock.withLock { _isCapturing } }
    set { lock.withLock { _isCapturing = newValue } }
  }

  func setOnFirstVideoFrame(_ callback: (() -> Void)?) {
    lock.withLock {
      _onFirstVideoFrame = callback
    }
  }

  func configureExpectedVideoDimensions(width: Int, height: Int) {
    lock.withLock {
      _expectedVideoWidth = width
      _expectedVideoHeight = height
      _didLogFrameDimensionMismatch = false
    }
  }
  
  /// Thread-safe check if ready to write frames
  func canWriteFrames() -> Bool {
    lock.withLock {
      _isCapturing && _assetWriter?.status == .writing
    }
  }

  func videoWriteStats() -> VideoWriteStats {
    lock.withLock {
      VideoWriteStats(
        receivedFrames: _videoFramesReceived,
        appendedFrames: _videoFramesAppended,
        droppedFramesDueToBackpressure: _videoFramesDroppedBackpressure,
        failedAppendFrames: _videoFramesFailedAppend
      )
    }
  }

  /// Thread-safe video frame write with lazy session start
  /// Uses pixel buffer adaptor for BGRA format from ScreenCaptureKit
  func appendVideoSample(_ sampleBuffer: CMSampleBuffer) {
    // Check if this is a valid frame from ScreenCaptureKit
    // SCStream sends status updates as sample buffers without image data
    guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
          let statusRawValue = attachments.first?[.status] as? Int,
          let status = SCFrameStatus(rawValue: statusRawValue),
          status == .complete else {
      // Not a complete frame - skip silently (these are status updates)
      return
    }

    // Get pixel buffer from sample buffer
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      let shouldLog = lock.withLock {
        if _didLogMissingPixelBuffer { return false }
        _didLogMissingPixelBuffer = true
        return true
      }
      if shouldLog {
        DiagnosticLogger.shared.log(
          .warning,
          .recording,
          "Complete recording frame missing pixel buffer"
        )
      }
      return
    }

    let pixelWidth = CVPixelBufferGetWidth(pixelBuffer)
    let pixelHeight = CVPixelBufferGetHeight(pixelBuffer)
    let expectedDimensions = lock.withLock { (_expectedVideoWidth, _expectedVideoHeight, _didLogFrameDimensionMismatch) }
    if let expectedWidth = expectedDimensions.0,
       let expectedHeight = expectedDimensions.1,
       (pixelWidth != expectedWidth || pixelHeight != expectedHeight),
       !expectedDimensions.2 {
      lock.withLock { _didLogFrameDimensionMismatch = true }
      DiagnosticLogger.shared.log(.warning, .recording, "Recording frame dimension mismatch", context: [
        "expected": "\(expectedWidth)x\(expectedHeight)",
        "actual": "\(pixelWidth)x\(pixelHeight)",
      ])
    }

    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    guard timestamp.isValid else { return }

    let (writer, videoInput, adaptor, shouldStartSession, onFirstVideoFrame): (
      AVAssetWriter?, AVAssetWriterInput?, AVAssetWriterInputPixelBufferAdaptor?, Bool, (() -> Void)?
    ) = lock.withLock {
      guard _isCapturing, let writer = _assetWriter, writer.status == .writing else {
        return (nil, nil, nil, false, nil)
      }

      var needsSessionStart = false
      if !_sessionStarted {
        _sessionStarted = true
        _firstTimestamp = timestamp
        needsSessionStart = true
      }

      return (writer, _videoInput, _pixelBufferAdaptor, needsSessionStart, _onFirstVideoFrame)
    }

    guard let writer = writer,
          let videoInput = videoInput,
          let adaptor = adaptor else { return }

    // Lazy start session at first video timestamp.
    // This avoids rewriting every audio sample (large per-buffer allocations).
    if shouldStartSession {
      writer.startSession(atSourceTime: timestamp)
      DiagnosticLogger.shared.log(.debug, .recording, "Recording writer session started", context: [
        "firstFrameTimestampSeconds": String(format: "%.3f", timestamp.seconds)
      ])
      onFirstVideoFrame?()
    }

    lock.withLock { _videoFramesReceived += 1 }

    // Append pixel buffer with calculated presentation time
    if videoInput.isReadyForMoreMediaData {
      let success = adaptor.append(pixelBuffer, withPresentationTime: timestamp)
      if !success {
        let shouldLog = lock.withLock {
          _videoFramesFailedAppend += 1
          if _didLogVideoAppendFailure { return false }
          _didLogVideoAppendFailure = true
          return true
        }
        if shouldLog {
          logWriterIssue(
            "Failed to append recording video frame",
            writer: writer,
            context: ["timestampSeconds": String(format: "%.3f", timestamp.seconds)]
          )
        }
      } else {
        lock.withLock { _videoFramesAppended += 1 }
      }
    } else {
      lock.withLock { _videoFramesDroppedBackpressure += 1 }
    }
  }

  /// Thread-safe audio sample write
  func appendAudioSample(_ sampleBuffer: CMSampleBuffer) {
    // Get audio timestamp
    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    guard timestamp.isValid else { return }

    let (writer, audioInput, firstTs): (AVAssetWriter?, AVAssetWriterInput?, CMTime?) = lock.withLock {
      guard _isCapturing, let writer = _assetWriter, writer.status == .writing else {
        return (nil, nil, nil)
      }
      return (writer, _audioInput, _firstTimestamp)
    }

    guard let writer = writer, writer.status == .writing else { return }
    guard let audioInput = audioInput else { return }
    // Skip audio until video has started the session
    guard let firstTs = firstTs else { return }

    // Skip audio samples that arrived before video start
    guard CMTimeCompare(timestamp, firstTs) >= 0 else { return }

    // Session starts at first video timestamp, so original timestamps are valid.
    if audioInput.isReadyForMoreMediaData {
      let success = audioInput.append(sampleBuffer)
      if !success {
        let shouldLog = lock.withLock {
          if _didLogAudioAppendFailure { return false }
          _didLogAudioAppendFailure = true
          return true
        }
        if shouldLog {
          logWriterIssue(
            "Failed to append recording system audio sample",
            writer: writer,
            context: ["timestampSeconds": String(format: "%.3f", timestamp.seconds)]
          )
        }
      }
    }
  }

  /// Thread-safe microphone sample write
  func appendMicrophoneSample(_ sampleBuffer: CMSampleBuffer) {
    // Get mic timestamp
    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    guard timestamp.isValid else { return }

    let (writer, microphoneInput, firstTs): (AVAssetWriter?, AVAssetWriterInput?, CMTime?) = lock.withLock {
      guard _isCapturing, let writer = _assetWriter, writer.status == .writing else {
        return (nil, nil, nil)
      }
      return (writer, _microphoneInput, _firstTimestamp)
    }

    guard let writer = writer, writer.status == .writing else { return }
    guard let microphoneInput = microphoneInput else { return }
    // Skip mic audio until video has started the session
    guard let firstTs = firstTs else { return }

    // Skip mic samples that arrived before video start
    guard CMTimeCompare(timestamp, firstTs) >= 0 else { return }

    // Session starts at first video timestamp, so original timestamps are valid.
    if microphoneInput.isReadyForMoreMediaData {
      let success = microphoneInput.append(sampleBuffer)
      if !success {
        let shouldLog = lock.withLock {
          if _didLogMicrophoneAppendFailure { return false }
          _didLogMicrophoneAppendFailure = true
          return true
        }
        if shouldLog {
          logWriterIssue(
            "Failed to append recording microphone sample",
            writer: writer,
            context: ["timestampSeconds": String(format: "%.3f", timestamp.seconds)]
          )
        }
      }
    }
  }
  
  /// Mark inputs as finished
  func finishInputs() {
    lock.withLock {
      _videoInput?.markAsFinished()
      _audioInput?.markAsFinished()
      _microphoneInput?.markAsFinished()
    }
  }
  
  /// Cancel writing
  func cancelWriting() {
    lock.withLock {
      _assetWriter?.cancelWriting()
    }
  }
  
  /// Finish writing asynchronously
  func finishWriting() async {
    let writer = lock.withLock { _assetWriter }
    guard let writer = writer else {
      DiagnosticLogger.shared.log(.warning, .recording, "Recording finish requested without asset writer")
      return
    }

    DiagnosticLogger.shared.log(.debug, .recording, "Finishing recording writer", context: [
      "writerStatus": writerStatusLabel(writer.status)
    ])

    if writer.status == .writing {
      await writer.finishWriting()
      if let error = writer.error {
        logWriterIssue("Recording writer finished with error", writer: writer)
      } else {
        DiagnosticLogger.shared.log(.debug, .recording, "Recording writer finished", context: [
          "writerStatus": writerStatusLabel(writer.status)
        ])
      }
    } else {
      logWriterIssue("Recording writer not in writing state during finish", writer: writer)
    }
  }
  
  /// Reset all state
  func reset() {
    lock.withLock {
      _assetWriter = nil
      _videoInput = nil
      _pixelBufferAdaptor = nil
      _audioInput = nil
      _microphoneInput = nil
      _sessionStarted = false
      _isCapturing = false
      _firstTimestamp = nil
      _onFirstVideoFrame = nil
      _videoFramesReceived = 0
      _videoFramesAppended = 0
      _videoFramesDroppedBackpressure = 0
      _videoFramesFailedAppend = 0
      _expectedVideoWidth = nil
      _expectedVideoHeight = nil
      _didLogMissingPixelBuffer = false
      _didLogFrameDimensionMismatch = false
      _didLogVideoAppendFailure = false
      _didLogAudioAppendFailure = false
      _didLogMicrophoneAppendFailure = false
    }
  }

  private func logWriterIssue(
    _ message: String,
    writer: AVAssetWriter?,
    context: [String: String] = [:]
  ) {
    var context = context
    if let writer {
      context["writerStatus"] = writerStatusLabel(writer.status)
    }

    if let error = writer?.error {
      DiagnosticLogger.shared.logError(.recording, error, message, context: context)
    } else {
      DiagnosticLogger.shared.log(.error, .recording, message, context: context)
    }
  }

  private func writerStatusLabel(_ status: AVAssetWriter.Status) -> String {
    switch status {
    case .unknown: return "unknown"
    case .writing: return "writing"
    case .completed: return "completed"
    case .failed: return "failed"
    case .cancelled: return "cancelled"
    @unknown default: return "unknown"
    }
  }
}
