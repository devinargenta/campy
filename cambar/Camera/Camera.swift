import AVFoundation
import AVKit
import SwiftUI

public class AVCapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    // This output must be the same instance that is added to the session.
    var cameraOutput = AVCapturePhotoOutput()

    // MARK: Capture Photo

    public func capturePhoto() {
        // Ensure this output has an active connection before capturing.
        guard cameraOutput.connections.isEmpty == false else {
            print("AVCapturePhotoDelegate: No active connections on photo output.")
            return
        }
        let settings = AVCapturePhotoSettings()
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: Copy Photo (uses injected pasteboard)

    func copyPhotoToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    // MARK: Stream Photo Output

    public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
        }

        guard let data = photo.fileDataRepresentation(),
            let image = NSImage(data: data)
        else {
            print("unable to capture, image or data were null")
            return
        }

        copyPhotoToClipboard(image)
    }
}

enum CaptureState {
    case on, off
}

enum HasPermissionResult {
    case granted
    case denied
    case notDetermined
}

final class Camera: ObservableObject {
    let captureSession: AVCaptureSession = AVCaptureSession()
    let photoCaptureHandler: AVCapturePhotoDelegate = AVCapturePhotoDelegate()
    @Published var permissionGranted: AVAuthorizationStatus = .notDetermined
    @Published var errorMessage: String? = nil

    // Retain the single photo output that is added to the session.
    private var photoOutput: AVCapturePhotoOutput? = nil

    // Internal state variables
    private var sessionConfigured: Bool = false
    private var deviceDisconnectionObserver: NSObjectProtocol? = nil
    private var currentDevice: AVCaptureDevice? = nil

    // MARK: Public Controls

    func toggle(desired: CaptureState) {
        switch desired {
        case .on:
            if captureSession.isRunning { return }
            if sessionConfigured {
                captureSession.startRunning()
            } else {
                createSession()
                if self.sessionConfigured {
                    self.captureSession.startRunning()
                }
            }
        case .off:
            captureSession.stopRunning()
        }
    }

    func capturePhoto() {
        // Ensure session is running and output is available
        guard captureSession.isRunning else {
            print("Camera: capturePhoto() called while session is not running.")
            return
        }
        photoCaptureHandler.capturePhoto()
    }

    // MARK: Session Configuration (Public entry point)

    func createSession() {
        self.configureSessionLocked()
    }

    // MARK: Session Configuration (Private, queued)

    private func configureSessionLocked() {
        // If already configured, tear down inputs/outputs and reconfigure fresh.
        if sessionConfigured {
            teardownSessionLocked()
        }

        guard let videoDevice = Camera.bestDevice() else {
            // Ensure @Published updates occur on main
            DispatchQueue.main.async { self.errorMessage = "No capture devices found" }
            return
        }

        do {
            let videoInput = try makeVideoInput(from: videoDevice)
            let output = makePhotoOutput()
            try applyConfiguration(input: videoInput, output: output)

            // Retain and inject output
            self.photoOutput = output
            self.photoCaptureHandler.cameraOutput = output

            // Observers / state
            installDeviceDisconnectionObserver(for: videoDevice)
            currentDevice = videoDevice
            sessionConfigured = true
            // Ensure @Published updates occur on main
            DispatchQueue.main.async { self.errorMessage = nil }
        } catch {
            // Ensure @Published updates occur on main
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // Build an AVCaptureDeviceInput from a device
    private func makeVideoInput(from device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        try AVCaptureDeviceInput(device: device)
    }

    // Build and configure the photo output
    private func makePhotoOutput() -> AVCapturePhotoOutput {
        let output = AVCapturePhotoOutput()
        output.maxPhotoQualityPrioritization = .quality
        return output
    }

    // Apply inputs/outputs to the session with rollback on failure
    private func applyConfiguration(input: AVCaptureDeviceInput, output: AVCapturePhotoOutput)
        throws
    {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        // Inputs
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            captureSession.commitConfiguration()
            throw NSError(
                domain: "Camera",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"]
            )
        }

        // Outputs
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            captureSession.removeInput(input)
            captureSession.commitConfiguration()
            throw NSError(
                domain: "Camera",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Cannot add photo output"]
            )
        }

        captureSession.commitConfiguration()
    }

    private func installDeviceDisconnectionObserver(for device: AVCaptureDevice) {
        if let observer = deviceDisconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceDisconnectionObserver = nil
        }

        deviceDisconnectionObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: device,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.errorMessage = "Camera disconnected"
                self?.teardownSessionLocked()
            }
        }
    }

    deinit {
        if let observer = deviceDisconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Permissions

    @MainActor
    func requestPermission() async -> AVAuthorizationStatus {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            let approved = await AVCaptureDevice.requestAccess(for: .video)
            switch approved {
            case true:
                self.permissionGranted = .authorized
            case false:
                self.permissionGranted = .denied
            }

        }
        return permissionGranted
    }
}

extension Camera {
    // Remove inputs/outputs and observers on the session queue
    internal func teardownSessionLocked() {
        // Clear retained output reference so a fresh one can be configured later
        self.photoOutput = nil
        self.photoCaptureHandler.cameraOutput = AVCapturePhotoOutput()

        captureSession.beginConfiguration()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        captureSession.commitConfiguration()
        sessionConfigured = false

        if let observer = deviceDisconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceDisconnectionObserver = nil
        }
        currentDevice = nil
    }
}

// MARK: - Device selection helper (include only if you don't already have one)
extension Camera {
    public static func bestDevice() -> AVCaptureDevice? {
        if let primary = AVCaptureDevice.default(for: .video) {
            return primary
        }
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
            mediaType: .video,
            position: .front
        )
        return discovery.devices.first
    }
}
