//
//  CloudUsageService.swift
//  Snapzy
//
//  Fetches cloud bucket usage via S3-compatible API (ListObjectsV2 + lifecycle)
//  Works with both AWS S3 and Cloudflare R2 using existing credentials.
//

import Combine
import Foundation
import os.log

private let logger = Logger(subsystem: "Snapzy", category: "CloudUsageService")

/// Fetches and caches bucket usage statistics using S3-compatible API.
@MainActor
final class CloudUsageService: ObservableObject {

  static let shared = CloudUsageService()

  // MARK: - Published State

  @Published private(set) var usageInfo: CloudUsageInfo?
  @Published private(set) var isLoading = false
  @Published private(set) var error: String?

  // MARK: - Pricing Constants (per GB-month)

  private static let r2PricePerGB: Double = 0.015
  private static let s3PricePerGB: Double = 0.023
  private static let r2FreeStorageBytes: Int64 = 10 * 1_073_741_824  // 10 GB
  private static let s3FreeStorageBytes: Int64 = 5 * 1_073_741_824   // 5 GB (year 1)

  private init() {}

  // MARK: - Computed Properties

  /// Estimated monthly cost based on storage × unit price
  var estimatedMonthlyCost: String {
    guard let info = usageInfo else { return "—" }
    let config = CloudManager.shared.loadConfiguration()
    let providerType = config?.providerType ?? .awsS3

    let storageGB = Double(info.totalStorageBytes) / 1_073_741_824.0
    let freeBytes = providerType == .cloudflareR2
      ? Self.r2FreeStorageBytes : Self.s3FreeStorageBytes
    let pricePerGB = providerType == .cloudflareR2
      ? Self.r2PricePerGB : Self.s3PricePerGB

    if info.totalStorageBytes <= freeBytes {
      return "Free tier"
    }

    let billableGB = max(0.0, storageGB - Double(freeBytes) / 1_073_741_824.0)
    let cost = billableGB * pricePerGB

    if cost < 0.01 {
      return "< $0.01"
    }
    return String(format: "$%.2f", cost)
  }

  // MARK: - Fetch

  /// Fetch bucket usage by listing objects and checking lifecycle config.
  func fetchUsage() async {
    guard !isLoading else { return }
    guard let provider = CloudManager.shared.createProvider(),
          let config = CloudManager.shared.loadConfiguration()
    else {
      error = "Cloud not configured"
      return
    }

    isLoading = true
    error = nil

    do {
      // 1. List all objects with snapzy/ prefix
      let (totalBytes, objectCount) = try await listAllObjects(config: config)

      // 2. Get lifecycle rule days
      let lifecycleDays = try? await getLifecycleRuleDays(config: config)

      let info = CloudUsageInfo(
        totalStorageBytes: totalBytes,
        objectCount: objectCount,
        lifecycleRuleDays: lifecycleDays,
        fetchedAt: Date()
      )
      usageInfo = info
      logger.info("Usage fetched: \(info.formattedStorage), \(objectCount) objects")
    } catch {
      self.error = error.localizedDescription
      logger.error("Usage fetch failed: \(error.localizedDescription)")
    }

    isLoading = false
  }

  // MARK: - ListObjectsV2

  /// List all objects with `snapzy/` prefix, handling pagination.
  /// Returns (totalBytes, objectCount).
  private func listAllObjects(
    config: CloudConfiguration
  ) async throws -> (Int64, Int) {
    let credentials = loadCredentials()
    guard let accessKey = credentials.accessKey,
          let secretKey = credentials.secretKey
    else {
      throw CloudError.notConfigured
    }

    let endpoint = buildEndpoint(config: config)
    let region = config.region.isEmpty ? "us-east-1" : config.region

    var totalBytes: Int64 = 0
    var objectCount = 0
    var continuationToken: String? = nil

    repeat {
      var queryString = "list-type=2&prefix=snapzy/&max-keys=1000"
      if let token = continuationToken {
        queryString += "&continuation-token=\(token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? token)"
      }

      let url = URL(string: "\(endpoint)/\(config.bucket)?\(queryString)")!
      var request = URLRequest(url: url)
      request.httpMethod = "GET"

      let signedRequest = try AWSV4Signer.sign(
        request: request,
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        payloadHash: AWSV4Signer.sha256Hex("")
      )

      let (data, response) = try await URLSession.shared.data(for: signedRequest)

      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
      else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data, encoding: .utf8) ?? ""
        throw CloudError.uploadFailed(
          statusCode: statusCode,
          message: "ListObjectsV2 failed: \(body)"
        )
      }

