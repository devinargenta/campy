import AVFoundation
import AppKit
import SwiftUI
import Testing

@testable import cambar

@Suite("CameraWindowController")
@MainActor
struct CameraWindowControllerTests {

    private func makeController() -> CameraWindowController {
        CameraWindowController(
            title: "Test Window",
            content: { CameraView(camera: Camera())}
        )
    }

    @Test("initialization builds a hidden utility window with content")
    func init_buildsWindow() {
        // When
        let controller = makeController()

        // Then
        #expect(controller.isVisible == false)
    }

    @Test("toggleUnder toggles visibility without status item")
    func toggleUnder_withoutStatusItem_togglesVisibility() {
        // Given
        let controller = makeController()
        #expect(controller.isVisible == false)

        // When
        controller.toggleUnder(statusBarButton: nil)

        // Then
        #expect(controller.isVisible == true)

        // When
        controller.toggleUnder(statusBarButton: nil)

        // Then
        #expect(controller.isVisible == false)
    }

    @Test("hide makes window not visible")
    func hide_hidesWindow() {
        // Given
        let controller = makeController()

        // Show
        controller.toggleUnder(statusBarButton: nil)
        #expect(controller.isVisible == true)

        // When
        controller.hide()

        // Then
        #expect(controller.isVisible == false)
    }
}

// MARK: - StatusBarController Tests

@Suite("StatusBarController")
@MainActor
struct StatusBarControllerTests {

    @Test("handleClick triggers onClick and throttles subsequent clicks")
    func click_throttles() async {
        // Given
        var clickCount = 0
        let controller = StatusBarController(imageName: "MenuIcon") {
            clickCount += 1
        }

        // When: simulate three quick clicks
        controller.button?.performClick(nil)
        controller.button?.performClick(nil)
        controller.button?.performClick(nil)

        // Then: only first should count immediately due to throttle
        #expect(clickCount == 1)

        // After throttle interval, another click should be accepted
        try? await Task.sleep(for: .milliseconds(600))
        controller.button?.performClick(nil)
        #expect(clickCount == 2)
    }

    @Test("button is created with an image and action")
    func button_exists_with_image_and_action() {
        // Given
        let controller = StatusBarController(imageName: "MenuIcon") {}

        // When
        let button = controller.button

        // Then
        #expect(button != nil)
        #expect(button?.image != nil)
        #expect(button?.action != nil)
        #expect(button?.target != nil)
    }
}
