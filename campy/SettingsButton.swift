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
      self.camera.toggle()
    } label: {
      Label("Settings", systemImage: "gear")
        .opacity(1)
        .foregroundColor(.white)
        .backgroundStyle(
          .ultraThickMaterial
        )
        .font(.headline)
    }
  }
}

struct SettingsButton_Previews: PreviewProvider {
  static var previews: some View {
    SettingsButton(camera: Camera())
  }
}
