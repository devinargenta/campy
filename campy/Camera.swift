import AVKit
import Foundation

class Camera: ObservableObject {
  @Published var captureSession = AVCaptureSession()
  @Published var permissionGranted: Bool = false  // Flag for permission

  private var validDeviceTypes: [AVCaptureDevice.DeviceType] = [
    .externalUnknown, .deskViewCamera, .builtInWideAngleCamera,
  ]
  private var sessionQueue = DispatchQueue.main

  init() {
    DispatchQueue(label: "self").async {
      self.createSession()
    }

  }

  func toggle() {
    if permissionGranted != true { return }
    if captureSession.isRunning == true {
      captureSession.stopRunning()
    } else {
      captureSession.startRunning()
    }
  }

  func createSession() {
    Task {
      let videoDevice = AVCaptureDevice.DiscoverySession.init(
        deviceTypes: validDeviceTypes, mediaType: .video,
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
      captureSession.commitConfiguration()
      return
    }
  }
  func checkPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      permissionGranted = true
      break
    case .notDetermined:
      requestPermission()
      break
    default:
      permissionGranted = false
      break
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
