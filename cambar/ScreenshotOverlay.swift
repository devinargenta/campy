//
//  ScreenshotOverlay.swift
//  cambar
//
//  Created by Devin Argenta on 8/1/25.
//


import AVKit
import NotificationCenter
import SwiftUI

struct ScreenshotOverlay: View {
    @Binding var doubleTapped: Bool
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(
                    lineWidth: doubleTapped ? 5 : 0,
                    antialiased: true
                )
                .animation(.spring().speed(2), value: doubleTapped)
                .foregroundColor(.mint)
                .opacity(doubleTapped ? 1 : 0)
                .blur(radius: doubleTapped ? 5 : 0)

        }.ignoresSafeArea()
    }
}