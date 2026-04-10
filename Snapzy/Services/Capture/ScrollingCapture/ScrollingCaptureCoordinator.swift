//
//  ScrollingCaptureCoordinator.swift
//  Snapzy
//
//  Phase-01 coordinator for guided scrolling capture sessions.
//

import AppKit
import Foundation

@MainActor
final class ScrollingCaptureCoordinator {
  static let shared = ScrollingCaptureCoordinator()

  private let captureManager = ScreenCaptureManager.shared
  private let maxOutputHeight = ScrollingCaptureFeature.maxOutputHeight
  private let liveRefreshIntervalNanoseconds: UInt64 = 50_000_000
  private let defaultMinimumRefreshSpacing: TimeInterval = 0.09
  private let fastMinimumRefreshSpacing: TimeInterval = 0.06
  private let defaultScrollSettleDelay: TimeInterval = 0.05
  private let fastScrollSettleDelay: TimeInterval = 0.03
  private let scrollIdleTimeout: TimeInterval = 0.28
  private let defaultMinimumPendingScrollPoints: CGFloat = 10
  private let fastMinimumPendingScrollPoints: CGFloat = 8
  private let defaultForcedRefreshScrollPoints: CGFloat = 42
  private let fastForcedRefreshScrollPoints: CGFloat = 28
  private let autoScrollCaptureDelayNanoseconds: UInt64 = 95_000_000
  private let scrollHitSlop: CGFloat = 32
  private let processingQueue = DispatchQueue(
    label: "com.snapzy.scrolling-capture.processing",
    qos: .userInitiated
  )

  private var sessionModel: ScrollingCaptureSessionModel?
  private var hudWindow: ScrollingCaptureHUDWindow?
  private var previewWindow: ScrollingCapturePreviewWindow?
  private var regionOverlayWindows: [RecordingRegionOverlayWindow] = []
  private var latestImage: CGImage?
  private var stitcher: ScrollingCaptureStitcher?
  private var autoScrollEngine: ScrollingCaptureAutoScrollEngine?
  private var selectedRect: CGRect?
  private var saveDirectory: URL?
  private var format: ImageFormat = .png
  private var prefetchedContentTask: ShareableContentPrefetchTask?
  private var scrollMonitor: Any?
  private var pendingRefreshTask: Task<Void, Never>?
  private var autoScrollTask: Task<Void, Never>?
  private var prepareCaptureContextTask: Task<Void, Never>?
  private var preparedCaptureContext: ScreenCaptureManager.PreparedAreaCaptureContext?
  private var captureScaleFactor: CGFloat = 2
  private var pendingScrollDistancePoints: CGFloat = 0
  private var pendingScrollDirection: Int?
  private var pendingMixedDirections = false
  private var lockedScrollDirection: Int?
  private var lastScrollEventTime: TimeInterval?
  private var lastRefreshTime: TimeInterval?
  private var lastAcceptedDeltaPixels: Int?
  private var isRefreshingPreview = false
  private var sessionGeneration = 0
  private var autoScrollStepPoints: CGFloat = 0
  private var autoScrollConsecutiveFailures = 0
  private var autoScrollConsecutiveNoMovement = 0

  var isActive: Bool {
    sessionModel != nil
  }

