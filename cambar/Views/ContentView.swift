//  ContentView.swift
//  camprey
//
//  Created by Devin Argenta on 2/8/23.
//

import AVKit
import NotificationCenter
import SwiftUI

struct ContentView: View {
    var camera: Camera
    @State private var isDoubleTapped = false
    @State private var doubleTapPos: CGPoint?
    var body: some View {
        CameraView(camera: camera, isDoubleTapped: isDoubleTapped)
    }
}

