import AVFoundation
import AVKit
import Foundation

class AVCapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    @Published var cameraOutput = AVCapturePhotoOutput()
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()

        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = NSImage(data: data)
        else {
            return
        }

        if let error = error {
            print(error.localizedDescription)
        }
        let pb = NSPasteboard.general
        
        
        pb.clearContents()
        pb.writeObjects([image])
    }
}


class Camera: ObservableObject {
    @Published var captureSession = AVCaptureSession()
    @Published var permissionGranted: Bool = false // Flag for permission

    @Published var photoCaptureHandler = AVCapturePhotoDelegate()
    
    enum CaptureState {
        case on, off
    }

    private var validDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .externalUnknown, .deskViewCamera, .builtInWideAngleCamera,
    ]
    private var sessionQueue = DispatchQueue.main

    init() {
        DispatchQueue.main.async {
            self.createSession()
            self.photoCaptureHandler = AVCapturePhotoDelegate()
        }
    }

    func toggle(desired: CaptureState) {
        switch desired {
        case .on:
            captureSession.startRunning()
        case .off:
            captureSession.stopRunning()
        }
    }
    
    func capturePhoto() {
        return self.photoCaptureHandler.capturePhoto()
    }

    func createSession() {
        Task {
            let videoDevice = AVCaptureDevice.DiscoverySession(
                deviceTypes: self.validDeviceTypes,
                mediaType: .video,
                position: .unspecified)

            guard let device = videoDevice.devices.first else { return }
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(videoDeviceInput)
            else { return }
            captureSession.beginConfiguration()
            captureSession.addInput(videoDeviceInput)
            let output = AVCaptureVideoDataOutput()
            guard captureSession.canAddOutput(output) else { return }
            captureSession.sessionPreset = .high
            captureSession.addOutput(output)
            captureSession.addOutput(self.photoCaptureHandler.cameraOutput)
            captureSession.commitConfiguration()
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    func requestPermission() {
        sessionQueue.suspend()
        return AVCaptureDevice.requestAccess(for: .video) { granted in
            self.sessionQueue.async {
                self.permissionGranted = granted
                self.sessionQueue.resume()
            }
        }
    }
}
