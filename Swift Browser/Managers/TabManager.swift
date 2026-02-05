//
//  TabManager.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI
import WebKit
import Combine

public final class TabManager: ObservableObject {
    @Published public var tabs: [BrowserTab] = []
    @Published public var currentTab: BrowserTab?
    @Published public var addressBarText: String = ""
    @Published public var previousTabId: UUID?

    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupActiveTabObservation()
        addTab() // start with one tab open
    }

    deinit {
        for tab in tabs {
            tab.webView.teardown()
        }
        cancellables.removeAll()
    }

    private func setupActiveTabObservation() {
        // Observe currentTab changes and subscribe to its webView's URL
        $currentTab
            .receive(on: DispatchQueue.main)
            .map { tab -> AnyPublisher<String, Never> in
                guard let tab else {
                    return Just("").eraseToAnyPublisher()
                }

                // Return the current URL or the tab's internal URL if it's an internal page.
                // Use switchToLatest downstream so we don't keep subscriptions to background tabs.
                return tab.webView.$currentURL
                    .map { $0?.absoluteString ?? tab.url }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] value in
                self?.addressBarText = value
            }
            .store(in: &cancellables)
    }

    public func addTab() {
        let webView = WebViewManager()
        let newTab = BrowserTab(title: "Home", url: "", webView: webView)
        
        // Track previous tab before switching
        if let current = currentTab {
            previousTabId = current.id
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tabs.append(newTab)
            currentTab = newTab
        }
    }

    public func closeTab(_ tab: BrowserTab) {
        let wasCurrent = currentTab?.id == tab.id

        // Proactively tear down WebKit resources before releasing the tab.
        tab.webView.teardown()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tabs.removeAll { $0.id == tab.id }
            
            if wasCurrent {
                if let prevId = previousTabId, let prevTab = tabs.first(where: { $0.id == prevId }) {
                    switchToTab(prevTab)
                    previousTabId = nil // Clear it after returning
                } else {
                    currentTab = tabs.last
                    addressBarText = currentTab?.url ?? ""
                }
            }
        }
    }

    public func switchToTab(_ tab: BrowserTab) {
        if let current = currentTab, current.id != tab.id {
            previousTabId = current.id
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentTab = tab
            addressBarText = tab.url
        }
    }

    public func nextTab() {
        guard let current = currentTab, let index = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        let nextIndex = (index + 1) % tabs.count
        switchToTab(tabs[nextIndex])
    }

    public func previousTab() {
        guard let current = currentTab, let index = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        let prevIndex = (index - 1 + tabs.count) % tabs.count
        switchToTab(tabs[prevIndex])
    }

    public func switchToIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        switchToTab(tabs[index])
    }

    public func openSettings() {
        // Check if settings tab already exists
        if let settingsTab = tabs.first(where: { $0.url == "swiftbrowser://settings" }) {
            switchToTab(settingsTab)
        } else {
            let webView = WebViewManager()
            let settingsTab = BrowserTab(title: "Settings", url: "swiftbrowser://settings", webView: webView)
            tabs.append(settingsTab)
            switchToTab(settingsTab)
        }
        addressBarText = "Settings"
    }

    public func openHistory() {
        // Check if history tab already exists
        if let historyTab = tabs.first(where: { $0.url == "swiftbrowser://history" }) {
            switchToTab(historyTab)
        } else {
            let webView = WebViewManager()
            let historyTab = BrowserTab(title: "History", url: "swiftbrowser://history", webView: webView)
            tabs.append(historyTab)
            switchToTab(historyTab)
        }
        addressBarText = "History"
    }
    
    public func openShortcuts() {
        // Check if shortcuts tab already exists
        if let shortcutsTab = tabs.first(where: { $0.url == "swiftbrowser://shortcuts" }) {
            switchToTab(shortcutsTab)
        } else {
            let webView = WebViewManager()
            let shortcutsTab = BrowserTab(title: "Shortcuts", url: "swiftbrowser://shortcuts", webView: webView)
            tabs.append(shortcutsTab)
            switchToTab(shortcutsTab)
        }
        addressBarText = "Shortcuts"
    }
    
    public func loadCurrent() {
        #if DEBUG
        print("DEBUG: TabManager loadCurrent() called with text: '\(addressBarText)'")
        #endif
        guard let currentTab = currentTab else { 
            #if DEBUG
            print("DEBUG: loadCurrent failed - currentTab is nil")
            #endif
            return 
        }
        var input = addressBarText.trimmingCharacters(in: .whitespacesAndNewlines)

        if input.isEmpty {
            #if DEBUG
            print("DEBUG: loadCurrent detected empty input")
            #endif
            return
        }
        
        // Remove focus from all elements by injecting script
        currentTab.webView.webView.evaluateJavaScript("document.activeElement.blur()") { _, _ in }

        // If input looks like a URL (contains a dot or starts with http)
        if input.starts(with: "http://") || input.starts(with: "https://") {
            // valid full URL
        } else if input.contains(".") && !input.contains(" ") {
            input = "https://\(input)"
        } else {
            // Treat as DuckDuckGo search (Privacy First)
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            input = "https://duckduckgo.com/?q=\(query)"
        }

        #if DEBUG
        print("DEBUG: loadCurrent loading URL: \(input)")
        #endif
        currentTab.webView.load(input)
        currentTab.url = input
    }

    // Settings Propagation
    public func updateContentBlocker(enabled: Bool) {
        for tab in tabs {
            tab.webView.updateContentBlocker(enabled: enabled)
        }
    }

    public func updateDarkMode() {
        for tab in tabs {
            tab.webView.updateDarkMode()
        }
    }
    
    public func updateDeveloperMode(enabled: Bool) {
        for tab in tabs {
            tab.webView.updateDeveloperMode(enabled: enabled)
        }
    }
}
