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
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    lineWidth: doubleTapped ? 5 : 0,
                    antialiased: true
                )
                .padding(10)
                .animation(.spring().speed(1), value: doubleTapped)
                .foregroundColor(.mint.mix(with: .white, by: 0.40))
                .opacity(doubleTapped ? 1 : 0)

        }
    }
}
