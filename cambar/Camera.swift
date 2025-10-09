import AVFoundation
import AVKit
import SwiftUI

class AVCapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var cameraOutput = AVCapturePhotoOutput()

    // MARK: Capture Photo

    public func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: Copy Photo

    func copyPhotoToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    // MARK: Stream Photo Output

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = NSImage(data: data)
        else {
            print("unable to capture, image or data were null")
            return
        }

        if let error = error {
            print(error.localizedDescription)
        }
        copyPhotoToClipboard(image)
    }
}

class Camera: ObservableObject {
    @Published var captureSession: AVCaptureSession
    @Published var captureSessionRunning: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var photoCaptureHandler: AVCapturePhotoDelegate
    @Published var errorMessage: String? = nil

    enum CaptureState {
        case on, off
    }

    // Valid Device Types
    private var validDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .external, .deskViewCamera, .builtInWideAngleCamera,
    ]

    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInteractive)
    private var sessionConfigured: Bool = false

    // Track current device for notification cleanup
    private var deviceDisconnectionObserver: NSObjectProtocol?
    private var currentDevice: AVCaptureDevice?

    init() {
        captureSession = AVCaptureSession()
        photoCaptureHandler = AVCapturePhotoDelegate()
    }

    // MARK: Public Controls

    func toggle(desired: CaptureState) {
        sessionQueue.sync {
            switch desired {
            case .on:
                if captureSession.isRunning {
                    
                    captureSession.stopRunning()
                    captureSessionRunning = false
                    return
                }
                captureSession.startRunning()
                captureSessionRunning = true
            case .off:
                captureSession.stopRunning()
                captureSessionRunning = false
            }
        }
    }

    func capturePhoto() {
        return photoCaptureHandler.capturePhoto()
    }

    // MARK: Device Selection

    func bestDevice(in position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Use the requested position; if none found, fall back to any device.
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: validDeviceTypes,
            mediaType: .video,
            position: position
        )
        if let device = discovery.devices.first {
            return device
        }
        // Fallback: any position
        let anyDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: validDeviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        let devices = anyDiscovery.devices
        guard !devices.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No capture devices found"
            }
            return nil
        }
        return devices.first
    }

    // MARK: Session Configuration

    func createSession() {
        sessionQueue.async { [self] in
            // If already configured, tear down inputs/outputs and reconfigure fresh.
            if sessionConfigured {
                teardownSessionLocked()
            }

            guard let videoDevice = bestDevice(in: .front) else { return }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)

                captureSession.beginConfiguration()
                captureSession.sessionPreset = .high

                // Inputs
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    throw NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
                }

                // Outputs
                let photoOutput = photoCaptureHandler.cameraOutput
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                } else {
                    throw NSError(domain: "Camera", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add photo output"])
                }

                captureSession.commitConfiguration()
                sessionConfigured = true

                // Setup device disconnection notification
                setupDisconnectionObserverLocked(for: videoDevice)
                currentDevice = videoDevice
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Remove inputs/outputs and observers on the session queue
    private func teardownSessionLocked() {
        // Remove all inputs/outputs safely
        captureSession.beginConfiguration()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        captureSession.commitConfiguration()
        sessionConfigured = false

        // Remove previous observer if any
        if let observer = deviceDisconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceDisconnectionObserver = nil
        }
        currentDevice = nil
    }

    private func setupDisconnectionObserverLocked(for device: AVCaptureDevice) {
        // Clean any previous observer
        if let observer = deviceDisconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceDisconnectionObserver = nil
        }

        deviceDisconnectionObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: device,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.errorMessage = "Camera disconnected"
            // Ensure session is torn down on the session queue
            self.sessionQueue.async {
                self.teardownSessionLocked()
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

    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                if !granted {
                    self.errorMessage = "Camera access denied"
                }
            }
        }
    }
}
