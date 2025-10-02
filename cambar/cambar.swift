//
//  campreyApp.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVFoundation
import SwiftUI

@main
struct CamBar: App {
    let icon = NSImage(imageLiteralResourceName: "MenuIcon")
    let camera = Camera()
    var body: some Scene {
        WindowGroup {
            ContentView(camera: camera)
        }
        MenuBarExtra {
            ZStack {
                ContentView(camera: camera)
                    .zIndex(1)
            }
            .contextMenu {
                Text("Double tap to screenshot (copied to clipboard)")
                Button("Quit", action: quit) // Use a separate function to quit the app
            }
        } label: {
            Image(nsImage: icon).task {
                icon.isTemplate = true
            }
        }.windowBackgroundDragBehavior(.enabled).menuBarExtraStyle(WindowMenuBarExtraStyle())

    }

    func quit() {
        NSApp.terminate(nil)
    }
}
