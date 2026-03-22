//
//  CloudUploadHistoryStore.swift
//  Snapzy
//
//  Local JSON persistence for cloud upload history records
//

import Combine
import Foundation
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "CloudUploadHistoryStore")

/// Manages persistent storage of cloud upload records using local JSON file
@MainActor
final class CloudUploadHistoryStore: ObservableObject {

  static let shared = CloudUploadHistoryStore()

  @Published private(set) var records: [CloudUploadRecord] = []

  private let fileManager = FileManager.default
  private var storageURL: URL {
    let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let dir = appSupport.appendingPathComponent("Snapzy", isDirectory: true)
    try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("cloud-upload-history.json")
  }

  private init() {
    loadAll()
  }

  // MARK: - Public API

  /// Add a new upload record
  func add(_ record: CloudUploadRecord) {
    records.insert(record, at: 0)
    save()
    logger.info("Upload record added: \(record.fileName)")
  }

  /// Remove a record by ID
  func remove(id: UUID) {
    records.removeAll { $0.id == id }
    save()
  }

  /// Remove all records
  func removeAll() {
    records.removeAll()
    save()
  }

  /// Most recent N records
  func recentRecords(limit: Int = 5) -> [CloudUploadRecord] {
    Array(records.prefix(limit))
  }

  // MARK: - Persistence

  func loadAll() {
    guard fileManager.fileExists(atPath: storageURL.path) else {
      records = []
      return
    }

    do {
      let data = try Data(contentsOf: storageURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      records = try decoder.decode([CloudUploadRecord].self, from: data)
      logger.info("Loaded \(self.records.count) upload records")
    } catch {
      logger.error("Failed to load upload history: \(error.localizedDescription)")
      records = []
    }
  }

  func save() {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      encoder.outputFormatting = .prettyPrinted
      let data = try encoder.encode(records)
      try data.write(to: storageURL, options: .atomic)
    } catch {
      logger.error("Failed to save upload history: \(error.localizedDescription)")
    }
  }
}
