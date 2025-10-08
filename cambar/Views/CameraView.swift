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
        if self.camera.errorMessage != nil {
            ZStack {
                VStack {
                    Text(
                        self.camera.errorMessage
                            ?? "Can't access camera, try refreshing"
                    )
                    Button(
                        action: {
                            camera.errorMessage = nil
                            camera.requestPermission()
                            camera.createSession()
                        },
                        label: {
                            HStack {
                                Image(systemName: "arrow.clockwise.square.fill")
                                Text("Refresh camera connection")
                            }
                        }
                    )
                }
                .padding(10)
                .background(Color.mint.mix(with: .black, by: 0.40))

            }
        } else {
                CameraViewUIController(captureSession: camera.captureSession)
                    .onTapGesture(count: 2) { tap in
                        camera.capturePhoto()
                        withAnimation {
                            isDoubleTapped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1)
                            {
                                withAnimation {
                                    isDoubleTapped = false
                                }
                            }
                        }
                    }
                    .overlay {
                        ScreenshotOverlay(doubleTapped: $isDoubleTapped)
                    }
                    .frame(width: 500, height: 281)
                    .background(.clear)
        }
    }
}
