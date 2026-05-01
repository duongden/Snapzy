//
//  VideoEditorExportSettingsTests.swift
//  SnapzyTests
//
//  Unit tests for video export sizing and zoom segment value models.
//

import CoreGraphics
import XCTest
@testable import Snapzy

final class VideoEditorExportSettingsTests: XCTestCase {

  func testVideoEditorExportLayoutEvenSize_roundsToEvenMinimumDimensions() {
    XCTAssertEqual(
      VideoEditorExportLayout.evenSize(CGSize(width: 101.7, height: 1.1)),
      CGSize(width: 102, height: 2)
    )
    XCTAssertEqual(
      VideoEditorExportLayout.evenSize(CGSize(width: -10, height: 0)),
      CGSize(width: 2, height: 2)
    )
  }

  func testVideoEditorExportLayoutAspectRatioCanvasSize_usesNaturalShortEdge() {
    XCTAssertEqual(
      VideoEditorExportLayout.aspectRatioCanvasSize(
        for: CGSize(width: 1920, height: 1080),
        aspectRatio: CGSize(width: 1, height: 1)
      ),
      CGSize(width: 1080, height: 1080)
    )
    XCTAssertEqual(
      VideoEditorExportLayout.aspectRatioCanvasSize(
        for: CGSize(width: 1080, height: 1920),
        aspectRatio: CGSize(width: 16, height: 9)
      ),
      CGSize(width: 1920, height: 1080)
    )
    XCTAssertEqual(
      VideoEditorExportLayout.aspectRatioCanvasSize(
        for: CGSize(width: 0, height: 1080),
        aspectRatio: CGSize(width: 16, height: 9)
      ),
      .zero
    )
  }

  func testVideoEditorExportLayoutAspectFitRect_centersContent() {
    let rect = VideoEditorExportLayout.aspectFitRect(
      sourceSize: CGSize(width: 1920, height: 1080),
      in: CGSize(width: 1080, height: 1080)
    )

    XCTAssertEqual(rect.origin.x, 0, accuracy: 0.0001)
    XCTAssertEqual(rect.origin.y, 236.25, accuracy: 0.0001)
    XCTAssertEqual(rect.width, 1080, accuracy: 0.0001)
    XCTAssertEqual(rect.height, 607.5, accuracy: 0.0001)
  }

  func testExportSettingsExportSize_handlesPercentAspectAndCustomPresets() {
    let naturalSize = CGSize(width: 1920, height: 1080)

    var settings = ExportSettings()
    XCTAssertEqual(settings.exportSize(from: naturalSize), naturalSize)

    settings.dimensionPreset = .percent50
    XCTAssertEqual(settings.exportSize(from: naturalSize), CGSize(width: 960, height: 540))

    settings.dimensionPreset = .ratio1x1
    XCTAssertEqual(settings.exportSize(from: naturalSize), CGSize(width: 1080, height: 1080))

    settings.dimensionPreset = .custom
    settings.customWidth = 1001
    settings.customHeight = 563
    XCTAssertEqual(settings.exportSize(from: naturalSize), CGSize(width: 1000, height: 562))
  }

  func testExportSettingsAspectRatioStringAndContentRect() {
    var settings = ExportSettings()
    settings.dimensionPreset = .ratio1x1

    XCTAssertEqual(settings.aspectRatioString(from: CGSize(width: 1920, height: 1080)), "1:1")

    let contentRect = settings.videoContentRect(from: CGSize(width: 1920, height: 1080))
    XCTAssertEqual(contentRect.origin.y, 236.25, accuracy: 0.0001)
    XCTAssertEqual(contentRect.width, 1080, accuracy: 0.0001)
    XCTAssertEqual(contentRect.height, 607.5, accuracy: 0.0001)
  }

  func testExportSettingsAudioModes() {
    var settings = ExportSettings()
    settings.audioMode = .keep
    settings.audioVolume = 0.25
    XCTAssertTrue(settings.shouldIncludeAudio)
    XCTAssertEqual(settings.effectiveVolume, 1)

    settings.audioMode = .mute
    XCTAssertFalse(settings.shouldIncludeAudio)
    XCTAssertEqual(settings.effectiveVolume, 0)

    settings.audioMode = .custom
    XCTAssertTrue(settings.shouldIncludeAudio)
    XCTAssertEqual(settings.effectiveVolume, 0.25)
  }

  func testZoomSegmentClampsAndFormatsValues() {
    let segment = ZoomSegment(
      startTime: -5,
      duration: 100,
      zoomLevel: 9,
      zoomCenter: CGPoint(x: -1, y: 2),
      zoomType: .auto,
      followSpeed: 99,
      focusMargin: -5
    )

    XCTAssertEqual(segment.startTime, 0)
    XCTAssertEqual(segment.duration, ZoomSegment.maxDuration)
    XCTAssertEqual(segment.zoomLevel, ZoomSegment.maxZoomLevel)
    XCTAssertEqual(segment.zoomCenter, .init(x: 0, y: 1))
    XCTAssertEqual(segment.followSpeed, AutoFocusSettings.followSpeedRange.upperBound)
    XCTAssertEqual(segment.focusMargin, AutoFocusSettings.focusMarginRange.lowerBound)
    XCTAssertEqual(segment.formattedZoomLevel, "4x")
    XCTAssertEqual(segment.formattedDuration, "30s")
    XCTAssertTrue(segment.isAutoMode)
  }

  func testZoomSegmentCenteredAndClampedToVideoDuration() {
    let centered = ZoomSegment.centered(at: 1, duration: 4, zoomLevel: 1.5)
    XCTAssertEqual(centered.startTime, 0)
    XCTAssertEqual(centered.formattedZoomLevel, "1.5x")
    XCTAssertEqual(centered.formattedDuration, "4s")

    let clamped = ZoomSegment(startTime: 9, duration: 5).clamped(to: 10)
    XCTAssertEqual(clamped.startTime, 9)
    XCTAssertEqual(clamped.duration, 1)
  }
}
