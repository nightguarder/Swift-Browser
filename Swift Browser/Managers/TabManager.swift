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

    private func setupActiveTabObservation() {
        // Observe currentTab changes and subscribe to its webView's URL
        $currentTab
            .receive(on: DispatchQueue.main)
            .flatMap { tab -> AnyPublisher<String, Never> in
                guard let tab = tab else {
                    return Just("").eraseToAnyPublisher()
                }
                // Return the current URL or the tab's internal URL if it's an internal page
                return tab.webView.$currentURL
                    .map { $0?.absoluteString ?? tab.url }
                    .eraseToAnyPublisher()
            }
            .assign(to: &$addressBarText)
    }

    public func addTab() {
        let webView = WebViewManager()
        let newTab = BrowserTab(title: "Home", url: "", webView: webView)
        
        // Track previous tab before switching
        if let current = currentTab {
            previousTabId = current.id
        }
        
        tabs.append(newTab)
        currentTab = newTab
    }

    public func closeTab(_ tab: BrowserTab) {
        let wasCurrent = currentTab?.id == tab.id
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

    public func switchToTab(_ tab: BrowserTab) {
        if let current = currentTab, current.id != tab.id {
            previousTabId = current.id
        }
        currentTab = tab
        addressBarText = tab.url
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

    public func loadCurrent() {
        print("DEBUG: TabManager loadCurrent() called with text: '\(addressBarText)'")
        guard let currentTab = currentTab else { 
            print("DEBUG: loadCurrent failed - currentTab is nil")
            return 
        }
        var input = addressBarText.trimmingCharacters(in: .whitespacesAndNewlines)

        if input.isEmpty {
            print("DEBUG: loadCurrent detected empty input")
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

        print("DEBUG: loadCurrent loading URL: \(input)")
        currentTab.webView.load(input)
        currentTab.url = input
    }
}
