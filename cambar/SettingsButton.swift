//
//  SettingsButton.swift
//  campy
//
//  Created by Devin Argenta on 2/15/23.
//

import SwiftUI

struct SettingsButton: View {
  private var camera: Camera
  init(camera: Camera) {
    self.camera = camera
  }
  var body: some View {
    Button {
      self.camera.toggle(desired: camera.captureSession.isRunning ? .off : .on)
    } label: {
      Image(systemName: "gear").backgroundStyle(.opacity(0))
    }.backgroundStyle(.opacity(0))
  }
}

struct SettingsButton_Previews: PreviewProvider {
  static var previews: some View {
      SettingsButton(camera: Camera())
  }
}
