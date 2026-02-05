import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onClick: () -> Void
    // Simple throttle to avoid rapid repeated toggles
    private var isThrottling = false
    private let throttleInterval: Duration = .milliseconds(500)

    var button: NSStatusBarButton? { statusItem.button }

    init(imageName: String, onClick: @escaping () -> Void) {
        self.onClick = onClick
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // Prefer asset by name; if not found, keep it nil rather than crashing
            let image = NSImage(named: imageName)!
            image.isTemplate = true
            button.image = image
            button.toolTip = "Show/Hide Cambar"
            button.target = self
            button.action = #selector(handleClick)
            button.ignoresMultiClick = true
            button.keyEquivalent = "."
        }

    }

    @objc func handleClick() {
        guard !isThrottling else { return }
        isThrottling = true
        onClick()

        Task { [self] in
            // Sleep without blocking the main thread
            try? await Task.sleep(for: self.throttleInterval)
            self.endThrottle()
        }
    }

    private func endThrottle() {
        isThrottling = false
    }
}
