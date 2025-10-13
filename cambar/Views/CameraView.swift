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
    @ObservedObject private var camera: Camera
    @State private var isDoubleTapped = false

    init(camera: Camera, isDoubleTapped: Bool = false) {
        self.camera = camera
        self.isDoubleTapped = isDoubleTapped
        camera.createSession()
    }
   
    var body: some View {
        Group {
            if camera.errorMessage != nil {
                errorStateView
            } else {
                previewStateView.background(ProgressView())
                    .frame(width: Self.previewWidth, height: Self.previewHeight)
                    .background {backgroundStateOverlay}
            }
        }
        .mask {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        
    }
}

// MARK: - Subviews
extension CameraView {

    func didTap() {
        withAnimation {
            isDoubleTapped = true
            camera.capturePhoto()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    isDoubleTapped = false
                }
            }
        }
    }
   
    @MainActor
    var previewStateView: some View {
        ZStack {
            CameraViewUIController(captureSession: camera.captureSession)
                .accessibilityIdentifier("CameraPreview")

            ScreenshotOverlay(doubleTapped: $isDoubleTapped)
                .accessibilityIdentifier("ScreenshotOverlay")
        }
        .onTapGesture(count: 2) {
            didTap()
        }


    }

    @MainActor
    var backgroundStateOverlay: some View {
        if !camera.captureSession.outputs.isEmpty {
            Self.errorBackgroundColor
        } else {
            Self.previewBackgroundColor
        }
    }
}


extension CameraView {
    @ViewBuilder
    fileprivate var errorStateView: some View {
        ZStack {
            VStack {
                Text(
                    camera.errorMessage ?? "Can't access camera, try refreshing"
                )
                .accessibilityIdentifier("ErrorMessage")
                Button(
                    action: {
                        camera.toggle(desired: .off)
                        camera.createSession()
                        camera.toggle(desired: .on)
                    },
                    label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.square.fill")
                            Text("Refresh camera connection")
                        }
                    }
                )
                .accessibilityIdentifier("ErrorRefreshButton")
            }
            .padding(10)
            .background(Self.errorBackgroundColor)
        }
    }

}

// MARK: - Constants
extension CameraView {
    fileprivate static let cornerRadius: CGFloat = 20
    fileprivate static let previewWidth: CGFloat = 500
    fileprivate static let previewHeight: CGFloat = 281
    fileprivate static let opacity: Double = 0.8

    fileprivate static var errorBackgroundColor: Color {
        Color.mint.mix(with: .black, by: 0.40)
    }

    fileprivate static var previewBackgroundColor: Color {
        Color.gray.mix(with: .black, by: 0.40)
    }
}
