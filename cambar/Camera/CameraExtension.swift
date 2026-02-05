//
//  CameraExtension.swift
//  cambar
//
//  Created by Devin Argenta on 10/16/25.
//  Copyright © 2025 stdev. All rights reserved.
//

import AVFoundation
import AVKit
import SwiftUI

extension Camera {
    // Remove inputs/outputs and observers on the session queue
    internal func teardownSessionLocked() {
        // Clear retained output reference so a fresh one can be configured later
        self.photoOutput = nil
        self.photoCaptureHandler.cameraOutput = AVCapturePhotoOutput()

        captureSession.beginConfiguration()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        captureSession.commitConfiguration()
        sessionConfigured = false

        if let observer = deviceDisconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceDisconnectionObserver = nil
        }
        currentDevice = nil
    }
}
