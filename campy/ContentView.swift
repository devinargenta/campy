//  ContentView.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVKit
import AppKit
import Foundation
import SwiftUI

class PreviewView: NSView {

  init(captureSession: AVCaptureSession) {
    super.init(frame: .zero)
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    setupLayer()
  }

  func setupLayer() {

    previewLayer?.contentsGravity = .resizeAspectFill
    previewLayer?.videoGravity = .resizeAspectFill
    previewLayer?.connection?.automaticallyAdjustsVideoMirroring = true
    layer = previewLayer
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var previewLayer: AVCaptureVideoPreviewLayer?
}

struct PreviewViewUIController: NSViewRepresentable {
  private var captureSession: AVCaptureSession
  init(captureSession: AVCaptureSession) {
    self.captureSession = captureSession
  }
  func makeNSView(context: NSViewRepresentableContext<PreviewViewUIController>) -> PreviewView {
    PreviewView(captureSession: self.captureSession)
  }

  func updateNSView(
    _ uiView: PreviewView, context: NSViewRepresentableContext<PreviewViewUIController>
  ) {}

  typealias NSViewType = PreviewView
}

struct ContentView: View {
  @ObservedObject private var camera = Camera()

  let didBecomeKeyNotification = NotificationCenter.default.publisher(
    for: NSWindow.didBecomeKeyNotification)
  let didResignKeyNotification = NotificationCenter.default.publisher(
    for: NSWindow.didResignKeyNotification)
  var body: some View {

    PreviewViewUIController(captureSession: camera.captureSession)
      .cornerRadius(5, antialiased: true)
      .padding(.all, 5)
      .background(
        Color.mint.opacity(0.5)
      )
      .frame(width: 500, height: 281)
      .onReceive(didBecomeKeyNotification) { notification in
        DispatchQueue.main.async {
          camera.toggle()
        }
      }.onReceive(didResignKeyNotification) { notification in
        DispatchQueue.main.async {
          camera.toggle()
        }

      }.task {
        DispatchQueue.main.async {
          camera.checkPermission()
        }
      }
      .overlay(alignment: .bottomTrailing) {
        SettingsButton(camera: camera).padding(0)
      }
  }

}
