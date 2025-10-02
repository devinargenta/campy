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
        if let errorMessage = camera.errorMessage {
            ZStack {
                VStack {
                    Text(errorMessage)
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
                .applyConditionalButtonStyle()
            }
        } else {
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
                        start: {
                            camera.toggle(desired: .on)
                        },
                        stop: {
                            camera.toggle(desired: .off)
                        }
                    )
                )
        }
    }
}

// MARK: - Conditional ButtonStyle Helper
private extension View {
    @ViewBuilder
    func applyConditionalButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(GlassButtonStyle())
        } else {
            self.buttonStyle(PlainButtonStyle())
        }
    }
}
