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
    @Binding var isDoubleTapped: Bool
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(
                    lineWidth: isDoubleTapped ? Self.strokeWidth : 0,
                    antialiased: true
                )
                .padding(Self.padding)
                .animation(Self.animation, value: isDoubleTapped)
                .foregroundColor(Self.foregroundColor)
                .opacity(isDoubleTapped ? 1 : 0)

        }.onChange(of: isDoubleTapped){
            print(isDoubleTapped)
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
