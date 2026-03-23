//
//  SettingsView.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import SwiftUI
import WebKit
import Combine

public struct SettingsView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject private var duckPlayerSettings = DuckPlayerSettings.shared
    @ObservedObject private var contentBlockerManager = ContentBlockerManager.shared
    @State private var showResetConfirmation = false
    @State private var isUpdatingFilters = false
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
                    // Content Blocker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Blocking")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)
                        
                        // Filter Lists Status
                        HStack {
                            Image(systemName: "list.bullet.rectangle.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 20))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Filter Lists")
                                    .font(.system(size: 14, weight: .medium))
                                Text("\(contentBlockerManager.totalRules) rules active")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                isUpdatingFilters = true
                                Task {
                                    _ = await contentBlockerManager.updateFilterLists()
                                    isUpdatingFilters = false
                                }
                            }) {
                                if isUpdatingFilters {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Text("Update Now")
                                        .font(.system(size: 12))
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isUpdatingFilters)
                        }
                        .padding(12)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)
                        
                        // Rule Limit Warning
                        if contentBlockerManager.ruleLimitWarning {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                
                                Text("Rule limit reached. Some filters may be inactive.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            .padding(12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Filter Lists
                        ForEach(contentBlockerManager.getFilterLists()) { filterList in
                            FilterListRow(
                                filterList: filterList,
                                onToggle: { enabled in
                                    contentBlockerManager.toggleFilterList(id: filterList.id, enabled: enabled)
                                    tabManager.updateContentBlocker(enabled: contentBlockerEnabled)
                                }
                            )
                        }
                        
                        // Last Update
                        if let lastUpdate = contentBlockerManager.lastUpdate {
                            Text("Last updated: \(formatDate(lastUpdate))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                        }
                    }
                    
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
                        
                        // Fireproof Domains
                        FireproofDomainsSection()
                    }
                    
                    // Spaces Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spaces")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)
                        
                        ForEach(SpaceManager.shared.spaces) { space in
                            SpaceCookieSettingsRow(space: space)
                        }
                    }
                    
                    // Duck Player Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duck Player")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.bottom, 4)
                        
                        // Mode Picker
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 20))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YouTube Privacy Player")
                                    .font(.system(size: 14, weight: .medium))
                                Text(duckPlayerSettings.mode.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: $duckPlayerSettings.mode) {
                                ForEach(DuckPlayerMode.allCases) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                        
                        // Reset "Don't show again" if it was dismissed
                        if duckPlayerSettings.mode == .alwaysAsk && duckPlayerSettings.alwaysAskOverlayHidden {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                
                                Text("You dismissed the Duck Player button. ")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Button("Show it again") {
                                    duckPlayerSettings.alwaysAskOverlayHidden = false
                                }
                                .font(.system(size: 12))
                                .buttonStyle(.link)
                            }
                            .padding(.horizontal, 12)
                        }
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

        // 2. Clear website data for ALL space data stores (not just .default())
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        for space in SpaceManager.shared.spaces {
            let store = SpaceManager.shared.cookieDataStore(for: space)
            store.removeData(ofTypes: websiteDataTypes, modifiedSince: date) { }
        }

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

        // 9. Clear fireproofed domains
        FireproofDomains.shared.clearAll()

        // 9. Reset to default settings
        defaults.set(true, forKey: "contentBlockerEnabled")
        defaults.set(DarkModeManager.DarkModePreference.system.rawValue, forKey: "darkModePreference")
        defaults.set(true, forKey: "doNotTrackEnabled")
        defaults.set(false, forKey: "developerModeEnabled")
        defaults.set(true, forKey: "tabDiscardingEnabled")

        // 10. Reset DuckPlayer settings
        DuckPlayerSettings.shared.reset()

        // 10. Reset hasLaunchedBefore to show Welcome screen on next launch
        defaults.set(false, forKey: "hasLaunchedBefore")

        // 11. Close all tabs to force welcome screen
        DispatchQueue.main.async {
            self.tabManager.closeAllTabs()
        }
    }

    private let appSpecificKeys = [
        "userName", "contentBlockerEnabled", "darkModePreference",
        "doNotTrackEnabled", "developerModeEnabled", "tabDiscardingEnabled",
        "duckPlayerMode", "duckPlayerAskOverlayHidden"
    ]
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FilterListRow: View {
    let filterList: FilterList
    let onToggle: (Bool) -> Void
    
    @State private var isEnabled: Bool
    
    init(filterList: FilterList, onToggle: @escaping (Bool) -> Void) {
        self.filterList = filterList
        self.onToggle = onToggle
        self._isEnabled = State(initialValue: filterList.isEnabled)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(filterList.name)
                    .font(.system(size: 13, weight: .medium))
                
                Text(filterList.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let ruleCount = filterList.ruleCount {
                    Text("\(ruleCount) rules")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    onToggle(newValue)
                }
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct SpaceCookieSettingsRow: View {
    let space: Space
    @State private var blockAllCookies: Bool
    
    init(space: Space) {
        self.space = space
        self._blockAllCookies = State(initialValue: space.blockAllCookies)
    }
    
    var body: some View {
        HStack {
            Image(systemName: space.icon)
                .foregroundColor(Color(space.color))
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(space.name)
                    .font(.system(size: 14, weight: .medium))
                
                if space.isPrivate {
                    Text("Private space - cookies always blocked")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else if blockAllCookies {
                    Text("All cookies blocked")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text("Cookies allowed")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if space.isPrivate {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            } else {
                Toggle("", isOn: $blockAllCookies)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: blockAllCookies) { _, newValue in
                        updateSpaceBlockCookies(newValue)
                    }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func updateSpaceBlockCookies(_ blocked: Bool) {
        var updatedSpace = space
        updatedSpace.blockAllCookies = blocked
        
        if let index = SpaceManager.shared.spaces.firstIndex(where: { $0.id == space.id }) {
            SpaceManager.shared.spaces[index] = updatedSpace
            SpaceManager.shared.saveSpaces()
        }
    }
}

struct FireproofDomainsSection: View {
    @ObservedObject private var fireproof = FireproofDomains.shared
    @State private var newDomain = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fireproof Domains")
                        .font(.system(size: 14, weight: .medium))
                    Text("Preserve login sessions when clearing data")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Add domain field
            HStack(spacing: 8) {
                TextField("e.g. github.com", text: $newDomain)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onSubmit { addDomain() }

                Button("Add") { addDomain() }
                    .buttonStyle(.bordered)
                    .font(.system(size: 12))
                    .disabled(newDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 4)

            // Domain list
            if !fireproof.domains.isEmpty {
                ForEach(Array(fireproof.domains).sorted(), id: \.self) { domain in
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text(domain)
                            .font(.system(size: 12))
                        Spacer()
                        Button(action: { fireproof.remove(domain) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                Text("No fireproofed domains. Add sites you want to keep logged in.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }

    private func addDomain() {
        let trimmed = newDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        fireproof.add(trimmed)
        newDomain = ""
    }
}
