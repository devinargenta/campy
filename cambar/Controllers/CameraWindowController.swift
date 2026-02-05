import AppKit
import SwiftUI

@MainActor
final class CameraWindowController: NSObject, NSWindowDelegate {
    private let title: String
    private let contentProvider: () -> CameraView
    private let window: NSWindow

    var isVisible: Bool {
        window.isVisible
    }

    init(
        title: String,
        content: @escaping () -> CameraView
    ) {
        self.title = title
        self.contentProvider = content

        // Build hosting controller and window
        let hosting = NSHostingController(rootView: content())
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        win.title = title
        win.contentView = hosting.view

        win.styleMask = .utilityWindow
        win.backgroundColor = .clear
        win.isRestorable = false
        win.level = .statusBar
        win.isMovableByWindowBackground = true
        win.isReleasedWhenClosed = false

        self.window = win

        super.init()
        self.window.delegate = self
    }

    func hide() {
        window.orderOut(self)
    }

    func toggleUnder(statusBarButton: NSStatusBarButton?) {
        if window.isVisible {
            hide()
        } else {
            window.orderFront(self)
            positionWindowUnderStatusItem(statusBarButton)
        }
    }

    // MARK: - Internals

    private func positionWindowUnderStatusItem(_ statusBarButton: NSStatusBarButton?) {
        guard
            let button = statusBarButton,
            let buttonWindow = button.window
        else { return }

        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.frame)
        let windowSize = window.frame.size

        let screen = buttonWindow.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var x = buttonFrameOnScreen.midX - (windowSize.width / 2.0)
        var y = buttonFrameOnScreen.minY - windowSize.height

        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - windowSize.width))
        if y < visibleFrame.minY {
            y = buttonFrameOnScreen.maxY
        }

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
