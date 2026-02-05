//
//  AVCapturePhotoDelegate.swift
//  cambar
//
//  Created by Devin Argenta on 10/16/25.
//  Copyright © 2025 stdev. All rights reserved.
//

import AVFoundation
import AVKit
import SwiftUI

public class AVCapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    // This output must be the same instance that is added to the session.
    var cameraOutput = AVCapturePhotoOutput()

    // MARK: Capture Photo

    public func capturePhoto() {
        // Ensure this output has an active connection before capturing.
        guard cameraOutput.connections.isEmpty == false else {
            print("AVCapturePhotoDelegate: No active connections on photo output.")
            return
        }
        let settings = AVCapturePhotoSettings()
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: Copy Photo (uses injected pasteboard)

    func copyPhotoToClipboard(_ image: NSImage) -> Bool {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
        return true
    }

    // MARK: Stream Photo Output

    public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
        }

        guard let data = photo.fileDataRepresentation(),
            let image = NSImage(data: data),
            copyPhotoToClipboard(image)
        else {
            print("unable to capture, image or data were null")
            return
        }

    }
}
