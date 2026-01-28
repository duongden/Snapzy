# Research: ScreenCaptureKit & AppKit Optimization

## 1. SCShareableContent Pre-fetching & Caching
* **Latency Issues**: `SCShareableContent.getWithCompletionHandler` is an asynchronous IPC call that can take 30ms to 6s depending on system load and disk space [[4](https://stackoverflow.com/questions/75817351/scshareablecontent-getwithcompletionhandler-takes-a-very-long-time)].
* **Strategy**:
    * **Pre-fetch**: Trigger an initial fetch during app launch or when the menu is opened.
    * **Cache**: Maintain a local cache of `SCDisplay` and `SCWindow` objects.
    * **Invalidation**: Use a `Timer` or `NSWorkspace` notifications to refresh the cache every 5-10 seconds only when the app is active.

## 2. NSWindow Performance Optimization
* **Window Level**: Use `.screenSaver` or `.statusBar` to ensure the capture overlay is always on top.
* **Backing & Shadows**:
    * Disable `hasShadow` for the overlay window to reduce window server compositing overhead.
    * Avoid `backgroundColor = .clear`. Use a slightly opaque background (0.01) or `NSVisualEffectView` to ensure the window remains "hittable" for mouse events without the performance hit of a full clear-layer compositor [[3](https://stackoverflow.com/questions/59823611/nswindow-with-clear-background-not-receiving-mouse-events)].
* **Optimization**: Set `ignoresMouseEvents = false` only on the specific areas (like the crop rect) to allow system-level event passthrough where possible.

## 3. CALayer vs SwiftUI Rendering
* **CALayer**: Hardware-accelerated and lightweight. Ideal for "crosshair" lines, magnifiers, and coordinate labels that update at 60fps+.
    * Use `shouldRasterize = true` for static grid elements.
    * Use `drawsAsynchronously = true` for high-frequency updates [[1](https://medium.com/@alessandromanrossi/calayer-performance-optimization-tips-and-tricks-5e3e8f8e7f1e)].
* **SwiftUI**: Higher overhead due to the diffing engine. If using SwiftUI, wrap the selection logic in a `Canvas` for immediate mode drawing to bypass view hierarchy overhead.

## 4. Main vs Background Threading
* **Capture Init**: SCKit session establishment is heavy. Always initialize on a dedicated background `DispatchQueue`.
* **Sample Handling**: `SCStreamOutput` delegates provide samples on a background queue. Keep processing (cropping/filtering) on this queue; only dispatch to main for final UI updates.
* **Avoidance**: Never call `getWithCompletionHandler` on the main thread; it will cause "Beachballing" if the system IPC is delayed [[2](https://medium.com/@alessandromanrossi/ios-concurrency-performance-optimization-a-practical-guide-75058866184a)].

## 5. Common Performance Bottlenecks
* **Double Rendering**: Systems must render the desktop and the capture buffer simultaneously, doubling GPU load [[1](https://quora.com/Why-does-screen-recording-software-slow-down-the-computer)].
* **Sonoma Regressions**: macOS 14 has reported "rendering lag" in Window Capture mode specifically [[2](https://github.com/obsproject/obs-studio/issues/9638)].
* **Floating Thumbnails**: The system-level "floating thumbnail" after capture adds ~500ms of delay before the file is accessible.
* **Resolution**: Capturing at full Retina resolution (5K+) without downscaling is the most common cause of frame drops.

## Sources
- [[1] Medium: CALayer Performance Tips](https://medium.com/@alessandromanrossi/calayer-performance-optimization-tips-and-tricks-5e3e8f8e7f1e)
- [[2] Medium: iOS/macOS Concurrency Guide](https://medium.com/@alessandromanrossi/ios-concurrency-performance-optimization-a-practical-guide-75058866184a)
- [[3] StackOverflow: NSWindow Transparency & Events](https://stackoverflow.com/questions/59823611/nswindow-with-clear-background-not-receiving-mouse-events)
- [[4] StackOverflow: SCShareableContent Latency](https://stackoverflow.com/questions/75817351/scshareablecontent-getwithcompletionhandler-takes-a-very-long-time)
- [[5] OBS GitHub: macOS Sonoma SCKit Issues](https://github.com/obsproject/obs-studio/issues/9638)
