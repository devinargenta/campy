//  ContentView.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVKit
import NotificationCenter
import SwiftUI

class PreviewView: NSView {
    private let sessionQueue = DispatchQueue(label: "camera.session")
    init(captureSession: AVCaptureSession) {
        super.init(frame: .zero)
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.setupLayer()
        sessionQueue.async { 
            captureSession.startRunning()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayer() {
        previewLayer?.contentsGravity = .resizeAspectFill
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer?.connection?.isVideoMirrored = true

        layer = previewLayer
    }

    var previewLayer: AVCaptureVideoPreviewLayer?
}

struct ScreenshotOverlay: View {
    @Binding var doubleTapped: Bool
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(
                    lineWidth: doubleTapped ? 5 : 0,
                    antialiased: true
                )
                .animation(.spring().speed(2), value: doubleTapped)
                .foregroundColor(.mint)
                .opacity(doubleTapped ? 1 : 0)
                .blur(radius: doubleTapped ? 5 : 0)

        }.ignoresSafeArea()
    }
}

struct PreviewViewUIController: NSViewRepresentable {
    private var captureSession: AVCaptureSession
    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    func makeNSView(
        context: NSViewRepresentableContext<PreviewViewUIController>
    ) -> PreviewView {
        PreviewView(captureSession: captureSession)
    }

    func updateNSView(
        _ uiView: PreviewView,
        context: NSViewRepresentableContext<PreviewViewUIController>
    ) {}

    typealias NSViewType = PreviewView
}

struct WindowKeyStateModifier: ViewModifier {
    let start: () -> Void
    let stop: () -> Void
    
    let didBecomeKeyNotification = NotificationCenter.default.publisher(
        for: NSWindow.didBecomeKeyNotification
    )
    let didResignKeyNotification = NotificationCenter.default.publisher(
        for: NSWindow.didResignKeyNotification
    )

    func body(content: Content) -> some View {
        content
            .onReceive(didBecomeKeyNotification) { _ in start() }
            .onReceive(didResignKeyNotification) { _ in stop() }
    }
}

struct ContentView: View {

    @StateObject private var camera = Camera()
    @State private var isDoubleTapped = false
    @State private var doubleTapPos: CGPoint?



    var body: some View {
        ZStack {
            CameraView(camera: camera, isDoubleTapped: isDoubleTapped)
        }
    }
}

