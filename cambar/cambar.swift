import AVFoundation
import SwiftUI

@main
struct CamBar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {}
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private let camera = Camera()

    private var statusBarController: StatusBarController!
    private var windowController: CameraWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build controllers

        statusBarController = StatusBarController(
            imageName: "MenuIcon",
            onClick: { [self] in
                toggleWindow()
            }
        )

        windowController = CameraWindowController(
            title: "Cambar",
            content: { [self] in
                // Provide ContentView with actions for context menu
                return CameraView(camera: self.camera)
            }
        )
    }

    // MARK: - Actions
    @MainActor private func toggleWindow() {
        windowController.toggleUnder(statusBarButton: statusBarController.button)

        let viz = windowController.isVisible

        if viz {
            self.camera.toggle(desired: .on)
        } else {
            self.camera.toggle(desired: .off)
        }
    }
}
