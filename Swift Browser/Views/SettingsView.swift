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
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("doNotTrackEnabled") private var doNotTrackEnabled = true
    
    public init(tabManager: TabManager) {
        self.tabManager = tabManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
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
                        
                        // Dark Mode Toggle
                        settingsRow(
                            icon: "moon.fill",
                            color: .indigo,
                            title: "Dark Mode",
                            description: "Force dark mode on websites",
                            isOn: $darkModeEnabled
                        )
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
            Text("This will delete all bookmarks and reset settings. This cannot be undone.")
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
        
        // Clear all browser UserDefaults
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            defaults.removeObject(forKey: key)
        }
        
        // Clear web cache and data
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date) { }
        
        // Clear cookies
        HTTPCookieStorage.shared.removeCookies(since: date)
        
        // Reset content blocker to default (enabled)
        defaults.set(true, forKey: "contentBlockerEnabled")
        
        // Reset dark mode to default (disabled)
        defaults.set(false, forKey: "darkModeEnabled")
    }
}
