//
//  SettingsView.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import SwiftUI
import WebKit

public struct SettingsView: View {
    @ObservedObject var tabManager: TabManager
    @State private var showResetConfirmation = false
    @AppStorage("contentBlockerEnabled") private var contentBlockerEnabled = true
    @AppStorage("darkModePreference") private var darkModePreference: DarkModeManager.DarkModePreference = .system
    @AppStorage("doNotTrackEnabled") private var doNotTrackEnabled = true
    @AppStorage("developerModeEnabled") private var developerModeEnabled = false
    @AppStorage("tabDiscardingEnabled") private var tabDiscardingEnabled = true
    
    public init(tabManager: TabManager) {
        self.tabManager = tabManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                KeyboardShortcutHint("⌘,")
                
                Button("Done") {
                    if let current = tabManager.currentTab, current.url == "swiftbrowser://settings" {
                        tabManager.closeTab(current)
                    }
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Privacy & Security Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Security")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)
                        
                        // Content Blocker Toggle
                        settingsRow(
                            icon: "shield.lefthalf.fill",
                            color: .green,
                            title: "Content Blocker",
                            description: "Block ads and trackers",
                            isOn: $contentBlockerEnabled
                        )
                        
                        // Do Not Track Toggle
                        settingsRow(
                            icon: "eye.slash.fill",
                            color: .blue,
                            title: "Do Not Track",
                            description: "Request sites not to track you",
                            isOn: $doNotTrackEnabled
                        )
                    }
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)
                        
                        // Dark Mode Picker
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                                .font(.system(size: 20))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Mode")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Choose your preferred appearance")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: $darkModePreference) {
                                ForEach(DarkModeManager.DarkModePreference.allCases, id: \.self) { pref in
                                    Text(pref.displayName).tag(pref)
                                }
                            }
                             .pickerStyle(.menu)
                             .frame(width: 140)
                              .onChange(of: darkModePreference) { _, _ in
                                  tabManager.updateDarkMode()
                              }
                        }
                        .padding(12)
                        .background(Color.indigo.opacity(0.05))
                        .cornerRadius(8)
                    }

                    // Performance Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)

                        settingsRow(
                            icon: "memorychip",
                            color: .teal,
                            title: "Discard Background Tabs",
                            description: "Discard tabs idle for 15 minutes",
                            isOn: $tabDiscardingEnabled
                        )
                        .onChange(of: tabDiscardingEnabled) { _, _ in
                            tabManager.refreshTabDiscarding()
                        }
                    }
                    
                    // Developer Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Developer")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)
                        
                        settingsRow(
                            icon: "hammer.fill",
                            color: .orange,
                            title: "Developer Mode",
                            description: "Enable Web Inspector and debug tools",
                            isOn: $developerModeEnabled
                        )
                        .onChange(of: developerModeEnabled) { _, newValue in
                            tabManager.updateDeveloperMode(enabled: newValue)
                        }
                        
                        Text("Right-click on a page and choose Inspect Element.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                    }
                    
                    Divider()
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Danger Zone")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.bottom, 4)
                        
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                             
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Browser")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Clear all bookmarks and settings")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Reset...") { showResetConfirmation = true }
                                .foregroundColor(.red)
                                .buttonStyle(.bordered)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(32)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Reset Browser?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetBrowser()
                if let current = tabManager.currentTab, current.url == "swiftbrowser://settings" {
                    tabManager.closeTab(current)
                }
            }
        } message: {
            Text("This will reset the browser to factory defaults: delete all bookmarks, history, cookies, saved tabs, and settings. The browser will restart to the welcome screen. This cannot be undone.")
        }
    }
    
    private func settingsRow(icon: String, color: Color, title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func resetBrowser() {
        let defaults = UserDefaults.standard
        let bundleID = "nightguarder.Swift-Browser"

        // 1. Clear all UserDefaults
        defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(bundleID) || appSpecificKeys.contains($0) }.forEach { defaults.removeObject(forKey: $0) }

        // 2. Clear website data (cookies, cache, local storage, etc.)
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date) { }

        // 3. Clear HTTP cookies
        HTTPCookieStorage.shared.removeCookies(since: date)

        // 4. Clear history
        HistoryManager.shared.clearHistory()

        // 5. Clear all bookmarks across all spaces
        BookmarkManager.shared.clearAllBookmarks()

        // 6. Reset spaces to defaults
        SpaceManager.shared.resetToDefaultSpaces()

        // 7. Clear session persistence (saved tabs)
        SessionPersistence.shared.clearSession()

        // 8. Clear all downloads
        DownloadManager.shared.clearAllDownloads()

        // 9. Reset to default settings
        defaults.set(true, forKey: "contentBlockerEnabled")
        defaults.set(DarkModeManager.DarkModePreference.system.rawValue, forKey: "darkModePreference")
        defaults.set(true, forKey: "doNotTrackEnabled")
        defaults.set(false, forKey: "developerModeEnabled")
        defaults.set(true, forKey: "tabDiscardingEnabled")

        // 10. Reset hasLaunchedBefore to show Welcome screen on next launch
        defaults.set(false, forKey: "hasLaunchedBefore")

        // 11. Close all tabs to force welcome screen
        DispatchQueue.main.async {
            self.tabManager.closeAllTabs()
        }
    }

    private let appSpecificKeys = [
        "userName", "contentBlockerEnabled", "darkModePreference",
        "doNotTrackEnabled", "developerModeEnabled", "tabDiscardingEnabled"
    ]
}
