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
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer?.connection?.isVideoMirrored = true
 
        layer = previewLayer
  

 
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var previewLayer: AVCaptureVideoPreviewLayer?
}

struct ScreenshotOverlay: View {
    @Binding var doubletapped: Bool;
    var body: some View {
        ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(lineWidth: doubletapped ? 5 : 0, antialiased: true)
                    .animation(.spring().speed(2), value: doubletapped)
                    .foregroundColor(.mint)

        }.ignoresSafeArea()
    }
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
    @State private var didTap: Bool = false
    @State private var tapPos: CGPoint?
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
                    withAnimation {
                        didTap = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                self.didTap = false
                            }
                        }
                    }
                }
                .overlay {
                    ScreenshotOverlay(doubletapped: $didTap)
                }
                .background(.mint.opacity(0.5))
                .frame(width: 500, height: 281)
                .onReceive(didBecomeKeyNotification) { _ in
                    DispatchQueue.main.async {
                        camera.toggle(desired: .on)
                    }
                }.onReceive(didResignKeyNotification) { _ in
                    DispatchQueue.main.async {
                        camera.toggle(desired: .off)
                    }
                }
        }
    }
}
