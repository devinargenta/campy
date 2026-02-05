import AVFoundation
import KeyboardShortcuts
import SwiftUI

/// Global keyboard shortcut names used by the app.
///
/// - Note: Defaults are set here so users get a sensible initial mapping,
///   but they can still customize them in System Settings.
extension KeyboardShortcuts.Name {
    /// Toggles the visibility of the camera window.
    ///
    /// Default: Command–Option–K
    static let toggleView = Self("toggleView", default: .init(.k, modifiers: [.command, .option]))

    /// Triggers a screenshot capture (handled inside `CameraView`).
    ///
    /// Default: Command–Option–P
    static let screenshot = Self("screenshot", default: .init(.p, modifiers: [.command, .option]))
}

/// The main application entry point.
///
/// This app is a lightweight menu bar utility that shows a small camera preview window
/// under the status bar item on demand. It uses a shared `Camera` model and hosts
/// a SwiftUI `CameraView` inside a frameless utility window.
@main
struct CamBar: App {
    /// Bridges lifecycle events to an `NSApplicationDelegate` for status bar control
    /// and window coordination.
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate

    /// No default scenes are created. All UI is driven by the delegate via a status bar item.
    var body: some Scene {}
}

/// Application delegate coordinating the status bar item, camera model, and window.
///
/// Responsibilities:
/// - Creates and owns a single `Camera` instance shared with the SwiftUI `CameraView`.
/// - Manages a `StatusBarController` to place an icon in the menu bar and handle clicks.
/// - Builds a `CameraWindowController` that hosts the SwiftUI content.
/// - Registers global keyboard shortcuts for toggling the window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    /// Shared camera model backing the SwiftUI view and capture session.
    private let camera = Camera()

    /// Manages the NSStatusItem and click handling.
    private var statusBarController: StatusBarController!

    /// Hosts the SwiftUI camera UI inside a small utility window.
    private var windowController: CameraWindowController!

    /// The SwiftUI view bound to the shared `Camera` model.
    private var cameraView: CameraView!

    /// Called by the system when the app has finished launching and is ready to run.
    ///
    /// This method performs all one-time startup wiring for the app:
    /// - Creates the status bar controller with the menu bar icon and assigns a click handler
    ///   that toggles the camera window.
    /// - Instantiates the `CameraView` bound to the shared `Camera` model.
    /// - Builds the `CameraWindowController` that hosts the camera view content.
    /// - Registers a global keyboard shortcut handler for `KeyboardShortcuts.Name.toggleView`
    ///   to toggle the camera window on key up.
    ///
    /// Behavior:
    /// - The status bar button and the keyboard shortcut both invoke the same `toggleWindow()`
    ///   flow, which shows or hides the window and, in turn, toggles the camera on or off.
    /// - Captures `self` explicitly via `[self]` capture list to make intent clear and avoid
    ///   accidental strong reference cycles elsewhere.
    ///
    /// - Parameter notification: The launch notification supplied by `NSApplication`.
    /// - SeeAlso: `NSApplicationDelegate.applicationDidFinishLaunching(_:)`, `toggleWindow()`,
    ///            `StatusBarController`, `CameraWindowController`, `KeyboardShortcuts.onKeyUp(for:)`.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build controllers
        statusBarController = StatusBarController(
            imageName: "MenuIcon",
            onClick: { [self] in
                toggleWindow()
            }
        )

        // Build the SwiftUI camera view bound to the shared camera model.
        cameraView = CameraView(camera: camera)

        // Host the SwiftUI view in a small, frameless utility window aligned to the status bar.
        windowController = CameraWindowController(
            title: "Cambar",
            content: {
                return self.cameraView
            }
        )

        // Register global shortcut to toggle the window on key up.
        KeyboardShortcuts.onKeyUp(for: .toggleView) { [self] in
            toggleWindow()
        }
    }

    // MARK: - Actions

    /// Shows or hides the camera window and starts/stops the camera session accordingly.
    ///
    /// - Note: The camera is only running while the window is visible. This helps conserve
    ///   resources and avoids using the camera when not needed.
    @MainActor private func toggleWindow() {
        windowController.toggleUnder(statusBarButton: statusBarController.button)

        let viz = windowController.isVisible

        if viz {
            // Ensure the capture session is started if the window is visible.
            self.camera.toggle(desired: .on)
        } else {
            // Stop the capture session when the window is hidden.
            self.camera.toggle(desired: .off)
        }
    }
}
