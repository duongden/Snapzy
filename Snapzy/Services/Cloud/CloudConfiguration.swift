//
//  CloudConfiguration.swift
//  Snapzy
//
//  Data model for cloud storage configuration and expire time options
//

import Foundation

// MARK: - Cloud Expire Time

/// Expiration time options for uploaded files
enum CloudExpireTime: String, Codable, CaseIterable {
  case min15 = "15m"
  case min30 = "30m"
  case hour1 = "1h"
  case hour2 = "2h"
  case hour3 = "3h"
  case hour5 = "5h"
  case hour8 = "8h"
  case hour12 = "12h"
  case day1 = "1d"
  case day3 = "3d"
  case day5 = "5d"
  case day7 = "7d"
  case day15 = "15d"
  case day24 = "24d"
  case day30 = "30d"
  case permanent = "permanent"

  var displayName: String {
    switch self {
    case .min15: return "15 minutes"
    case .min30: return "30 minutes"
    case .hour1: return "1 hour"
    case .hour2: return "2 hours"
    case .hour3: return "3 hours"
    case .hour5: return "5 hours"
    case .hour8: return "8 hours"
    case .hour12: return "12 hours"
    case .day1: return "1 day"
    case .day3: return "3 days"
    case .day5: return "5 days"
    case .day7: return "7 days"
    case .day15: return "15 days"
    case .day24: return "24 days"
    case .day30: return "30 days"
    case .permanent: return "Permanent"
    }
  }

  /// Duration in seconds, nil for permanent
  var seconds: Int? {
    switch self {
    case .min15: return 15 * 60
    case .min30: return 30 * 60
    case .hour1: return 3600
    case .hour2: return 2 * 3600
    case .hour3: return 3 * 3600
    case .hour5: return 5 * 3600
    case .hour8: return 8 * 3600
    case .hour12: return 12 * 3600
    case .day1: return 86400
    case .day3: return 3 * 86400
    case .day5: return 5 * 86400
    case .day7: return 7 * 86400
    case .day15: return 15 * 86400
    case .day24: return 24 * 86400
    case .day30: return 30 * 86400
    case .permanent: return nil
    }
  }

  var isPermanent: Bool { self == .permanent }
}

// MARK: - Cloud Configuration

/// Non-sensitive cloud storage configuration stored in UserDefaults
struct CloudConfiguration: Codable, Equatable {
  let providerType: CloudProviderType
  let bucket: String
  let region: String
  let endpoint: String?
  let customDomain: String?
  let expireTime: CloudExpireTime

  /// Validate that required fields are present
  var isValid: Bool {
    !bucket.trimmingCharacters(in: .whitespaces).isEmpty
      && (providerType == .cloudflareR2
        ? !(endpoint ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        : !region.trimmingCharacters(in: .whitespaces).isEmpty)
  }
}
