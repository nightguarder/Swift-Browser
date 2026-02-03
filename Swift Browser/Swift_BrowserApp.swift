//
//  Swift_BrowserApp.swift
//  Swift Browser
//
//  Created by Nightguarder on 02.02.26.
//

import SwiftUI

@main
struct Swift_BrowserApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @State private var showSplash = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasLaunchedBefore {
                    WelcomeView(showSplash: $showSplash)
                } else if showSplash {
                    SplashScreen()
                        .onAppear {
                            // Auto-dismiss splash after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    BrowserView()
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
        .commands {
             SidebarCommands()
        }
    }
}
