//
//  ContentView.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//


import SwiftUI
import Foundation
import AVFoundation
import AppKit
import AVKit

// App -> Scene -> PlayerUIView
// -> Camera ->
class Camera: ObservableObject {
    @ObservedObject var env = Env();
    
    internal init(permissionGranted: Bool = false) {
        self.permissionGranted = permissionGranted
       
        
    }
    
    
    @Published var permissionGranted: Bool = false // Flag for permission
    
    private let sessionQueue = DispatchQueue.main
    func checkPermission() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
        case .authorized:
            print("authorized")
            permissionGranted = true
            
            // Permission has not been requested yet
        case .notDetermined:
            print("not determined")
            requestPermission()
            
        default:
            print("default");
            permissionGranted = false
        }
        return permissionGranted
        
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

class PreviewView: NSView {
    @StateObject private var camera: Camera = Camera();
    
    init(captureSession: AVCaptureSession) {
   
        super.init(frame: .zero)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
     

        setupLayer()
    }

    func setupLayer() {
        previewLayer?.frame = self.frame
        previewLayer?.contentsGravity = .resizeAspectFill
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer?.session?.startRunning()
        layer = previewLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer?

}

struct PreviewViewUIController: NSViewRepresentable {
    private var captureSession: AVCaptureSession;
    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession;
    }
    func makeNSView(context: NSViewRepresentableContext<PreviewViewUIController>) -> PreviewView {
        return PreviewView(captureSession: self.captureSession)
    }
    
    

    func updateNSView(_ uiView: PreviewView, context: NSViewRepresentableContext<PreviewViewUIController>) {

    }
    
    typealias NSViewType = PreviewView
}

class Env: ObservableObject {
    @Published var captureSession = AVCaptureSession();
    
    
}

struct ContentView: View {
    @ObservedObject private var env = Env();
    init() {
        setupSession()
    }
    func setupSession() {
        env.captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [ .externalUnknown, .deskViewCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice.devices.first!), env.captureSession.canAddInput(videoDeviceInput) else { return }
        env.captureSession.addInput(videoDeviceInput)
        let output = AVCaptureVideoDataOutput()
        guard env.captureSession.canAddOutput(output) else { return }
        env.captureSession.sessionPreset = .hd1280x720
        env.captureSession.addOutput(output)
        env.captureSession.commitConfiguration()
    }
    var body: some View {
        VStack {
            PreviewViewUIController(captureSession: env.captureSession)
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
                    
                    if notification.object != nil {
                        print(env.captureSession.outputs)
                        env.captureSession.startRunning()
                    }
                }.onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { notification in
                    
                    if notification.object != nil {
                        env.captureSession.stopRunning()
                    }
                }
 

        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