      // Parse XML response
      let parsed = ListObjectsV2Parser.parse(data: data)
      totalBytes += parsed.totalSize
      objectCount += parsed.objectCount
      continuationToken = parsed.nextContinuationToken

    } while continuationToken != nil

    return (totalBytes, objectCount)
  }

  // MARK: - Lifecycle Rule

  /// Get the Snapzy lifecycle rule expiration days.
  private func getLifecycleRuleDays(
    config: CloudConfiguration
  ) async throws -> Int? {
    let credentials = loadCredentials()
    guard let accessKey = credentials.accessKey,
          let secretKey = credentials.secretKey
    else { return nil }

    let endpoint = buildEndpoint(config: config)
    let region = config.region.isEmpty ? "us-east-1" : config.region

    let url = URL(string: "\(endpoint)/\(config.bucket)?lifecycle")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let signedRequest = try AWSV4Signer.sign(
      request: request,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
      payloadHash: AWSV4Signer.sha256Hex("")
    )

    let (data, response) = try await URLSession.shared.data(for: signedRequest)

    guard let httpResponse = response as? HTTPURLResponse else { return nil }

    // 404 = no lifecycle config
    if httpResponse.statusCode == 404 { return nil }

    guard (200...299).contains(httpResponse.statusCode) else { return nil }

    // Parse XML to find snapzy-auto-expire rule
    return LifecycleRuleParser.parseSnapzyExpireDays(from: data)
  }

  // MARK: - Helpers

  private func loadCredentials() -> (accessKey: String?, secretKey: String?) {
    let ak = CloudManager.shared.loadAccessKey()
    let sk = CloudManager.shared.loadSecretKey()
    return (ak.isEmpty ? nil : ak, sk.isEmpty ? nil : sk)
  }

  private func buildEndpoint(config: CloudConfiguration) -> String {
    if let ep = config.endpoint, !ep.isEmpty {
      return ep
    }
    let region = config.region.isEmpty ? "us-east-1" : config.region
    return "https://s3.\(region).amazonaws.com"
  }
}

// MARK: - ListObjectsV2 XML Parser

/// Lightweight XML parser for ListObjectsV2 response.
/// Extracts <Size> values, <KeyCount>, and <NextContinuationToken>.
final class ListObjectsV2Parser: NSObject, XMLParserDelegate {

  struct Result {
    var totalSize: Int64 = 0
    var objectCount: Int = 0
    var nextContinuationToken: String? = nil
  }

  private var result = Result()
  private var currentElement = ""
  private var currentText = ""

  static func parse(data: Data) -> Result {
    let handler = ListObjectsV2Parser()
    let parser = XMLParser(data: data)
    parser.delegate = handler
    parser.parse()
    return handler.result
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    currentElement = elementName
    currentText = ""
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentText += string
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
    switch elementName {
    case "Size":
      if let size = Int64(text) {
        result.totalSize += size
        result.objectCount += 1
      }
    case "NextContinuationToken":
      if !text.isEmpty {
        result.nextContinuationToken = text
      }
    default:
      break
    }
  }
}

// MARK: - Lifecycle Rule Parser

/// Parses lifecycle configuration XML to find the Snapzy auto-expire rule.
final class LifecycleRuleParser: NSObject, XMLParserDelegate {

  private var insideRule = false
  private var currentElement = ""
  private var currentText = ""
  private var currentRuleID = ""
  private var currentDays: Int? = nil
  private var foundDays: Int? = nil

  static func parseSnapzyExpireDays(from data: Data) -> Int? {
    let handler = LifecycleRuleParser()
    let parser = XMLParser(data: data)
    parser.delegate = handler
    parser.parse()
    return handler.foundDays
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    currentElement = elementName
    currentText = ""
    if elementName == "Rule" {
      insideRule = true
      currentRuleID = ""
      currentDays = nil
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentText += string
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
    if insideRule {
      switch elementName {
      case "ID":
        currentRuleID = text
      case "Days":
        currentDays = Int(text)
      case "Rule":
        if currentRuleID == "snapzy-auto-expire", let days = currentDays {
          foundDays = days
        }
        insideRule = false
      default:
        break
      }
    }
  }
}
