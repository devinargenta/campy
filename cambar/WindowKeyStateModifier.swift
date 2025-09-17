//
//  WindowKeyStateModifier.swift
//  cambar
//
//  Created by Devin Argenta on 8/1/25.
//

import AVKit
import NotificationCenter
import SwiftUI

struct WindowKeyStateModifier: ViewModifier {
    @Environment(\.isPresented) var isPresented;
    
    let start: () -> Void
    let stop: () -> Void
    let didBecomeKeyNotification = NotificationCenter.default.publisher(
        for: NSWindow.didBecomeKeyNotification
    )
    let didResignKeyNotification = NotificationCenter.default.publisher(
        for: NSWindow.didResignKeyNotification
    )
    
    func body(content: Content) -> some View {
        content.onAppear {
            start()
        }.onDisappear {
            stop()
        }
    }
}
