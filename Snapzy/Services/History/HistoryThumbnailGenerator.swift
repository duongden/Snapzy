//
//  HistoryThumbnailGenerator.swift
//  Snapzy
//
//  Lazy thumbnail generation and caching for capture history
//

import AppKit
import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "HistoryThumbnailGenerator")

/// Generates and caches thumbnails for capture history items
final class HistoryThumbnailGenerator {

  static let shared = HistoryThumbnailGenerator()

  private let cacheVersion = "preview-v2"
  private let maxDimension: CGFloat = 208
  private let compressionFactor: CGFloat = 0.58
  private let workerQueue = DispatchQueue(
    label: "snapzy.history-thumbnail-generator.worker",
    qos: .utility,
    attributes: .concurrent
  )
  private let stateQueue = DispatchQueue(label: "snapzy.history-thumbnail-generator.state")
  private let memoryCache = NSCache<NSString, NSImage>()
  private var inFlightRequests: [UUID: [(NSImage?) -> Void]] = [:]

  var thumbnailsDirectory: URL {
    let appSupport = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    return appSupport
      .appendingPathComponent("Snapzy", isDirectory: true)
      .appendingPathComponent("HistoryThumbnails", isDirectory: true)
  }

  private init() {
    try? FileManager.default.createDirectory(
      at: thumbnailsDirectory,
      withIntermediateDirectories: true
    )
    memoryCache.countLimit = 160
    memoryCache.totalCostLimit = 48 * 1024 * 1024
  }

  // MARK: - Public API

  func loadThumbnailImage(for record: CaptureHistoryRecord) async -> NSImage? {
    await withCheckedContinuation { continuation in
      loadThumbnailImage(for: record) { image in
        continuation.resume(returning: image)
      }
    }
  }

  func loadThumbnailImage(
    for record: CaptureHistoryRecord,
    completion: @escaping (NSImage?) -> Void
  ) {
    let cacheKey = cacheKey(for: record.id)

    if let cachedImage = memoryCache.object(forKey: cacheKey) {
      DispatchQueue.main.async {
        completion(cachedImage)
      }
      return
    }

    let shouldStartWork = stateQueue.sync { () -> Bool in
      if inFlightRequests[record.id] != nil {
        inFlightRequests[record.id]?.append(completion)
        return false
      }

      inFlightRequests[record.id] = [completion]
      return true
    }

    guard shouldStartWork else { return }

    workerQueue.async { [weak self] in
      guard let self else { return }
      let image = self.resolveThumbnailImage(for: record)

      if let image {
        let cost = max(Int(image.size.width * image.size.height * 4), 1)
        self.memoryCache.setObject(image, forKey: cacheKey, cost: cost)
      }

      let completions = self.stateQueue.sync {
        self.inFlightRequests.removeValue(forKey: record.id) ?? []
      }

      DispatchQueue.main.async {
        completions.forEach { $0(image) }
      }
    }
  }

  func preloadThumbnails(for records: [CaptureHistoryRecord]) {
    records.forEach { record in
      loadThumbnailImage(for: record) { _ in }
    }
  }

  /// Generate a thumbnail for a history record and cache it to disk.
  /// Returns the cached thumbnail URL if successful.
  func generate(for record: CaptureHistoryRecord) async -> URL? {
    await withCheckedContinuation { continuation in
      let preferredURL = existingThumbnailURL(for: record)
      loadThumbnailImage(for: record) { image in
        guard image != nil else {
          continuation.resume(returning: nil)
          return
        }

        continuation.resume(returning: preferredURL ?? self.defaultThumbnailURL(for: record.id))
      }
    }
  }

  /// Load a thumbnail from disk for a record
  func thumbnailURL(for record: CaptureHistoryRecord) -> URL? {
    existingThumbnailURL(for: record)
  }

  /// Total size of all cached thumbnails in bytes
  func totalThumbnailSize() -> Int64 {
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(
      at: thumbnailsDirectory,
      includingPropertiesForKeys: [.fileSizeKey]
    ) else { return 0 }

    var total: Int64 = 0
    for url in contents {
      if let attrs = try? fm.attributesOfItem(atPath: url.path),
        let size = attrs[.size] as? Int64 {
        total += size
      }
    }
    return total
  }

  /// Delete all cached thumbnails and clear thumbnail paths in database
  func clearAllThumbnails() {
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(
      at: thumbnailsDirectory,
      includingPropertiesForKeys: nil
    ) else { return }

    for url in contents {
      try? fm.removeItem(at: url)
    }

    memoryCache.removeAllObjects()

    // Clear all thumbnail paths in database
    DispatchQueue.main.async {
      CaptureHistoryStore.shared.clearAllThumbnailPaths()
      logger.info("All history thumbnails cleared")
    }
  }

  /// Delete thumbnail for a specific record ID
  func deleteThumbnail(for recordId: UUID) {
    try? FileManager.default.removeItem(at: defaultThumbnailURL(for: recordId))
    try? FileManager.default.removeItem(at: legacyThumbnailURL(for: recordId))
    memoryCache.removeObject(forKey: cacheKey(for: recordId))
  }

  // MARK: - Private

