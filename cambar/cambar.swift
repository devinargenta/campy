import AVFoundation
import SwiftUI

@main
struct CamBar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        // Window management is in AppDelegate
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let icon = NSImage(imageLiteralResourceName: "MenuIcon")
    let camera = Camera()
    var cameraWindow: NSWindow!
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        icon.isTemplate = true
        setupStatusItem()
        setupCameraWindow()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = icon
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
    }

    private func setupCameraWindow() {
        let contentView = ContentView(camera: camera)
            .contextMenu {
                Text("Double tap to screenshot (copied to clipboard)")
                Button("Refresh Connection / Retry", action: { [self] in
                    self.camera.captureSession.inputs.forEach(self.camera.captureSession.removeInput)
                    self.camera.captureSession.outputs.forEach(self.camera.captureSession.removeOutput)
                    self.camera.captureSession.stopRunning()
                    self.camera.createSession()
                    self.camera.captureSession.startRunning()
                })
                Button("Quit", action: quitApp)
            }
        let hosting = NSHostingController(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.utilityWindow, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cambar"
        window.contentView = hosting.view
        window.level = .floating
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        self.cameraWindow = window
    }

    // MARK: - Menu Actions

    @objc func statusItemClicked() {
        if cameraWindow.isVisible {
            closeCameraWindow()
        } else {
            camera.createSession()
            showCameraWindow()
        }
    }

    private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Window Management

    func showCameraWindow() {
        camera.toggle(desired: .on)
        cameraWindow.makeKeyAndOrderFront(nil)
        positionWindowUnderStatusItem(cameraWindow)
    }

    func closeCameraWindow() {
        camera.toggle(desired: .off)
        cameraWindow.orderOut(nil)
    }

    func positionWindowUnderStatusItem(_ window: NSWindow) {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.frame)
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let x = buttonFrameOnScreen.origin.x + (buttonFrameOnScreen.width - windowWidth) / 2
        let y = buttonFrameOnScreen.origin.y - windowHeight
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