  func beginSession(
    rect: CGRect,
    saveDirectory: URL,
    format: ImageFormat,
    prefetchedContentTask: ShareableContentPrefetchTask?
  ) {
    cancel()
    sessionGeneration += 1

    let model = ScrollingCaptureSessionModel(selectedRect: rect)
    self.sessionModel = model
    self.selectedRect = rect
    self.saveDirectory = saveDirectory
    self.format = format
    self.prefetchedContentTask = prefetchedContentTask
    self.captureScaleFactor = scaleFactor(for: rect)
    self.pendingScrollDistancePoints = 0
    self.pendingScrollDirection = nil
    self.pendingMixedDirections = false
    self.lockedScrollDirection = nil
    self.lastScrollEventTime = nil
    self.lastRefreshTime = nil
    self.lastAcceptedDeltaPixels = nil
    self.isRefreshingPreview = false
    self.preparedCaptureContext = nil
    self.prepareCaptureContextTask = nil
    self.autoScrollEngine = nil
    self.autoScrollTask = nil
    self.autoScrollStepPoints = 0
    self.autoScrollConsecutiveFailures = 0
    self.autoScrollConsecutiveNoMovement = 0

    showRegionOverlay(for: rect)
    hudWindow = ScrollingCaptureHUDWindow(
      anchorRect: rect,
      model: model,
      onStart: { [weak self] in self?.startCapture() },
      onDone: { [weak self] in self?.finish() },
      onCancel: { [weak self] in self?.cancel() }
    )
    previewWindow = ScrollingCapturePreviewWindow(anchorRect: rect, model: model)

    hudWindow?.orderFrontRegardless()
    previewWindow?.orderFrontRegardless()
    prewarmCaptureContext(for: rect)
    prepareAutoScrollEngineIfNeeded(for: rect, model: model)

    if ScrollingCaptureFeature.showHints {
      AppToastManager.shared.show(
        message: "Select only the moving content, press Start Capture, then let Snapzy auto-scroll when possible or keep scrolling naturally.",
        style: .info,
        position: .topCenter
      )
    }

    DiagnosticLogger.shared.log(
      .info,
      .capture,
      "Scrolling capture session ready",
      context: ["rect": "\(Int(rect.width))x\(Int(rect.height))"]
    )
  }

  func cancel() {
    sessionGeneration += 1
    pendingRefreshTask?.cancel()
    pendingRefreshTask = nil
    autoScrollTask?.cancel()
    autoScrollTask = nil
    prepareCaptureContextTask?.cancel()
    prepareCaptureContextTask = nil

    if let scrollMonitor {
      NSEvent.removeMonitor(scrollMonitor)
      self.scrollMonitor = nil
    }

    for overlay in regionOverlayWindows {
      overlay.close()
    }
    regionOverlayWindows.removeAll()
    hudWindow?.orderOut(nil)
    previewWindow?.orderOut(nil)
    hudWindow = nil
    previewWindow = nil
    sessionModel = nil
    latestImage = nil
    stitcher = nil
    selectedRect = nil
    saveDirectory = nil
    prefetchedContentTask = nil
    preparedCaptureContext = nil
    pendingScrollDistancePoints = 0
    pendingScrollDirection = nil
    pendingMixedDirections = false
    lockedScrollDirection = nil
    lastScrollEventTime = nil
    lastRefreshTime = nil
    lastAcceptedDeltaPixels = nil
    isRefreshingPreview = false
    autoScrollEngine?.invalidate()
    autoScrollEngine = nil
    autoScrollStepPoints = 0
    autoScrollConsecutiveFailures = 0
    autoScrollConsecutiveNoMovement = 0
  }

  private func startCapture() {
    guard let sessionModel else { return }
    guard sessionModel.phase == .ready else { return }

    if let selectedRect {
      prepareAutoScrollEngineIfNeeded(for: selectedRect, model: sessionModel)
    }

    setRegionOverlayInteractionEnabled(false)
    sessionModel.phase = .capturing
    sessionModel.statusText = sessionModel.autoScrollEnabled && autoScrollEngine != nil
      ? "Capturing the first frame. After that, Snapzy will auto-scroll the target surface."
      : "Capturing the first frame. After that, keep scrolling downward at a steady pace."
    installScrollMonitorIfNeeded()

    Task { @MainActor in
      let initialUpdate = await refreshPreview(reason: "Initial frame captured")
      if case .initialized? = initialUpdate?.outcome {
        startAutoScrollIfNeeded()
      }
    }
  }