  private func resolveThumbnailImage(for record: CaptureHistoryRecord) -> NSImage? {
    if let cachedURL = existingThumbnailURL(for: record),
      let cachedImage = decodeThumbnail(at: cachedURL)
    {
      return cachedImage
    }

    guard FileManager.default.fileExists(atPath: record.filePath) else {
      logger.debug("File missing, skipping thumbnail: \(record.fileName)")
      return nil
    }

    let generatedThumbnail: GeneratedThumbnail?
    switch record.captureType {
    case .screenshot, .gif:
      generatedThumbnail = generateImageThumbnail(for: record)
    case .video:
      generatedThumbnail = generateVideoThumbnail(for: record)
    }

    guard let generatedThumbnail else { return nil }

    DispatchQueue.main.async {
      CaptureHistoryStore.shared.updateThumbnailPath(id: record.id, path: generatedThumbnail.url.path)
    }

    return generatedThumbnail.image
  }

  private func generateImageThumbnail(for record: CaptureHistoryRecord) -> GeneratedThumbnail? {
    let url = record.fileURL
    let scopedAccess = SandboxFileAccessManager.shared.beginAccessingURL(url)
    defer { scopedAccess.stop() }

    guard let cgImage = downsampledImage(at: url) else {
      logger.warning("Failed to load image for thumbnail: \(record.fileName)")
      return nil
    }

    return saveThumbnail(cgImage, recordId: record.id)
  }

  private func generateVideoThumbnail(for record: CaptureHistoryRecord) -> GeneratedThumbnail? {
    let url = record.fileURL
    let scopedAccess = SandboxFileAccessManager.shared.beginAccessingURL(url)
    defer { scopedAccess.stop() }

    let asset = AVURLAsset(url: url)

    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.maximumSize = CGSize(width: maxDimension * 2, height: maxDimension * 2)

    // Extract at mid-point or 1s, whichever is smaller
    let extractTime: TimeInterval
    if let duration = record.duration, duration > 0 {
      extractTime = min(duration / 2, 1.0)
    } else {
      extractTime = 0
    }

    let time = CMTimeMakeWithSeconds(extractTime, preferredTimescale: 600)

    do {
      let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
      return saveThumbnail(cgImage, recordId: record.id)
    } catch {
      logger.error("Failed to generate video thumbnail: \(error.localizedDescription)")
      return nil
    }
  }

  private func existingThumbnailURL(for record: CaptureHistoryRecord) -> URL? {
    let currentURL = defaultThumbnailURL(for: record.id)

    if FileManager.default.fileExists(atPath: currentURL.path) {
      return currentURL
    }

    guard
      let storedURL = record.thumbnailURL,
      storedURL.lastPathComponent == currentURL.lastPathComponent,
      FileManager.default.fileExists(atPath: storedURL.path)
    else {
      return nil
    }

    return storedURL
  }

  private func defaultThumbnailURL(for recordId: UUID) -> URL {
    thumbnailsDirectory.appendingPathComponent("\(recordId.uuidString)-\(cacheVersion).jpg")
  }

  private func legacyThumbnailURL(for recordId: UUID) -> URL {
    thumbnailsDirectory.appendingPathComponent("\(recordId.uuidString).jpg")
  }

  private func cacheKey(for recordId: UUID) -> NSString {
    NSString(string: "\(recordId.uuidString)-\(cacheVersion)")
  }

  private func downsampledImage(at url: URL) -> CGImage? {
    let sourceOptions: [CFString: Any] = [
      kCGImageSourceShouldCache: false
    ]

    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
      return nil
    }

    let maxPixelSize = Int(maxDimension * 2)
    let downsampleOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]

    return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary)
  }

  private func decodeThumbnail(at url: URL) -> NSImage? {
    let options: [CFString: Any] = [
      kCGImageSourceShouldCacheImmediately: true
    ]
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
      return nil
    }

    return NSImage(
      cgImage: cgImage,
      size: NSSize(width: cgImage.width, height: cgImage.height)
    )
  }

  private func saveThumbnail(_ image: CGImage, recordId: UUID) -> GeneratedThumbnail? {
    let url = defaultThumbnailURL(for: recordId)

    guard let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      UTType.jpeg.identifier as CFString,
      1,
      nil
    ) else {
      logger.warning("Failed to create thumbnail destination for \(recordId)")
      return nil
    }

    let properties: [CFString: Any] = [
      kCGImageDestinationLossyCompressionQuality: compressionFactor
    ]
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)

    guard CGImageDestinationFinalize(destination) else {
      logger.warning("Failed to encode thumbnail as JPEG for \(recordId)")
      return nil
    }

    let legacyURL = legacyThumbnailURL(for: recordId)
    if legacyURL != url {
      try? FileManager.default.removeItem(at: legacyURL)
    }

    let thumbnailImage = NSImage(
      cgImage: image,
      size: NSSize(width: image.width, height: image.height)
    )

    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
      let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
      memoryCache.setObject(thumbnailImage, forKey: cacheKey(for: recordId), cost: max(fileSize, 1))
      return GeneratedThumbnail(url: url, image: thumbnailImage)
    } catch {
      logger.error("Failed to read thumbnail metadata: \(error.localizedDescription)")
      return nil
    }
  }
}

private struct GeneratedThumbnail {
  let url: URL
  let image: NSImage
}
