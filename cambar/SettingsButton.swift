//
//  SettingsButton.swift
//  campy
//
//  Created by Devin Argenta on 2/15/23.
//

import SwiftUI

struct SettingsButton: View {
    @State private var showMessage = false

    var body: some View {
        ViewThatFits {
            VStack {
                Button("PISS") {
                    showMessage = true
                }
                if showMessage {
                    Text("PISS")
                }
            }
        }
    }
}

struct SettingsButton_Previews: PreviewProvider {
    static var previews: some View {
        SettingsButton()
    }
}
