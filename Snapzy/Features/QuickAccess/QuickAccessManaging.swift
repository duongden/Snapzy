//
//  QuickAccessManaging.swift
//  Snapzy
//
//  Protocol extracted from QuickAccessManager for DI.
//

import Foundation

@MainActor
protocol QuickAccessManaging {
  func addScreenshot(url: URL) async
  func addVideo(url: URL) async
}

extension QuickAccessManager: QuickAccessManaging {}
