//
//  campreyApp.swift
//  camprey
//
    //  Created by Devin Argenta on 2/8/23.
//

import SwiftUI
import AVFoundation


@main
struct campreyApp: App {
    @State var isInserted: Bool = true;
    @State private var hide: Bool = false;
    var body: some Scene {
  
        MenuBarExtra("PISS") {
            VStack{
                
                ContentView()
            }.scaledToFill()
            
            
            
        }.menuBarExtraStyle(.window)



    }
}


struct Previews_campreyApp_Previews: PreviewProvider {
    
    static var previews: some View {
        
        ContentView().frame(width: 500, height: 500)

    }
}
