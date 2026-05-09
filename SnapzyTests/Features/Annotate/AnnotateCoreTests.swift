//
//  AnnotateCoreTests.swift
//  SnapzyTests
//
//  Unit tests for annotation creation and geometry helpers.
//

import CoreGraphics
import SwiftUI
import XCTest
@testable import Snapzy

final class AnnotateCoreTests: XCTestCase {
  // Keep AnnotateState alive for the test process; XCTest scope cleanup can
  // crash while deinitializing this MainActor app-level ObservableObject.
  @MainActor private static var retainedAnnotateStates: [AnnotateState] = []

  @MainActor
  private func makeAnnotateState() -> AnnotateState {
    let state = AnnotateState()
    Self.retainedAnnotateStates.append(state)
    return state
  }

  func testAnnotateCanvasDefaultsUseNoCornerRadius() {
    XCTAssertEqual(AnnotateCanvasDefaults.cornerRadius, 0)
    XCTAssertEqual(AnnotationCanvasEffects().cornerRadius, 0)
  }

  @MainActor
  func testAnnotateState_undoAfterNewTextCreationRemovesTextAnnotation() {
    let state = makeAnnotateState()

    state.saveState()
    let annotation = AnnotationItem(
      type: .text("Hello"),
      bounds: CGRect(x: 20, y: 20, width: 120, height: 32),
      properties: AnnotationProperties(fontSize: 18)
    )
    state.annotations.append(annotation)
    state.selectedAnnotationId = annotation.id
    state.beginTextEditing(id: annotation.id, recordsUndo: false)
    state.commitTextEditing()

    state.undo()

    XCTAssertTrue(state.annotations.isEmpty)
  }

  @MainActor
  func testAnnotateState_undoRedoExistingTextEditRestoresText() throws {
    let state = makeAnnotateState()
    let annotation = AnnotationItem(
      type: .text("Original"),
      bounds: CGRect(x: 20, y: 20, width: 140, height: 32),
      properties: AnnotationProperties(fontSize: 18)
    )
    state.annotations = [annotation]
    state.selectedAnnotationId = annotation.id

    state.beginTextEditing(id: annotation.id)
    state.updateAnnotationText(id: annotation.id, text: "Changed")
    state.commitTextEditing()
    state.undo()

    let undone = try XCTUnwrap(state.annotations.first)
    guard case .text(let undoneText) = undone.type else {
      return XCTFail("Expected text annotation after undo")
    }
    XCTAssertEqual(undoneText, "Original")

    state.redo()

    let redone = try XCTUnwrap(state.annotations.first)
    guard case .text(let redoneText) = redone.type else {
      return XCTFail("Expected text annotation after redo")
    }
    XCTAssertEqual(redoneText, "Changed")
  }

  @MainActor
  func testAnnotateState_undoRedoTextFontSizeRestoresPropertiesAndBounds() throws {
    let state = makeAnnotateState()
    let originalBounds = CGRect(x: 20, y: 20, width: 180, height: 32)
    let annotation = AnnotationItem(
      type: .text("Resizable text"),
      bounds: originalBounds,
      properties: AnnotationProperties(fontSize: 18)
    )
    state.annotations = [annotation]
    state.selectedAnnotationId = annotation.id

    state.updateAnnotationProperties(id: annotation.id, fontSize: 36, recordsUndo: true)

    let resized = try XCTUnwrap(state.annotations.first)
    XCTAssertEqual(resized.properties.fontSize, 36)
    XCTAssertNotEqual(resized.bounds, originalBounds)

    state.undo()

    let undone = try XCTUnwrap(state.annotations.first)
    XCTAssertEqual(undone.properties.fontSize, 18)
    XCTAssertEqual(undone.bounds, originalBounds)

    state.redo()

    let redone = try XCTUnwrap(state.annotations.first)
    XCTAssertEqual(redone.properties.fontSize, 36)
  }

  func testAnnotationFactory_createsCounterCenteredAtStart() {
    let annotation = AnnotationFactory.createAnnotation(
      tool: .counter,
      from: CGPoint(x: 50, y: 60),
      to: CGPoint(x: 50, y: 60),
      path: [],
      context: makeContext(counterValue: 5)
    )

    guard case .counter(5) = annotation?.type else {
      return XCTFail("Expected counter value 5, got \(String(describing: annotation?.type))")
    }
    XCTAssertEqual(annotation?.bounds, CGRect(x: 38, y: 48, width: 24, height: 24))
  }

