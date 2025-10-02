//
//  PreviewView.swift
//  cambar
//
//  Created by Devin Argenta on 8/1/25.
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
