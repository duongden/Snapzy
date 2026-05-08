//
//  OCRRecognitionTests.swift
//  SnapzyTests
//
//  Regression coverage for language-aware Vision OCR routing.
//

import AppKit
import Vision
import XCTest
@testable import Snapzy

@MainActor
final class OCRRecognitionTests: XCTestCase {

  func testVisionOCRProfile_routesReadmeSupportedLanguages() throws {
    let cases: [(language: String, primaryVisionLanguage: String?, profileID: String)] = [
      ("en", nil, "default-interface"),
      ("vi", "vi-VT", "vietnamese-interface"),
      ("zh-Hans", "zh-Hans", "simplified-chinese-interface"),
      ("zh-Hant", "zh-Hant", "traditional-chinese-interface"),
      ("es", "es-ES", "spanish-interface"),
      ("ja", "ja-JP", "japanese-interface"),
      ("ko", "ko-KR", "korean-interface"),
      ("ru", "ru-RU", "russian-interface"),
      ("fr", "fr-FR", "french-interface"),
      ("de", "de-DE", "german-interface"),
    ]

    for testCase in cases {
      let profile = VisionOCRProfile.resolve(
        for: OCRRequest(
          image: try renderImage(text: "Snapzy OCR"),
          preferredLanguageIdentifier: testCase.language
        )
      )

      XCTAssertEqual(profile.id, testCase.profileID, testCase.language)
      XCTAssertEqual(profile.recognitionLanguages.first, testCase.primaryVisionLanguage, testCase.language)
      XCTAssertEqual(profile.automaticallyDetectsLanguage, testCase.primaryVisionLanguage == nil, testCase.language)
      XCTAssertTrue(profile.usesLanguageCorrection, testCase.language)
    }
  }

  func testVietnameseOCR_preservesDiacriticsForShortIssuePhrase() async throws {
    try XCTSkipIf(!supportedVisionLanguages().contains("vi-VT"), "Vision Vietnamese OCR unavailable")

    let result = try await OCRService.shared.recognize(
      OCRRequest(
        image: try renderImage(text: "Tài sản"),
        preferredLanguageIdentifier: "vi",
        contentType: .interfaceText
      )
    )

    XCTAssertTrue(result.text.contains("Tài sản"), result.text)
    XCTAssertFalse(result.text.contains("Tai san"), result.text)
    XCTAssertEqual(result.profileID, "vietnamese-interface")
  }

  func testVietnameseOCR_preservesDiverseDiacriticsForCommonPhrases() async throws {
    try XCTSkipIf(!supportedVisionLanguages().contains("vi-VT"), "Vision Vietnamese OCR unavailable")

    let phrases = [
      "Tài sản cố định",
      "Số dư tài khoản",
      "Đường dẫn đã sao chép",
      "Ưu đãi đặc biệt",
      "Chỉnh sửa thủ công",
      "Cộng hòa xã hội"
    ]

    for phrase in phrases {
      let result = try await OCRService.shared.recognize(
        OCRRequest(
          image: try renderImage(text: phrase),
          preferredLanguageIdentifier: "vi",
          contentType: .interfaceText
        )
      )

      XCTAssertTrue(
        OCRBenchmarkMetrics.normalized(result.text).contains(phrase),
        "expected \(phrase), got \(result.text)"
      )
    }
  }

  func testVietnameseOCR_reflowsSameRowWordFragments() async throws {
    try XCTSkipIf(!supportedVisionLanguages().contains("vi-VT"), "Vision Vietnamese OCR unavailable")

    let result = try await OCRService.shared.recognize(
      OCRRequest(
        image: try renderImage(textChunks: ["Ưu đãi", "đặc", "biệt"], horizontalGap: 100),
        preferredLanguageIdentifier: "vi",
        contentType: .interfaceText
      )
    )

    XCTAssertTrue(
      OCRBenchmarkMetrics.normalized(result.text).contains("Ưu đãi đặc biệt"),
      "expected same-row fragments to reflow, got \(result.text)"
    )
  }

  func testOCR_recognizesReadmeSupportedLanguageSamples() async throws {
    let cases: [(language: String, visionLanguage: String, text: String)] = [
      ("en", "en-US", "Copy text"),
      ("vi", "vi-VT", "Chính xác"),
      ("zh-Hans", "zh-Hans", "复制文本"),
      ("zh-Hant", "zh-Hant", "複製文字"),
      ("es", "es-ES", "Texto rápido"),
      ("ja", "ja-JP", "設定画面"),
      ("ko", "ko-KR", "설정 화면"),
      ("ru", "ru-RU", "Точные заметки"),
      ("fr", "fr-FR", "Texte précis"),
      ("de", "de-DE", "Überschriften"),
    ]
    let supportedLanguages = try supportedVisionLanguages()

    for testCase in cases {
      try XCTSkipIf(!supportedLanguages.contains(testCase.visionLanguage), "Vision OCR language \(testCase.visionLanguage) unavailable")

      let result = try await OCRService.shared.recognize(
        OCRRequest(
          image: try renderImage(text: testCase.text),
          preferredLanguageIdentifier: testCase.language,
          contentType: .interfaceText
        )
      )

      XCTAssertTrue(
        OCRBenchmarkMetrics.normalized(result.text).contains(testCase.text),
        "\(testCase.language): expected \(testCase.text), got \(result.text)"
      )
    }
  }

  private func supportedVisionLanguages() throws -> Set<String> {
    Set(try VNRecognizeTextRequest().supportedRecognitionLanguages())
  }

  private func renderImage(text: String) throws -> CGImage {
    try renderImage(textChunks: [text], horizontalGap: 0)
  }

  private func renderImage(textChunks: [String], horizontalGap: CGFloat) throws -> CGImage {
    let font = NSFont.systemFont(ofSize: 48, weight: .regular)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: NSColor.black
    ]
    let textSizes = textChunks.map {
      ($0 as NSString).size(withAttributes: attributes)
    }
    let textWidth = textSizes.map(\.width).reduce(0, +)
      + horizontalGap * CGFloat(max(textChunks.count - 1, 0))
    let textHeight = textSizes.map(\.height).max() ?? 0
    let padding: CGFloat = 40
    let imageSize = NSSize(
      width: ceil(textWidth + padding * 2),
      height: ceil(textHeight + padding * 2)
    )
    let image = NSImage(size: imageSize)

    image.lockFocus()
    NSColor.white.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: imageSize)).fill()
    var x = padding
    for (index, text) in textChunks.enumerated() {
      (text as NSString).draw(
        at: NSPoint(x: x, y: padding),
        withAttributes: attributes
      )
      x += textSizes[index].width + horizontalGap
    }
    image.unlockFocus()

    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      throw OCRError.imageConversionFailed
    }
    return cgImage
  }
}
