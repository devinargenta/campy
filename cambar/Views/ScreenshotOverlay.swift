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
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(
                    lineWidth: doubleTapped ? Self.strokeWidth : 0,
                    antialiased: true
                )
                .padding(Self.padding)
                .animation(Self.animation, value: doubleTapped)
                .foregroundColor(Self.foregroundColor)
                .opacity(doubleTapped ? 1 : 0)

        }
    }
}
// MARK: - Constants
extension ScreenshotOverlay {
    fileprivate static let padding: CGFloat = 10
    fileprivate static let strokeWidth: CGFloat = 5
    fileprivate static let cornerRadius: CGFloat = 20
    fileprivate static let animation: Animation = .spring().speed(1)
    fileprivate static var foregroundColor: Color {
        Color.mint.mix(with: .white, by: 0.40)
    }

}