  private func finish() {
    guard let sessionModel else { return }

    stopAutoScrollLoop()
    pendingRefreshTask?.cancel()
    pendingRefreshTask = nil

    Task { @MainActor in
      await waitForPendingPreviewRefresh()

      if abs(pendingScrollDistancePoints) > 2 {
        _ = await refreshPreview(reason: "Final visible frame captured before save")
      }

      if latestImage == nil {
        _ = await refreshPreview(reason: "Current frame captured before save")
      }

      guard let latestImage, let saveDirectory else {
        AppToastManager.shared.show(message: "No stitched frame is ready yet.", style: .warning)
        return
      }

      sessionModel.phase = .saving
      sessionModel.statusText = "Saving the stitched long image."

      let result = await captureManager.saveProcessedImage(
        latestImage,
        to: saveDirectory,
        format: format
      )

      switch result {
      case .success:
        SoundManager.playScreenshotCapture()
        AppToastManager.shared.show(
          message: "Scrolling Capture experimental: saved the stitched image.",
          style: .info
        )
        cancel()
      case .failure(let error):
        sessionModel.phase = .capturing
        sessionModel.statusText = "Save failed. You can try Done again."
        AppToastManager.shared.show(message: error.localizedDescription, style: .error)
      }
    }
  }

  private func installScrollMonitorIfNeeded() {
    guard scrollMonitor == nil else { return }

    scrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
      DispatchQueue.main.async {
        self?.handleScrollEvent(event)
      }
    }
  }

  private func handleScrollEvent(_ event: NSEvent) {
    guard let selectedRect, let sessionModel else { return }
    guard sessionModel.phase == .capturing else { return }
    guard autoScrollTask == nil else { return }
    guard abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX) else { return }
    guard selectedRect.insetBy(dx: -scrollHitSlop, dy: -scrollHitSlop).contains(NSEvent.mouseLocation) else {
      return
    }

    let multiplier: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 18
    let deltaY = CGFloat(event.scrollingDeltaY) * multiplier
    guard abs(deltaY) > 0.5 else { return }

    let direction = deltaY > 0 ? 1 : -1
    if let lockedScrollDirection, direction != lockedScrollDirection {
      sessionModel.statusText = "Direction changed. Keep scrolling the same way or restart the session."
      pendingRefreshTask?.cancel()
      pendingRefreshTask = nil
      pendingScrollDistancePoints = 0
      pendingScrollDirection = nil
      pendingMixedDirections = false
      return
    }

    if let pendingScrollDirection, pendingScrollDirection != direction {
      pendingMixedDirections = true
    } else {
      pendingScrollDirection = direction
    }

    pendingScrollDistancePoints += deltaY
    lastScrollEventTime = ProcessInfo.processInfo.systemUptime

    sessionModel.statusText = "Capturing and aligning the latest visible content..."
    startLiveRefreshLoopIfNeeded()
  }

  private func refreshPreview(
    reason: String,
    expectedSignedDeltaPixelsOverride: Int? = nil
  ) async -> ScrollingCaptureStitchUpdate? {
    let generation = sessionGeneration
    guard let sessionModel else { return nil }
    guard !isRefreshingPreview else { return nil }

    isRefreshingPreview = true
    defer {
      isRefreshingPreview = false
      if generation == sessionGeneration {
        lastRefreshTime = ProcessInfo.processInfo.systemUptime
      }
    }

    do {
      let expectedSignedDeltaPixels: Int?
      let batchScrollDirection = pendingScrollDirection
      let hadMixedDirections = pendingMixedDirections
      if let expectedSignedDeltaPixelsOverride {
        expectedSignedDeltaPixels = expectedSignedDeltaPixelsOverride
      } else if abs(pendingScrollDistancePoints) > 2 {
        expectedSignedDeltaPixels = normalizedExpectedDeltaPixels(
          from: Int(round(pendingScrollDistancePoints * captureScaleFactor))
        )
      } else {
        expectedSignedDeltaPixels = nil
      }
      pendingScrollDistancePoints = 0
      pendingScrollDirection = nil
      pendingMixedDirections = false

      if hadMixedDirections {
        sessionModel.statusText = "Mixed scroll directions detected. Keep one direction so Snapzy can align."
        return nil
      }

      guard let capturedImage = try await capturePreparedAreaForSession() else {
        sessionModel.statusText = "Unable to capture the selected area."
        return nil
      }
      guard generation == sessionGeneration, self.sessionModel != nil else { return nil }

      let (update, processedStitcher) = await stitchCapturedImage(
        capturedImage,
        expectedSignedDeltaPixels: expectedSignedDeltaPixels
      )
      guard generation == sessionGeneration, let sessionModel = self.sessionModel else { return nil }
      if let processedStitcher {
        self.stitcher = processedStitcher
      }

      guard let update, let mergedImage = update.mergedImage else {
        sessionModel.statusText = "Unable to render the stitched preview."
        return nil
      }

      latestImage = mergedImage
      if
        case .appended = update.outcome,
        lockedScrollDirection == nil,
        update.mergeDirection != .unresolved,
        let batchScrollDirection
      {
        lockedScrollDirection = batchScrollDirection
      }
      sessionModel.previewImage = NSImage(
        cgImage: mergedImage,
        size: NSSize(width: mergedImage.width, height: mergedImage.height)
      )
      sessionModel.acceptedFrameCount = update.acceptedFrameCount
      sessionModel.stitchedPixelHeight = update.outputHeight

      switch update.outcome {
      case .initialized:
        lastAcceptedDeltaPixels = nil
        sessionModel.previewCaption = reason
        sessionModel.statusText =
          "First frame locked. Keep the pointer over the highlighted region and scroll downward steadily."
      case .appended(let deltaY):
        lastAcceptedDeltaPixels = deltaY
        sessionModel.previewCaption =
          "\(update.acceptedFrameCount) frames stitched • +\(deltaY) px"
        sessionModel.statusText =
          "Session active. \(update.acceptedFrameCount) frames stitched into \(update.outputHeight) px."
      case .ignoredNoMovement:
        sessionModel.statusText = "Waiting for new content. Keep the scroll moving in one direction."
      case .ignoredAlignmentFailed:
        if update.matchFailureCount >= 2 {
          sessionModel.statusText = "Alignment paused. Slow down and keep one direction so Snapzy can recover."
        } else {
          sessionModel.statusText = "Couldn't align that frame. Keep the same direction and a steadier pace."
        }
      case .reachedHeightLimit:
        sessionModel.previewCaption = "\(update.acceptedFrameCount) frames stitched • height limit reached"
        sessionModel.statusText =
          "Reached the \(maxOutputHeight) px output limit. Press Done to save the current result."
      }
      return update
    } catch {
      DiagnosticLogger.shared.log(
        .error,
        .capture,
        "Scrolling capture preview refresh failed",
        context: ["error": error.localizedDescription]
      )
        sessionModel.statusText = "Preview refresh failed. You can Cancel and try again."
      return nil
    }
  }

  private func showRegionOverlay(for rect: CGRect) {
    for overlay in regionOverlayWindows {
      overlay.close()
    }
    regionOverlayWindows.removeAll()

    for screen in NSScreen.screens {
      let overlay = RecordingRegionOverlayWindow(screen: screen, highlightRect: rect)
      overlay.interactionDelegate = self
      overlay.setInteractionEnabled(true)
      overlay.orderFrontRegardless()
      regionOverlayWindows.append(overlay)
    }
  }

  private func setRegionOverlayInteractionEnabled(_ enabled: Bool) {
    for overlay in regionOverlayWindows {
      overlay.setInteractionEnabled(enabled)
    }
  }

  private func updateSelectedRect(_ rect: CGRect, reprepareSession: Bool) {
    let normalizedRect = rect.standardized
    selectedRect = normalizedRect
    sessionModel?.selectedRect = normalizedRect
    captureScaleFactor = scaleFactor(for: normalizedRect)

    for overlay in regionOverlayWindows {
      overlay.updateHighlightRect(normalizedRect)
    }
    hudWindow?.updateAnchorRect(normalizedRect)
    previewWindow?.updateAnchorRect(normalizedRect)

    if reprepareSession {
      refreshSelectionPreparation()
    }
  }

  private func refreshSelectionPreparation() {
    guard let selectedRect, let sessionModel, sessionModel.phase == .ready else { return }

    preparedCaptureContext = nil
    prepareCaptureContextTask?.cancel()
    prepareCaptureContextTask = nil
    latestImage = nil
    stitcher = nil
    lastAcceptedDeltaPixels = nil
    autoScrollStepPoints = 0
    autoScrollConsecutiveFailures = 0
    autoScrollConsecutiveNoMovement = 0
    sessionModel.previewImage = nil
    sessionModel.previewCaption = "Start Capture to lock the first frame"
    sessionModel.acceptedFrameCount = 0
    sessionModel.stitchedPixelHeight = 0
    sessionModel.statusText =
      "Adjust the region so only the moving content stays inside, then press Start Capture."

    prewarmCaptureContext(for: selectedRect)
    prepareAutoScrollEngineIfNeeded(for: selectedRect, model: sessionModel)
  }

  private func prewarmCaptureContext(for rect: CGRect) {
    prepareCaptureContextTask?.cancel()
    prepareCaptureContextTask = Task { @MainActor [weak self] in
      guard let self else { return }

      do {
        let context = try await self.captureManager.prepareAreaCapture(
          rect: rect,
          excludeDesktopIcons: DesktopIconManager.shared.isIconHidingEnabled,
          excludeDesktopWidgets: DesktopIconManager.shared.isWidgetHidingEnabled,
          excludeOwnApplication: true,
          prefetchedContentTask: self.prefetchedContentTask
        )

        guard !Task.isCancelled else { return }
        self.preparedCaptureContext = context
        self.captureScaleFactor = context.scaleFactor
      } catch {
        if error is CancellationError { return }
        DiagnosticLogger.shared.log(
          .warning,
          .capture,
          "Scrolling capture prewarm failed",
          context: ["error": error.localizedDescription]
        )
      }
    }
  }

  private func ensurePreparedCaptureContext() async throws -> ScreenCaptureManager.PreparedAreaCaptureContext {
    if let preparedCaptureContext {
      return preparedCaptureContext
    }

    if let prepareCaptureContextTask {
      await prepareCaptureContextTask.value
      self.prepareCaptureContextTask = nil
      if let preparedCaptureContext {
        return preparedCaptureContext
      }
    }

    guard let selectedRect else {
      throw CaptureError.cancelled
    }

    let context = try await captureManager.prepareAreaCapture(
      rect: selectedRect,
      excludeDesktopIcons: DesktopIconManager.shared.isIconHidingEnabled,
      excludeDesktopWidgets: DesktopIconManager.shared.isWidgetHidingEnabled,
      excludeOwnApplication: true,
      prefetchedContentTask: prefetchedContentTask
    )
    preparedCaptureContext = context
    captureScaleFactor = context.scaleFactor
    return context
  }

  private func capturePreparedAreaForSession() async throws -> CGImage? {
    do {
      let context = try await ensurePreparedCaptureContext()
      return try await captureManager.capturePreparedArea(context)
    } catch {
      preparedCaptureContext = nil
      prepareCaptureContextTask?.cancel()
      prepareCaptureContextTask = nil
      throw error
    }
  }

  private func startLiveRefreshLoopIfNeeded() {
    guard pendingRefreshTask == nil else { return }

    pendingRefreshTask = Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.pendingRefreshTask = nil }

      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: self.liveRefreshIntervalNanoseconds)
        if Task.isCancelled { return }
        guard let sessionModel = self.sessionModel, sessionModel.phase == .capturing else { return }

        let now = ProcessInfo.processInfo.systemUptime
        let idleDuration = self.lastScrollEventTime.map { now - $0 } ?? .greatestFiniteMagnitude
        let pendingDistance = abs(self.pendingScrollDistancePoints)
        let hasPendingMotion = pendingDistance > 2
        let hasEnoughSettledMotion = pendingDistance >= self.minimumPendingScrollPoints()
          && idleDuration >= self.scrollSettleDelay()
        let shouldRefresh = hasPendingMotion
          && (hasEnoughSettledMotion || pendingDistance >= self.forcedRefreshScrollPoints())
          && self.canStartRefresh(at: now)

        if shouldRefresh {
          _ = await self.refreshPreview(reason: "Live stitched preview")
          continue
        }

        if idleDuration >= self.scrollIdleTimeout {
          if hasPendingMotion && self.canStartRefresh(at: now) {
            _ = await self.refreshPreview(reason: "Latest visible frame")
          }
          return
        }
      }
    }
  }

  private func canStartRefresh(at now: TimeInterval) -> Bool {
    guard !isRefreshingPreview else { return false }
    guard let lastRefreshTime else { return true }
    return now - lastRefreshTime >= minimumRefreshSpacing()
  }

  private func prepareAutoScrollEngineIfNeeded(
    for rect: CGRect,
    model: ScrollingCaptureSessionModel
  ) {
    model.autoScrollAvailable = AXIsProcessTrusted()

    guard model.autoScrollEnabled else {
      autoScrollEngine?.invalidate()
      autoScrollEngine = nil
      model.autoScrollStatusText = model.autoScrollAvailable
        ? "Auto-scroll is off for this session."
        : "Auto-scroll needs Accessibility permission."
      return
    }

    guard model.autoScrollAvailable else {
      autoScrollEngine?.invalidate()
      autoScrollEngine = nil
      model.autoScrollStatusText = "Auto-scroll needs Accessibility permission."
      return
    }

    let engine = ScrollingCaptureAutoScrollEngine(selectionRect: rect)
    switch engine.prepare() {
    case .ready(let description):
      model.autoScrollAvailable = true
      autoScrollEngine = engine
      autoScrollStepPoints = initialAutoScrollStepPoints()
      autoScrollConsecutiveFailures = 0
      autoScrollConsecutiveNoMovement = 0
      model.autoScrollStatusText = description
    case .unavailablePermission(let description), .noScrollableTarget(let description):
      model.autoScrollAvailable = AXIsProcessTrusted()
      autoScrollEngine = nil
      model.autoScrollStatusText = description
    }
  }

  private func startAutoScrollIfNeeded() {
    guard autoScrollTask == nil else { return }
    guard let autoScrollEngine, let sessionModel else { return }
    guard sessionModel.phase == .capturing, sessionModel.autoScrollEnabled else { return }

    autoScrollStepPoints = max(autoScrollStepPoints, initialAutoScrollStepPoints())
    autoScrollConsecutiveFailures = 0
    autoScrollConsecutiveNoMovement = 0
    sessionModel.isAutoScrolling = true
    sessionModel.autoScrollStatusText = "Auto-scroll running with \(autoScrollEngine.targetDescription.lowercased())."

    autoScrollTask = Task { @MainActor [weak self] in
      guard let self else { return }
      await self.runAutoScrollLoop()
    }
  }

  private func stopAutoScrollLoop() {
    autoScrollTask?.cancel()
    autoScrollTask = nil
    sessionModel?.isAutoScrolling = false
  }

  private func runAutoScrollLoop() async {
    defer {
      autoScrollTask = nil
      if let sessionModel, sessionModel.phase == .capturing {
        sessionModel.isAutoScrolling = false
        if sessionModel.autoScrollEnabled {
          sessionModel.autoScrollStatusText = autoScrollEngine?.targetDescription
            ?? "Auto-scroll is ready when a supported target is found."
        }
      }
    }

    guard let autoScrollEngine else { return }

    while !Task.isCancelled {
      guard let sessionModel = self.sessionModel, sessionModel.phase == .capturing else { return }

      let requestedStepPoints = min(max(autoScrollStepPoints, 28), maxAutoScrollStepPoints())
      let stepOutcome = await autoScrollEngine.performStep(points: requestedStepPoints)
      if Task.isCancelled { return }

      switch stepOutcome {
      case .failed(let description):
        sessionModel.statusText = "\(description) Continue scrolling manually or press Done."
        return
      case .blocked(let description):
        autoScrollConsecutiveNoMovement += 1
        if autoScrollConsecutiveNoMovement == 1 {
          autoScrollEngine.flipWheelDirectionHint()
        }
        autoScrollStepPoints = min(maxAutoScrollStepPoints(), requestedStepPoints * 1.18)
        if autoScrollConsecutiveNoMovement >= 3 {
          sessionModel.statusText = "\(description) You can continue scrolling manually."
          return
        }
        try? await Task.sleep(nanoseconds: 80_000_000)
        continue
      case .reachedBoundary(let description):
        _ = await refreshPreview(
          reason: "Final auto-scroll frame",
          expectedSignedDeltaPixelsOverride: Int(round(requestedStepPoints * captureScaleFactor))
        )
        sessionModel.statusText = "\(description) Press Done to save the current result."
        sessionModel.autoScrollStatusText = "Reached the end of the scrollable content."
        return
      case .scrolled(let estimatedPoints, let boundaryReached):
        sessionModel.statusText = "Auto-scrolling and stitching the latest visible content..."
        try? await Task.sleep(nanoseconds: autoScrollCaptureDelayNanoseconds)

        let update = await refreshPreview(
          reason: "Auto-scroll preview",
          expectedSignedDeltaPixelsOverride: Int(round(estimatedPoints * captureScaleFactor))
        )

        guard let update else {
          sessionModel.statusText = "Auto-scroll paused because Snapzy couldn't refresh the preview."
          return
        }

        switch update.outcome {
        case .initialized:
          continue
        case .appended(let deltaY):
          autoScrollConsecutiveFailures = 0
          autoScrollConsecutiveNoMovement = 0
          let acceptedPoints = CGFloat(deltaY) / max(captureScaleFactor, 1)
          let blendedStep = acceptedPoints * 0.82 + requestedStepPoints * 0.18
          autoScrollStepPoints = min(maxAutoScrollStepPoints(), max(24, blendedStep))
          sessionModel.autoScrollStatusText =
            "Auto-scroll running • step \(Int(round(autoScrollStepPoints))) pt"

          if boundaryReached {
            sessionModel.statusText = "Auto-scroll reached the end. Press Done to save the current result."
            sessionModel.autoScrollStatusText = "Reached the end of the scrollable content."
            return
          }
        case .ignoredNoMovement:
          autoScrollConsecutiveNoMovement += 1
          autoScrollStepPoints = min(maxAutoScrollStepPoints(), requestedStepPoints * 1.22)
          if autoScrollConsecutiveNoMovement >= 3 {
            sessionModel.statusText = "Auto-scroll no longer sees new content. You can press Done or continue manually."
            return
          }
        case .ignoredAlignmentFailed:
          autoScrollConsecutiveFailures += 1
          autoScrollStepPoints = max(20, requestedStepPoints * 0.72)
          if autoScrollConsecutiveFailures >= 3 {
            sessionModel.statusText =
              "Auto-scroll paused after repeated alignment misses. You can continue manually or press Done."
            return
          }
        case .reachedHeightLimit:
          sessionModel.autoScrollStatusText = "Height limit reached."
          return
        }
      }
    }
  }

  private func waitForPendingPreviewRefresh() async {
    while isRefreshingPreview {
      try? await Task.sleep(nanoseconds: 20_000_000)
    }
  }

  private func normalizedExpectedDeltaPixels(from rawValue: Int) -> Int {
    guard rawValue != 0 else { return 0 }

    let sign = rawValue > 0 ? 1 : -1
    let magnitude = abs(rawValue)
    guard let lastAcceptedDeltaPixels, lastAcceptedDeltaPixels > 0 else {
      return sign * min(max(16, magnitude), 1_600)
    }

    let blendedMagnitude = Int(round(Double(magnitude + lastAcceptedDeltaPixels) / 2.0))
    let lowerBound = max(16, Int(Double(lastAcceptedDeltaPixels) * 0.55))
    let upperBound = max(lowerBound + 28, Int(Double(lastAcceptedDeltaPixels) * 1.85))
    let clampedMagnitude = min(max(lowerBound, blendedMagnitude), upperBound)
    return sign * clampedMagnitude
  }

  private func stitchCapturedImage(
    _ capturedImage: CGImage,
    expectedSignedDeltaPixels: Int?
  ) async -> (ScrollingCaptureStitchUpdate?, ScrollingCaptureStitcher?) {
    let currentStitcher = stitcher
    let maxOutputHeight = maxOutputHeight

    return await withCheckedContinuation { continuation in
      processingQueue.async {
        autoreleasepool {
          if let currentStitcher {
            let update = currentStitcher.append(
              capturedImage,
              maxOutputHeight: maxOutputHeight,
              expectedSignedDeltaPixels: expectedSignedDeltaPixels
            )
            continuation.resume(returning: (update, currentStitcher))
          } else {
            let newStitcher = ScrollingCaptureStitcher()
            let update = newStitcher.start(with: capturedImage)
            continuation.resume(returning: (update, newStitcher))
          }
        }
      }
    }
  }

  private func minimumRefreshSpacing() -> TimeInterval {
    lastAcceptedDeltaPixels == nil ? defaultMinimumRefreshSpacing : fastMinimumRefreshSpacing
  }

  private func scrollSettleDelay() -> TimeInterval {
    lastAcceptedDeltaPixels == nil ? defaultScrollSettleDelay : fastScrollSettleDelay
  }

  private func minimumPendingScrollPoints() -> CGFloat {
    lastAcceptedDeltaPixels == nil ? defaultMinimumPendingScrollPoints : fastMinimumPendingScrollPoints
  }

  private func forcedRefreshScrollPoints() -> CGFloat {
    guard let lastAcceptedDeltaPixels, lastAcceptedDeltaPixels > 0 else {
      return defaultForcedRefreshScrollPoints
    }

    let estimatedPoints = CGFloat(lastAcceptedDeltaPixels) / max(captureScaleFactor, 1)
    let adaptivePoints = estimatedPoints * 0.42
    return min(defaultForcedRefreshScrollPoints, max(fastForcedRefreshScrollPoints, adaptivePoints))
  }

  private func initialAutoScrollStepPoints() -> CGFloat {
    guard let selectedRect else { return 96 }
    return min(maxAutoScrollStepPoints(), max(48, selectedRect.height * 0.24))
  }

  private func maxAutoScrollStepPoints() -> CGFloat {
    guard let selectedRect else { return 180 }
    return max(96, min(240, selectedRect.height * 0.46))
  }

  private func scaleFactor(for rect: CGRect) -> CGFloat {
    let screen = NSScreen.screens.first(where: { $0.frame.intersects(rect) }) ?? NSScreen.main
    return screen?.backingScaleFactor ?? 2
  }
}

