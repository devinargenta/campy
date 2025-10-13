import AVFoundation
import SwiftUI

@main
struct CamBar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private let camera = Camera()

    private var statusBarController: StatusBarController!
    private var windowController: CameraWindowController!
    

    // MARK: - NSApplicationDelegate
    @MainActor fileprivate func getWindowController() -> CameraWindowController {
        return CameraWindowController(
            title: "Cambar",
            content: { [weak self] in
                guard let self else { return AnyView(EmptyView()) }
                // Provide ContentView with actions for context menu
                return AnyView(
                    CameraView(camera: self.camera)
                        .contextMenu {
                            Text("Double tap to screenshot (copied to clipboard)")
                            Button("Refresh Connection / Retry") { [weak self] in
                                guard let self else { return }
                                // Safely reconfigure
                                self.camera.toggle(desired: .off)
                                // Only turn on if the window is visible
                                if self.windowController.isVisible {
                                    self.camera.toggle(desired: .on)
                                }
                            }
                            Button("Quit", action: { NSApp.terminate(nil) })
                        }
                )
            }
        )
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build controllers

        statusBarController = StatusBarController(
            imageName: "MenuIcon",
            onClick: { [weak self] in
                self?.toggleWindow()
            }
        )

        windowController = getWindowController()
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
