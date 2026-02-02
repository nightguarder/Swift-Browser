//
//  Swift_BrowserApp.swift
//  Swift Browser
//
//  Created by Nightguarder on 02.02.26.
//

import SwiftUI

@main
struct Swift_BrowserApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreen()
                } else {
                    BrowserView()
                }
            }
            .onAppear {
                // Auto-dismiss splash after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
            }
        }
        .commands {
             SidebarCommands() 
        }
    }
}
