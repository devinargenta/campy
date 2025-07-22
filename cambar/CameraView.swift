//
//  CameraView.swift
//  cambar
//
//  Created by Devin Argenta on 7/22/25.
//
import AVKit
import NotificationCenter
import SwiftUI

struct CameraView: View {
    @ObservedObject var camera: Camera
    @State private var isDoubleTapped = false
    init(camera: Camera, isDoubleTapped: Bool = false) {
        self.camera = camera
        self.isDoubleTapped = isDoubleTapped
        self.camera.requestPermission()
    }
    var body: some View {
        if camera.errorMessage != nil {
            Text(camera.errorMessage ?? "We can't connect to your camera! Please ensure you have one connected.")
        }
        PreviewViewUIController(captureSession: camera.captureSession)
            .onTapGesture(count: 2) { tap in
                camera.capturePhoto()
                withAnimation {
                    isDoubleTapped = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            isDoubleTapped = false
                        }
                    }
                }
            }
            .overlay {
                ScreenshotOverlay(doubleTapped: $isDoubleTapped)
            }
            .background(.mint.opacity(0.5))
            .frame(width: 500, height: 281)
            .modifier(
                WindowKeyStateModifier(
                    start: { camera.toggle(desired: .on) },
                    stop: { camera.toggle(desired: .off) }
                )
            )
    }
}
