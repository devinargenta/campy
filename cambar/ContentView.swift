//  ContentView.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AppKit
import AVKit
import Foundation
import SwiftUI
import VisionKit

class PreviewView: NSView {
    init(captureSession: AVCaptureSession) {
        super.init(frame: .zero)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setupLayer()
    }

    func setupLayer() {
        previewLayer?.contentsGravity = .resizeAspectFill
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = true
        layer = previewLayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var previewLayer: AVCaptureVideoPreviewLayer?
}

struct PreviewViewUIController: NSViewRepresentable {
    private var captureSession: AVCaptureSession
    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    func makeNSView(context: NSViewRepresentableContext<PreviewViewUIController>) -> PreviewView {
        PreviewView(captureSession: captureSession)

    }

    func updateNSView(
        _ uiView: PreviewView, context: NSViewRepresentableContext<PreviewViewUIController>) {}

    typealias NSViewType = PreviewView
}

struct ContentView: View {
    @ObservedObject private var camera = Camera()
    @State private var didTap:Bool = false
    let didBecomeKeyNotification = NotificationCenter.default.publisher(
        for: NSWindow.didBecomeKeyNotification)
    let didResignKeyNotification = NotificationCenter.default.publisher(
        for: NSWindow.didResignKeyNotification)

    init() {
        camera.checkPermission()
    }
    var body: some View {
        ZStack {
            PreviewViewUIController(captureSession: camera.captureSession)
                .onTapGesture(count: 2) { _ in
                    camera.capturePhoto()
                    didTap = true
                    Task {
                        try? await Task.sleep(for: Duration.seconds(0.75))
                            didTap = false
                    }
                }
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(.mint.opacity(0.7))
                        Text("Screenshot copied to clipboard").fontDesign(.monospaced).font(.largeTitle)
                    }.ignoresSafeArea()
                        .opacity(didTap ? 1 : 0)
                }
                .frame(width: 500, height: 281)
                .onReceive(didBecomeKeyNotification) { f in
                    DispatchQueue.main.async {
                        camera.toggle(desired: .on)
 
                    }
                }.onReceive(didResignKeyNotification) { _ in
                    DispatchQueue.main.async {
                        camera.toggle(desired: .off)
                    }
                    
                }
            
                .overlay(alignment: .bottomTrailing) {
                    Text("lgtm").offset(x: -10, y: -10).font(.callout).foregroundColor(.mint).fontWeight(.bold)
                    
                }
        }
    }
}