  func testAnnotationFactory_rejectsNonDrawingToolsAndSinglePointPaths() {
    let context = makeContext()
    let start = CGPoint(x: 10, y: 20)

    XCTAssertNil(AnnotationFactory.createAnnotation(tool: .selection, from: start, to: start, path: [], context: context))
    XCTAssertNil(AnnotationFactory.createAnnotation(tool: .crop, from: start, to: start, path: [], context: context))
    XCTAssertNil(AnnotationFactory.createAnnotation(tool: .text, from: start, to: start, path: [], context: context))
    XCTAssertNil(AnnotationFactory.createAnnotation(tool: .mockup, from: start, to: start, path: [], context: context))
    XCTAssertNil(AnnotationFactory.createAnnotation(tool: .pencil, from: start, to: start, path: [start], context: context))
    XCTAssertNil(AnnotationFactory.createAnnotation(tool: .highlighter, from: start, to: start, path: [start], context: context))
  }

  func testAnnotationFactory_normalizesNearlyHorizontalHighlighterStroke() throws {
    let path = [
      CGPoint(x: 10, y: 100),
      CGPoint(x: 30, y: 102),
      CGPoint(x: 60, y: 98),
      CGPoint(x: 90, y: 101),
    ]

    let annotation = try XCTUnwrap(AnnotationFactory.createAnnotation(
      tool: .highlighter,
      from: path[0],
      to: path.last!,
      path: path,
      context: makeContext()
    ))

    guard case .highlight(let points) = annotation.type else {
      return XCTFail("Expected highlighter annotation, got \(annotation.type)")
    }
    XCTAssertEqual(points.count, 2)
    XCTAssertEqual(points[0].x, 10, accuracy: 0.0001)
    XCTAssertEqual(points[1].x, 90, accuracy: 0.0001)
    XCTAssertEqual(points[0].y, 100.5, accuracy: 0.0001)
    XCTAssertEqual(points[1].y, 100.5, accuracy: 0.0001)
    XCTAssertEqual(annotation.bounds, CGRect(x: 10, y: 100, width: 80, height: 1))
  }

  func testAnnotationFactory_smallWatermarkDragUsesCanvasSizedDefaultBounds() throws {
    let annotation = try XCTUnwrap(AnnotationFactory.createAnnotation(
      tool: .watermark,
      from: CGPoint(x: 500, y: 250),
      to: CGPoint(x: 504, y: 254),
      path: [],
      context: makeContext(watermarkText: "   ", bounds: CGRect(x: 0, y: 0, width: 1000, height: 500))
    ))

    guard case .watermark(let text) = annotation.type else {
      return XCTFail("Expected watermark annotation, got \(annotation.type)")
    }
    XCTAssertEqual(text, "Snapzy")
    XCTAssertEqual(annotation.bounds, CGRect(x: 290, y: 205, width: 420, height: 90))
  }

  func testAnnotationFactory_usesArrowStyleAndBoundsFromGeometry() throws {
    let annotation = try XCTUnwrap(AnnotationFactory.createAnnotation(
      tool: .arrow,
      from: CGPoint(x: 10, y: 20),
      to: CGPoint(x: 90, y: 80),
      path: [],
      context: makeContext(arrowStyle: .elbow)
    ))

    guard case .arrow(let geometry) = annotation.type else {
      return XCTFail("Expected arrow annotation, got \(annotation.type)")
    }
    XCTAssertEqual(geometry.style, .elbow)
    XCTAssertEqual(annotation.bounds, geometry.bounds())
    XCTAssertGreaterThan(annotation.bounds.width, 0)
    XCTAssertGreaterThan(annotation.bounds.height, 0)
  }

  func testAnnotationProperties_clampControlValueAndDerivedSizes() {
    XCTAssertEqual(AnnotationProperties.clampedControlValue(-10), 1)
    XCTAssertEqual(AnnotationProperties.clampedControlValue(30), 20)
    XCTAssertEqual(AnnotationProperties.counterDiameter(for: 3), 24)
    XCTAssertEqual(AnnotationProperties.pixelatedBlurSize(for: 2), 10)
    XCTAssertEqual(AnnotationProperties.gaussianBlurRadius(for: 2), 16)
  }

  func testAnnotateExporterGenerateCopyURL_incrementsExistingCopies() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SnapzyTests_AnnotateCopyURL_\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let original = directory.appendingPathComponent("capture.png")
    try Data("original".utf8).write(to: original)
    try Data("copy".utf8).write(to: directory.appendingPathComponent("capture_copy.png"))

    let copyURL = AnnotateExporter.generateCopyURL(from: original)

