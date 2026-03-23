//
//  CloudPasswordService.swift
//  Snapzy
//
//  Manages optional password protection for cloud credentials.
//  Stores a SHA-256 hash in the macOS Keychain — no plaintext passwords are ever persisted.
//

import CryptoKit
import Foundation
import Security

/// Manages the optional protection password for cloud credentials.
/// The password is hashed with SHA-256 before storage; verification compares hashes.
@MainActor
final class CloudPasswordService {

  static let shared = CloudPasswordService()

  // MARK: - Keychain Key

  private enum KeychainKeys {
    static let passwordHash = "com.trongduong.snapzy.cloud.passwordHash"
    static let service = "com.trongduong.snapzy.cloud"
  }

  private init() {}

  // MARK: - Public API

  /// Whether a protection password has been set.
  var hasPassword: Bool {
    loadHash() != nil
  }

  /// Hash and store a new protection password in the Keychain.
  func savePassword(_ password: String) throws {
    let hash = sha256(password)
    try saveToKeychain(key: KeychainKeys.passwordHash, value: hash)
  }

  /// Verify a password against the stored hash.
  /// Returns `false` if no password is set or the hash doesn't match.
  func verifyPassword(_ password: String) -> Bool {
    guard let storedHash = loadHash() else { return false }
    return sha256(password) == storedHash
  }

  /// Remove the stored password hash from the Keychain.
  func removePassword() {
    deleteFromKeychain(key: KeychainKeys.passwordHash)
  }

  // MARK: - Hashing

  private func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  // MARK: - Keychain Helpers

  private func loadHash() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: KeychainKeys.passwordHash,
      kSecAttrService as String: KeychainKeys.service,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess, let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func saveToKeychain(key: String, value: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw CloudError.keychainError("Failed to encode password hash")
    }

    // Delete existing item first
    deleteFromKeychain(key: key)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: KeychainKeys.service,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw CloudError.keychainError("SecItemAdd failed: \(status)")
    }
  }

  private func deleteFromKeychain(key: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: KeychainKeys.service,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
