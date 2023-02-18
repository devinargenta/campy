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
           
                .overlay(alignment: .topTrailing) {
                    Button {
                        NSApplication.shared.keyWindow?.close()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                    }.focusable(false).keyboardShortcut("x")
                }
                
            }.buttonStyle(.borderless).contextMenu{
                    Text("Double tap to screenshot")
                    Text("cmd+x to quit")
            }
        } label: {
            Image(nsImage: icon.self).task {
                icon.isTemplate = true
            }
                          
        }.menuBarExtraStyle(.window).windowResizability(.contentSize)
       
    }
}
