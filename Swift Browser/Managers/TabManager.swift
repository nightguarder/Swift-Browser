//
//  TabManager.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI
import WebKit
import Combine

final class TabManager: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var currentTab: BrowserTab?
    @Published var addressBarText: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        addTab() // start with one tab open
    }

    func addTab() {
        let webView = WebViewManager()
        let newTab = BrowserTab(title: "Home", url: "", webView: webView)
        
        // Subscribe to WebView updates
        webView.$currentURL
            .compactMap { $0?.absoluteString }
            .sink { [weak newTab] url in
                newTab?.url = url
            }
            .store(in: &cancellables)
            
        webView.$pageTitle
            .compactMap { $0 }
            .sink { [weak newTab] title in
                newTab?.title = title
            }
            .store(in: &cancellables)
            
        // Update address bar if this is the current tab
        webView.$currentURL
            .filter { [weak self] _ in self?.currentTab?.id == newTab.id }
            .compactMap { $0?.absoluteString }
            .sink { [weak self] url in
                self?.addressBarText = url
            }
            .store(in: &cancellables)

        tabs.append(newTab)
        currentTab = newTab
        addressBarText = ""
    }

    func closeTab(_ tab: BrowserTab) {
        tabs.removeAll { $0.id == tab.id }
        if currentTab?.id == tab.id {
            currentTab = tabs.last
            addressBarText = currentTab?.url ?? ""
        }
    }

    func switchToTab(_ tab: BrowserTab) {
        currentTab = tab
        addressBarText = tab.url
    }

    func nextTab() {
        guard let current = currentTab, let index = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        let nextIndex = (index + 1) % tabs.count
        switchToTab(tabs[nextIndex])
    }

    func previousTab() {
        guard let current = currentTab, let index = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        let prevIndex = (index - 1 + tabs.count) % tabs.count
        switchToTab(tabs[prevIndex])
    }

    func switchToIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        switchToTab(tabs[index])
    }

    func loadCurrent() {
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
