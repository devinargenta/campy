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
    let icon = NSImage(imageLiteralResourceName: "MenuIcon")
    var body: some Scene {
        MenuBarExtra {
            ZStack {
                ContentView()
                    .zIndex(1)
                Text("connecting to ur lil camera?")
                    .zIndex(0)
            }
            .buttonStyle(.borderless)
            .contextMenu {
                Text("Double tap to screenshot")
                Button("Quit") {
                    NSApp.terminate(self)
                }
            }
        } label: {
            Image(nsImage: icon.self).task {
                icon.isTemplate = true
            }

        }.menuBarExtraStyle(.window)
            .windowResizability(.contentSize)
    }
}
