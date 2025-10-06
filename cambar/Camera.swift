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
    @Published var permissionGranted: Bool = false // Flag for permission

    @Published var photoCaptureHandler: AVCapturePhotoDelegate
    
    @Published var errorMessage: String? = nil

    // MARK: CaptureState Enum
    enum CaptureState {
        case on, off
    }

    // MARK: Valid Device Types [AVCaptureDevice.DeviceType]
    private var validDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .external, .deskViewCamera, .builtInWideAngleCamera,
    ]

    private let sessionQueue = DispatchQueue(label: "camera.session")
    
    private var sessionConfigured: Bool = false

    // MARK: init

    init() {
        captureSession = AVCaptureSession()
        photoCaptureHandler = AVCapturePhotoDelegate()
    }

    func toggle(desired: CaptureState) {
        sessionQueue.async { [self] in
            switch desired {
            case .on:
                captureSession.startRunning()
            case .off:
                captureSession.stopRunning()
            }
        }
    }

    func capturePhoto() {
        return photoCaptureHandler.capturePhoto()
    }

    func bestDevice(in position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: validDeviceTypes, mediaType: .video, position: .unspecified)
        let devices = discoverySession.devices
        guard !devices.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No capture devices found"
            }
            return nil
        }
        return devices.first
    }

    func createSession() {
        DispatchQueue.main.async { [self] in
            guard let videoDevice = bestDevice(in: .front) else { return }
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  captureSession.canAddInput(videoDeviceInput)
            else {
                DispatchQueue.main.async {
                    self.errorMessage = "No capture devices found"
                }
                return
            }
            captureSession.beginConfiguration()
            captureSession.automaticallyRunsDeferredStart = true
            captureSession.addInput(videoDeviceInput)
            captureSession.sessionPreset = .high
            if captureSession.canAddOutput(photoCaptureHandler.cameraOutput) {
                captureSession.addOutput(photoCaptureHandler.cameraOutput)
            }
            captureSession.commitConfiguration()
            sessionConfigured = true
        }
        return
    }

    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                }
            }
        }
    }
}