    XCTAssertEqual(copyURL.lastPathComponent, "capture_copy2.png")
  }

  func testCodableBackgroundStyle_roundTripsSupportedStyles() throws {
    let wallpaperURL = URL(string: "file:///tmp/wallpaper.jpg")!
    let blurredURL = URL(string: "file:///tmp/blurred.jpg")!

    XCTAssertEqual(try XCTUnwrap(CodableBackgroundStyle(from: BackgroundStyle.none)).toBackgroundStyle(), .none)
    XCTAssertEqual(try XCTUnwrap(CodableBackgroundStyle(from: .gradient(.cyanBlue))).toBackgroundStyle(), .gradient(.cyanBlue))
    XCTAssertEqual(try XCTUnwrap(CodableBackgroundStyle(from: .wallpaper(wallpaperURL))).toBackgroundStyle(), .wallpaper(wallpaperURL))
    XCTAssertEqual(try XCTUnwrap(CodableBackgroundStyle(from: .blurred(blurredURL))).toBackgroundStyle(), .blurred(blurredURL))

    let solid = try XCTUnwrap(CodableBackgroundStyle(from: .solidColor(.red)))
    XCTAssertEqual(solid.kind, .solidColor)
    XCTAssertNotNil(solid.solidColorRGBA)
  }

  func testRGBAColorClampsComponents() {
    let color = RGBAColor(red: -1, green: 0.25, blue: 2, alpha: 1.5)

    XCTAssertEqual(color.red, 0)
    XCTAssertEqual(color.green, 0.25)
    XCTAssertEqual(color.blue, 1)
    XCTAssertEqual(color.alpha, 1)
  }

  func testAnnotateCanvasPresetPayloadApproximatelyEqualsHonorsTolerance() {
    let first = AnnotateCanvasPresetPayload(
      backgroundStyle: CodableBackgroundStyle(from: .gradient(.bluePurple))!,
      padding: 40,
      shadowIntensity: 0.3,
      cornerRadius: 12
    )
    let close = AnnotateCanvasPresetPayload(
      backgroundStyle: CodableBackgroundStyle(from: .gradient(.bluePurple))!,
      padding: 40.00005,
      shadowIntensity: 0.30005,
      cornerRadius: 12.00005
    )
    let different = AnnotateCanvasPresetPayload(
      backgroundStyle: CodableBackgroundStyle(from: .gradient(.orangeRed))!,
      padding: 40,
      shadowIntensity: 0.3,
      cornerRadius: 12
    )

    XCTAssertTrue(first.approximatelyEquals(close))
    XCTAssertFalse(first.approximatelyEquals(different))
  }

  func testCropAspectRatioNumericValues() {
    XCTAssertEqual(CropAspectRatio.free.ratio, 0)
    XCTAssertEqual(CropAspectRatio.square.ratio, 1)
    XCTAssertEqual(CropAspectRatio.ratio4x3.ratio, 4.0 / 3.0, accuracy: 0.0001)
    XCTAssertEqual(CropAspectRatio.ratio16x9.ratio, 16.0 / 9.0, accuracy: 0.0001)
    XCTAssertEqual(CropAspectRatio.ratio21x9.ratio, 21.0 / 9.0, accuracy: 0.0001)
  }

  func testAnnotationToolTypeDefaultShortcutsAreUniqueAndQuickPropertiesAreScoped() {
    let shortcuts = AnnotationToolType.allCases.map(\.defaultShortcut)
    XCTAssertEqual(Set(shortcuts).count, shortcuts.count)

    XCTAssertFalse(AnnotationToolType.selection.supportsQuickPropertiesBar)
    XCTAssertFalse(AnnotationToolType.crop.supportsQuickPropertiesBar)
    XCTAssertFalse(AnnotationToolType.mockup.supportsQuickPropertiesBar)
    XCTAssertTrue(AnnotationToolType.rectangle.supportsQuickPropertiesBar)
    XCTAssertTrue(AnnotationToolType.watermark.supportsQuickPropertiesBar)
    XCTAssertTrue(AnnotationToolType.filledRectangle.supportsQuickFillColor)
    XCTAssertFalse(AnnotationToolType.rectangle.supportsQuickFillColor)
    XCTAssertTrue(AnnotationToolType.rectangle.supportsQuickCornerRadius)
    XCTAssertFalse(AnnotationToolType.oval.supportsQuickCornerRadius)
  }

  func testMockupPresetCatalogContainsUniqueBuiltInPresets() {
    let presets = MockupPreset.allPresets

    XCTAssertEqual(presets.count, 8)
    XCTAssertEqual(Set(presets.map(\.id)).count, presets.count)
    XCTAssertEqual(DefaultPresets.all, presets)
    XCTAssertEqual(DefaultPresets.preset(named: "Hero Shot"), .heroShot)
    XCTAssertNil(DefaultPresets.preset(named: "Missing"))
  }

  private func makeContext(
    properties: AnnotationProperties = AnnotationProperties(),
    arrowStyle: ArrowStyle = .straight,
    blurType: BlurType = .pixelated,
    counterValue: Int = 1,
    watermarkText: String = "Snapzy",
    bounds: CGRect = CGRect(x: 0, y: 0, width: 400, height: 300)
  ) -> AnnotationFactory.CreationContext {
    AnnotationFactory.CreationContext(
      properties: properties,
      arrowStyle: arrowStyle,
      blurType: blurType,
      counterValue: counterValue,
      watermarkText: watermarkText,
      activeAnnotationBounds: bounds
    )
  }
}
