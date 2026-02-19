import Foundation

final class DeviceFingerprint {
    private let lock = NSLock()
    private var cachedFingerprint: String?
    private let keychain = KeychainService()

    private let stableDeviceIDKey = "device_fingerprint_v2"
    private let legacyLicenseCacheKey = "com.snapzy.license.cache"

    static let shared = DeviceFingerprint()

    private init() {}

    func generate() -> String {
        lock.lock()
        defer { lock.unlock() }

        if let existing = cachedFingerprint {
            return existing
        }

        let fingerprint = loadOrCreateStableFingerprint()
        cachedFingerprint = fingerprint
        return fingerprint
    }

    func generateDeviceName() -> String {
        let fingerprintPrefix = String(generate().prefix(8))
        return "Snapzy Mac \(fingerprintPrefix)"
    }

    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedFingerprint = nil
    }

    private func loadOrCreateStableFingerprint() -> String {
        if let data = try? keychain.load(forKey: stableDeviceIDKey),
           let fingerprint = String(data: data, encoding: .utf8),
           !fingerprint.isEmpty {
            return fingerprint
        }

        // Migration path: preserve old fingerprint if cache has one.
        if let legacyFingerprint = loadLegacyCachedFingerprint() {
            persistStableFingerprint(legacyFingerprint)
            return legacyFingerprint
        }

        let newFingerprint = UUID().uuidString.lowercased()
        persistStableFingerprint(newFingerprint)
        return newFingerprint
    }

    private func persistStableFingerprint(_ fingerprint: String) {
        try? keychain.save(data: fingerprint.data(using: .utf8)!, forKey: stableDeviceIDKey)
    }

    private func loadLegacyCachedFingerprint() -> String? {
        guard let data = UserDefaults.standard.data(forKey: legacyLicenseCacheKey) else {
            return nil
        }

        struct LegacyCacheEntry: Decodable {
            let deviceFingerprint: String
        }

        guard let entry = try? JSONDecoder().decode(LegacyCacheEntry.self, from: data),
              !entry.deviceFingerprint.isEmpty else {
            return nil
        }
        return entry.deviceFingerprint
    }
}
