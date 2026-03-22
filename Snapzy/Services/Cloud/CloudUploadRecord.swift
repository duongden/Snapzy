//
//  CloudUploadRecord.swift
//  Snapzy
//
//  Model for persisted cloud upload history entries
//

import Foundation

/// Record of a file uploaded to cloud storage, persisted locally
struct CloudUploadRecord: Identifiable, Codable, Equatable {
  let id: UUID
  let fileName: String
  let publicURL: URL
  let key: String
  let fileSize: Int64
  let uploadedAt: Date
  let providerType: CloudProviderType
  let expireTime: CloudExpireTime

  /// Human-readable file size
  var formattedFileSize: String {
    ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
  }

  /// Whether this upload has expired based on its expire time
  var isExpired: Bool {
    guard let seconds = expireTime.seconds else { return false }
    return Date().timeIntervalSince(uploadedAt) > TimeInterval(seconds)
  }

  /// Formatted upload date
  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: uploadedAt)
  }
}
