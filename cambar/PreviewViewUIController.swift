//
//  PreviewViewUIController.swift
//  cambar
//
//  Created by Devin Argenta on 8/1/25.
//

import AVKit
import NotificationCenter
import SwiftUI

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
    ) {
    }

    typealias NSViewType = PreviewView
}
