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
    let altIcon = NSImage(imageLiteralResourceName: "MenuIcon")
    let camera = Camera()
    var cameraWindow: NSWindow!
    var statusItem: NSStatusItem!

    func windowDidChangeOcclusionState(_ notification: Notification) {
        if cameraWindow.isVisible {
            camera.toggle(desired: .on)
        } else {
            camera.toggle(desired: .off)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        icon.isTemplate = true
        setupStatusItem()
        setupCameraWindow()
        camera.createSession()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        statusItem.button?.image = icon
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
   

        
    }
    

    private func setupCameraWindow() {
        let hosting = NSHostingController(
            rootView: ContentView(camera: camera)
                .contextMenu {
                    Text("Double tap to screenshot (copied to clipboard)")
                    Button(
                        "Refresh Connection / Retry",
                        action: { [self] in
                            // Use serialized API to reconfigure safely
                            camera.toggle(desired: .off)
                            camera.createSession()
                            camera.toggle(desired: .on)
                        }
                    )
                    Button("Quit", action: quitApp)
                }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [],
            backing: .buffered,
            defer: true
        )
        window.title = "Cambar"
        window.contentView = hosting.view
        window.animationBehavior = .utilityWindow
        window.delegate = self
        window.isRestorable = true
        window.level = .statusBar
        window.isMovableByWindowBackground = true
        self.cameraWindow = window

    }

    // MARK: - Menu Actions

    @objc func statusItemClicked() {
        toggleWindowVisibility()
    }

    private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Window Management

    func toggleWindowVisibility() {
        // window hasn't been built yet, don't do anything
        if cameraWindow == nil {
            return
        }
        if cameraWindow!.isVisible {
            // window is visible, hide it
            NSApp.deactivate()
            cameraWindow?.orderOut(self)
        } else {
            // window is hidden. Position and show it on top of other windows
            cameraWindow?.orderFront(self)
            positionWindowUnderStatusItem(cameraWindow)
            NSApp.activate()
        }
    }

    func positionWindowUnderStatusItem(_ window: NSWindow) {
        guard let button = statusItem.button, let buttonWindow = button.window
        else { return }
        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.frame)
        let windowWidth = window.frame.width
        let windowHeight = window.frame.height
        let x =
            buttonFrameOnScreen.origin.x
            + (buttonFrameOnScreen.width - windowWidth) / 2
        let y = buttonFrameOnScreen.origin.y - windowHeight
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