extension ScrollingCaptureCoordinator: RecordingRegionOverlayDelegate {
  func overlayDidRequestReselection(_ overlay: RecordingRegionOverlayWindow) {}

  func overlay(_ overlay: RecordingRegionOverlayWindow, didMoveRegionTo rect: CGRect) {
    guard let sessionModel, sessionModel.phase == .ready else { return }
    updateSelectedRect(rect, reprepareSession: false)
    sessionModel.statusText = "Release to lock the updated scrolling region."
  }

  func overlayDidFinishMoving(_ overlay: RecordingRegionOverlayWindow) {
    guard let sessionModel, sessionModel.phase == .ready else { return }
    refreshSelectionPreparation()
    sessionModel.statusText =
      "Region updated. Keep only the moving content inside, then press Start Capture."
  }

  func overlay(_ overlay: RecordingRegionOverlayWindow, didReselectWithRect rect: CGRect) {
    guard let sessionModel, sessionModel.phase == .ready else { return }
    updateSelectedRect(rect, reprepareSession: true)
    sessionModel.statusText =
      "Region updated. Keep only the moving content inside, then press Start Capture."
  }

  func overlay(_ overlay: RecordingRegionOverlayWindow, didResizeRegionTo rect: CGRect) {
    guard let sessionModel, sessionModel.phase == .ready else { return }
    updateSelectedRect(rect, reprepareSession: false)
    sessionModel.statusText = "Release to lock the updated scrolling region."
  }

  func overlayDidFinishResizing(_ overlay: RecordingRegionOverlayWindow) {
    guard let sessionModel, sessionModel.phase == .ready else { return }
    refreshSelectionPreparation()
    sessionModel.statusText =
      "Region updated. Keep only the moving content inside, then press Start Capture."
  }
}
