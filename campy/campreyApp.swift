//
//  campreyApp.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVFoundation
import SwiftUI

@main
struct campreyApp: App {
  var body: some Scene {
    MenuBarExtra {
      ContentView()
    } label: {
        VStack {
          Text("PISS1")
        }
    }
    .menuBarExtraStyle(.window).windowResizability(.contentSize)
  }
}
