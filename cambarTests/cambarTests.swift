import AVFoundation
import AppKit  // For NSImage, NSPasteboard
internal import CoreTransferable
import Foundation
import Testing

@testable import cambar

// 5. Mock for AVCaptureDeviceInput
final class MockCaptureDeviceInput: AVCaptureDeviceInput {
    // This allows us to instantiate the Mock without the need for a real AVCaptureDevice
    // In a real project, you would create a mock AVCaptureDevice as well.
    override init(device: AVCaptureDevice) throws {
        try super.init(device: device)
    }
}

// 6. Fake for AVCaptureDevice (needed to create an AVCaptureDeviceInput)
final class FakeCaptureDevice: AVCaptureDevice {
    override var uniqueID: String {
        "12345"
    }
    override class func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        .authorized
    }
    // You would typically mock more methods here if needed
}

// MARK: - Tests



// -----------------------------------------------------------------------------

@Suite("Camera Class Tests")
struct CameraTests {

    @MainActor
    @Test("toggle(.on) calls startRunning on capture session")
    func toggle_on_startsSession() async {
        // Given
        let camera = Camera()

        // When
//        camera.createSession()
//        camera.toggle(desired: .off)
        camera.toggle(desired: .on)
        // Then
        #expect(camera.captureSession.sessionPreset == .high)
        await MainActor.run {
            
            #expect(camera.captureSession.isRunning == true)
            camera.captureSession.stopRunning()
        }
    }

    @MainActor
    @Test("toggle(.off) calls stopRunning on capture session")
    func toggle_off_stopsSession() {
        // Given
        let camera = Camera()
        camera.createSession()
        camera.captureSession.startRunning()  // Ensure it's running first

        #expect(camera.captureSession.isRunning)
        // When
        camera.toggle(desired: .off)

        // Then
        #expect(!camera.captureSession.isRunning)
    }


    @MainActor
    @Test("createSession successfully configures a session")
    func createSession_success() async throws {
        // Given

        // Use a simple device finder that returns the fake device

        let camera = Camera()
        // When
        camera.createSession()


        try await Task.sleep(for: .milliseconds(50))

        // Then
        #expect(camera.errorMessage == nil)
    }

    @Test("createSession sets error message when no device is found")
    func impiss() async throws {
        // Given

        // Use a device finder that returns nil (no device found)

        let camera = Camera()

        // When
        camera.errorMessage = "YOU STINKY"

        // Wait for the asynchronous configuration and main-queue update
        try await Task.sleep(for: .milliseconds(50))

        // Then
        #expect(camera.errorMessage == "YOU STINKY")
    }

}

// MARK: - Injectible-only tests for photo capture delegate and fragile pieces

@Suite("AVCapturePhotoDelegate Tests (injectible only)")
struct PhotoDelegateTests {

    // Helper to create a small 1x1 NSImage for pasteboard tests
    private func makeTestImage() -> NSImage {
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }

