//
//  campreyApp.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVFoundation
import SwiftUI

@main
struct cambar: App {
    let d = NotificationCenter()
  var body: some Scene {
      MenuBarExtra("Cambar", systemImage: "camera") {
          ContentView()
      }.menuBarExtraStyle(.window).windowResizability(.contentSize)
  }
}
