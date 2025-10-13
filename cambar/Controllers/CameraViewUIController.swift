//
//  CameraViewUIController.swift
//  cambar
//
//  Created by Devin Argenta on 8/1/25.
//

import AVFoundation
import AppKit
import SwiftUI

@MainActor
struct CameraViewUIController: NSViewRepresentable {
    var captureSession: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.masksToBounds = true
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true
        previewLayer.backgroundColor = .clear
        previewLayer.frame = view.bounds

        view.layer = previewLayer
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let previewLayer = context.coordinator.previewLayer else { return }

        // Update session if it has changed
        if previewLayer.session !== captureSession {
            previewLayer.session = captureSession
        }

        // Keep the layer sized to the view
        if previewLayer.frame != nsView.bounds {
            previewLayer.frame = nsView.bounds
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let previewLayer = coordinator.previewLayer {
            previewLayer.session = nil
        }
        nsView.layer = nil
        coordinator.previewLayer = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
