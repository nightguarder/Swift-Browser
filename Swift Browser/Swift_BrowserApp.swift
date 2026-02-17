//
//  Swift_BrowserApp.swift
//  Swift Browser
//
//  Created by Nightguarder on 02.02.26.
//

import SwiftUI
import AppKit

@main
struct Swift_BrowserApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @AppStorage("darkModePreference") private var darkModePreference: DarkModeManager.DarkModePreference = .system
    @State private var showSplash = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasLaunchedBefore {
                    WelcomeView(showSplash: $showSplash)
                } else if showSplash {
                    SplashScreen()
                        .onAppear {
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
            .preferredColorScheme(darkModePreference == .dark ? .dark : (darkModePreference == .light ? .light : nil))
            .onAppear {
                SpaceManager.shared.initializeEncryptionOnFirstLaunch()
            }
        }
        .commands {
             SidebarCommands()
        }
    }
}
