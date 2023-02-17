//  ContentView.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVKit
import AppKit
import Foundation
import SwiftUI
import VisionKit

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
    
    let d = NotificationCenter()
  var body: some View {
    PreviewViewUIController(captureSession: camera.captureSession)
      .cornerRadius(5, antialiased: true)
      .frame(width: 500, height: 281)
      .onReceive(didBecomeKeyNotification) { notification in
        DispatchQueue.main.async {
            camera.toggle(desired: .on)
        }
      }.onReceive(didResignKeyNotification) { notification in
        DispatchQueue.main.async {
            camera.toggle(desired: .off)
        }

      }.task {
        DispatchQueue.main.async {
          camera.checkPermission()
        }
      }
      .overlay(alignment: .bottomTrailing) {
          Text("lgtm").offset(x: -10, y: -10).font(.callout).foregroundColor(.mint).fontWeight(.bold)
//          SettingsButton(camera: camera).padding(12).buttonStyle(.plain).onHover { curs in
//              if curs == true {
//                  NSCursor.pointingHand.push()
//              } else {
//                  NSCursor.pointingHand.pop()
//              }
//          }
      }
  }

}
