//
//  SystemWallpaperManager.swift
//  ClaudeShot
//
//  Service to enumerate and manage macOS system wallpapers
//

import AppKit
import Combine
import Foundation

class SystemWallpaperManager: ObservableObject {
  static let shared = SystemWallpaperManager()

  @Published var systemWallpapers: [WallpaperItem] = []
  @Published var isLoading = false
  @Published var accessDenied = false

  private let systemWallpaperPaths = [
    "/System/Library/Desktop Pictures",
    "/Library/Desktop Pictures",
  ]

  private let supportedExtensions = ["heic", "jpg", "jpeg", "png"]

  struct WallpaperItem: Identifiable, Hashable {
    let id = UUID()
    let fullImageURL: URL
    let thumbnailURL: URL?
    let name: String

    func hash(into hasher: inout Hasher) {
      hasher.combine(fullImageURL)
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
      lhs.fullImageURL == rhs.fullImageURL
    }
  }

  private init() {}

  @MainActor
  func loadSystemWallpapers() async {
    guard !isLoading else { return }
    isLoading = true
    accessDenied = false

    let wallpapers = await Task.detached(priority: .userInitiated) {
      self.enumerateAllDirectories()
    }.value

    if wallpapers.isEmpty && !hasAccessibleDirectory() {
      accessDenied = true
    }

    systemWallpapers = wallpapers
    isLoading = false
  }

  private func hasAccessibleDirectory() -> Bool {
    systemWallpaperPaths.contains { canAccessDirectory($0) }
  }

  private func canAccessDirectory(_ path: String) -> Bool {
    FileManager.default.isReadableFile(atPath: path)
  }

  private func enumerateAllDirectories() -> [WallpaperItem] {
    var items: [WallpaperItem] = []
    let fm = FileManager.default

    for basePath in systemWallpaperPaths {
      guard canAccessDirectory(basePath) else { continue }

      let baseURL = URL(fileURLWithPath: basePath)
      guard
        let contents = try? fm.contentsOfDirectory(
          at: baseURL,
          includingPropertiesForKeys: [.isRegularFileKey],
          options: [.skipsHiddenFiles]
        )
      else { continue }

      for url in contents {
        let ext = url.pathExtension.lowercased()
        guard supportedExtensions.contains(ext) else { continue }

        let name = url.deletingPathExtension().lastPathComponent
        let thumbnail = thumbnailURL(for: url, basePath: basePath)

        items.append(
          WallpaperItem(
            fullImageURL: url,
            thumbnailURL: thumbnail,
            name: name
          ))
      }
    }

    return items.sorted { $0.name < $1.name }
  }

  private func thumbnailURL(for wallpaper: URL, basePath: String) -> URL? {
    let thumbnailDir = URL(fileURLWithPath: basePath)
      .appendingPathComponent(".thumbnails")
    let thumbnailFile =
      thumbnailDir
      .appendingPathComponent(wallpaper.deletingPathExtension().lastPathComponent)
      .appendingPathExtension("heic")

    return FileManager.default.fileExists(atPath: thumbnailFile.path)
      ? thumbnailFile
      : nil
  }

  /// Fallback: Request user to manually grant access via NSOpenPanel
  @MainActor
  func requestUserAccess() async -> [URL]? {
    let panel = NSOpenPanel()
    panel.message = "Select the Desktop Pictures folder to grant access"
    panel.prompt = "Grant Access"
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.directoryURL = URL(fileURLWithPath: "/System/Library/Desktop Pictures")

    let response = await panel.begin()
    guard response == .OK, let url = panel.url else { return nil }

    // Enumerate user-selected directory
    let items = enumerateUserSelectedDirectory(url)
    if !items.isEmpty {
      systemWallpapers = items
      accessDenied = false
    }
    return items.isEmpty ? nil : [url]
  }

  private func enumerateUserSelectedDirectory(_ directoryURL: URL) -> [WallpaperItem] {
    var items: [WallpaperItem] = []
    let fm = FileManager.default

    guard
      let contents = try? fm.contentsOfDirectory(
        at: directoryURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    else { return [] }

    for url in contents {
      let ext = url.pathExtension.lowercased()
      guard supportedExtensions.contains(ext) else { continue }

      let name = url.deletingPathExtension().lastPathComponent
      let thumbnail = thumbnailURL(for: url, basePath: directoryURL.path)

      items.append(
        WallpaperItem(
          fullImageURL: url,
          thumbnailURL: thumbnail,
          name: name
        ))
    }

    return items.sorted { $0.name < $1.name }
  }
}
