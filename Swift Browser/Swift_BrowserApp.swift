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
    @AppStorage("darkModePreference") private var darkModePreference: DarkModeManager.DarkModePreference = .system
    @State private var showSplash = false

    var body: some Scene {
        WindowGroup {
            if darkModePreference == .system {
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
            } else {
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
                .preferredColorScheme(darkModePreference == .dark ? .dark : .light)
            }
        }
        .commands {
             SidebarCommands()
        }
    }
}
