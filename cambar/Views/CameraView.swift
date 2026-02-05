//
//  CameraView.swift
//  cambar
//
//  Created by Devin Argenta on 7/22/25.
//
import AVKit
import KeyboardShortcuts
import NotificationCenter
import SwiftUI

struct CameraView: View {
    @ObservedObject var camera: Camera
    @State private var isDoubleTapped: Bool = false
    @State private var isMirrored: Bool = false
    func didTap() {
        withAnimation {
            isDoubleTapped.toggle()
            camera.capturePhoto()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    isDoubleTapped.toggle()
                }
            }
        }
    }
    var body: some View {
        Group {
            if camera.errorMessage != nil {
                errorStateView
            } else {
                ZStack {
                    ProgressView()
                    previewStateView
                }
                .frame(width: Self.previewWidth, height: Self.previewHeight)
                .background { backgroundStateOverlay }
            }
        }
        .mask {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        .task {
            KeyboardShortcuts.onKeyDown(for: .screenshot) { [self] in
                withAnimation {
                    DispatchQueue.main.async {
                        self.didTap()
                    }
                }
            }
        }

    }
}

// MARK: - Subviews
extension CameraView {

    var shortcutSettings: some View {
        Section {
            Text("CMD+Opt+K - Open / Close Cambar")
            Text("CMD+Opt+P - Screenshot")
        } header: {
            Text("Shortcuts")
        }

    }
    @MainActor
    var previewStateView: some View {
        ZStack {
            CameraViewUIController(captureSession: camera.captureSession, isMirrored: isMirrored)
                .contextMenu {
                    Text("Double tap to screenshot (copied to clipboard)")
                    shortcutSettings
                    Section(
                        content: {
                            Button("Toggle Mirroring") { [self] in
                                self.isMirrored.toggle()
                            }
                            Button("Refresh Connection / Retry") { [self] in
                                // Safely reconfigure
                                self.camera.toggle(desired: .off)
                                self.camera.toggle(desired: .on)
                                // Only turn on if the window is visible
                            }
                        },
                        header: {
                            Text("Settings")
                        }
                    )
                    Section {
                        Button("Quit", action: { NSApp.terminate(nil) })
                    }
                }
                .accessibilityIdentifier("CameraPreview")

            ScreenshotOverlay(isDoubleTapped: $isDoubleTapped)
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
            .padding(Self.padding)
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
    fileprivate static let padding: CGFloat = 10

    fileprivate static var errorBackgroundColor: Color {
        Color.mint.mix(with: .black, by: 0.40)
    }

    fileprivate static var previewBackgroundColor: Color {
        Color.gray.mix(with: .black, by: 0.40)
    }
}