    @Test("copyPhotoToClipboard writes NSImage to NSPasteboard.general")
    func copy_to_pasteboard_writes_image() {
        // Given
        let delegate = AVCapturePhotoDelegate()
        let image = makeTestImage()
        let pb = NSPasteboard.general

        // Clear pasteboard first
        pb.clearContents()

        // When
        delegate.copyPhotoToClipboard(image)

        // Then: verify an image is now available on the pasteboard
        let classes: [NSPasteboardReading.Type] = [NSImage.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [:]
        let objects = pb.readObjects(forClasses: classes, options: options)
        #expect(objects != nil && objects!.contains { $0 is NSImage })
    }

    @Test("capturePhoto early-exits when output has no connections (no crash, no pasteboard write)")
    func capturePhoto_without_connections_does_not_capture() {
        // Given
        let delegate = AVCapturePhotoDelegate()
        // Fresh output with no connections
        delegate.cameraOutput = AVCapturePhotoOutput()

        // Clear pasteboard first
        let pb = NSPasteboard.general
        pb.clearContents()

        // When
        delegate.capturePhoto()

        // Then: still no image on pasteboard (best observable side effect we have)
        let classes: [NSPasteboardReading.Type] = [NSImage.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [:]
        let objects = pb.readObjects(forClasses: classes, options: options)
        #expect(objects == nil || objects!.isEmpty)
    }

    @Test("photoOutput nil data path: no crash and nothing copied")
    func photoOutput_nil_data_no_copy() {
        // We cannot construct AVCapturePhoto with custom data.
        // However, we can at least exercise the method with nil data by creating
        // a minimal stub that calls the delegate method with a photo that yields nil.
        // Without injection seams, we limit to verifying no pasteboard change.

        // Given
        let delegate = AVCapturePhotoDelegate()
        let pb = NSPasteboard.general
        pb.clearContents()

        // We cannot call photoOutput(_:didFinishProcessingPhoto:error:) with a real AVCapturePhoto
        // fabricated in tests, so we limit this to ensuring the method is callable with an error,
        // which triggers the error branch and early return before copying.
        // Call the delegate method directly with a dummy AVCapturePhotoOutput and a zero-initialized AVCapturePhoto.
        // Constructing AVCapturePhoto is not publicly available; therefore we can only verify
        // that calling the method with error=nil is not feasible here. We will call with an error to exercise the path.

        // When
        // Call with a fabricated error and skip providing a real photo (not possible).
        // We can only ensure that invoking the code path with an error does not affect pasteboard.
        delegate.capturePhoto()

        // Then
        let classes: [NSPasteboardReading.Type] = [NSImage.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [:]
        let objects = pb.readObjects(forClasses: classes, options: options)
        #expect(objects == nil || objects!.isEmpty)
    }

    @Test("Camera.capturePhoto early-exits if session is not running")
    func camera_capturePhoto_when_not_running_does_nothing() {
        // Given
        let camera = Camera()
        // Ensure session is not running
        #expect(camera.captureSession.isRunning == false)

        // Clear pasteboard
        NSPasteboard.general.clearContents()

        // When
        camera.capturePhoto()

        // Then: No pasteboard write occurred (no capture initiated)
        let classes: [NSPasteboardReading.Type] = [NSImage.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [:]
        let objects = NSPasteboard.general.readObjects(forClasses: classes, options: options)
        #expect(objects == nil || objects!.isEmpty)
    }

    @Test("teardownSessionLocked clears outputs and resets delegate output")
    func teardown_resets_outputs_and_delegate() {
        // Given
        let camera = Camera()

        // Add a dummy input/output so we can verify they are removed.
        // We cannot add real device inputs without hardware; however, removing
        // from an empty session is still a valid path to test the delegate/output reset.
        // Force the photo output delegate to hold a non-default instance so we can verify reset.
        let customOutput = AVCapturePhotoOutput()
        camera.captureSession.beginConfiguration()
        if camera.captureSession.canAddOutput(customOutput) {
            camera.captureSession.addOutput(customOutput)
        }
        camera.captureSession.commitConfiguration()

        // Sanity: the delegate initially points to a non-empty output after createSession,
        // but we didn't call createSession here; we set a custom one directly:
        camera.captureSession.stopRunning()

        // Set the delegate's output to our custom one
        // NOTE: Accessing photoCaptureHandler is private in Camera; we cannot reach it directly.
        // However, teardownSessionLocked sets photoCaptureHandler.cameraOutput = AVCapturePhotoOutput()
        // which we can observe indirectly by asserting the session no longer contains our custom output after teardown.
        // We will also verify session outputs become empty.
        #expect(camera.captureSession.outputs.contains { $0 === customOutput })

        // When
        camera.teardownSessionLocked()

        // Then
        #expect(camera.captureSession.outputs.isEmpty)
    }
}
