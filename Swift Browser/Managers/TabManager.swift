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

    private var idleDiscardTimerCancellable: AnyCancellable?
    
    /// Tracks tabs playing media across all spaces - these should never be discarded
    @Published public var mediaPlayingTabs: Set<UUID> = []
    
    /// Timer for discarding background space WebViews after switching
    private var backgroundSpaceDiscardWorkItem: DispatchWorkItem?

    private var tabDiscardingEnabled: Bool {
        if UserDefaults.standard.object(forKey: "tabDiscardingEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "tabDiscardingEnabled")
    }

    private let idleDiscardInterval: TimeInterval = 15 * 60
    private let idleDiscardCheckInterval: TimeInterval = 60

    public init() {
        setupActiveTabObservation()
        configureIdleDiscardTimer()
        setupSessionPersistence()
        
        // Try to restore session, otherwise add default tab
        if !restoreSession() {
            addTab() // start with one tab open
        }
    }

    deinit {
        for tab in tabs {
            tab.webView?.teardown()
        }
        idleDiscardTimerCancellable?.cancel()
        idleDiscardTimerCancellable = nil
        backgroundSpaceDiscardWorkItem?.cancel()
        backgroundSpaceDiscardWorkItem = nil
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
                return tab.$webView
                    .map { manager -> AnyPublisher<String, Never> in
                        if let manager {
                            return manager.$currentURL
                                .map { $0?.absoluteString ?? tab.url }
                                .merge(with: tab.$url)
                                .eraseToAnyPublisher()
                        }
                        return tab.$url.eraseToAnyPublisher()
                    }
                    .switchToLatest()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] value in
                self?.addressBarText = value
            }
            .store(in: &cancellables)
    }

    public func addTab(url: String = "", in spaceId: UUID? = nil) {
        let sid = spaceId ?? SpaceManager.shared.activeSpaceId
        let title = url.isEmpty ? "Home" : (url.hasPrefix("swiftbrowser://") ? url.replacingOccurrences(of: "swiftbrowser://", with: "").capitalized : "Loading...")
        let newTab = BrowserTab(title: title, url: url, spaceId: sid, webView: nil)
        
        // Track previous tab before switching
        if let current = currentTab {
            previousTabId = current.id
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tabs.append(newTab)
            currentTab = newTab
        }

        discardNonWebTabs()
        
        if !url.isEmpty && !url.hasPrefix("swiftbrowser://") {
            restoreTabIfNeeded(newTab)
        }
    }

    /// Handles opening a new tab from a WebKit-provided configuration (e.g. window.open)
    public func addTab(configuration: WKWebViewConfiguration, in spaceId: UUID? = nil) -> WKWebView? {
        let sid = spaceId ?? currentTab?.spaceId ?? SpaceManager.shared.activeSpaceId
        let space = SpaceManager.shared.spaces.first(where: { $0.id == sid }) ?? SpaceManager.shared.activeSpace
        
        let webViewManager = WebViewManager(dataStore: configuration.websiteDataStore, isPrivateSpace: space.isPrivate, configuration: configuration)
        let newTab = BrowserTab(title: "New Tab", url: "", spaceId: sid, webView: webViewManager)
        
        setupManagerCallbacks(webViewManager, for: newTab)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tabs.append(newTab)
            currentTab = newTab
        }
        
        return webViewManager.webView
    }

    public func closeTab(_ tab: BrowserTab) {
        let closingId = tab.id
        let wasCurrent = currentTab?.id == closingId

        // Remove from media playing tracking
        mediaPlayingTabs.remove(closingId)

        // Proactively tear down WebKit resources before releasing the tab.
        tab.webView?.teardown()
        tab.webView = nil

        if previousTabId == closingId {
            previousTabId = nil
        }

        var nextTab: BrowserTab?
        if wasCurrent {
            if let prevId = previousTabId, let prevTab = tabs.first(where: { $0.id == prevId }), prevTab.id != closingId {
                nextTab = prevTab
            } else if let idx = tabs.firstIndex(where: { $0.id == closingId }) {
                if idx > 0 {
                    nextTab = tabs[idx - 1]
                } else if idx + 1 < tabs.count {
                    nextTab = tabs[idx + 1]
                }
            }
            
            // Fallback: select any remaining tab
            if nextTab == nil {
                nextTab = tabs.first(where: { $0.id != closingId })
            }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tabs.removeAll { $0.id == closingId }

            if wasCurrent {
                currentTab = nextTab
                addressBarText = nextTab?.url ?? ""
                previousTabId = nil
            }
        }

        if let currentTab {
            currentTab.lastUsedAt = Date()
            restoreTabIfNeeded(currentTab)
        }

        discardNonWebTabs()
    }

    public func switchToTab(_ tab: BrowserTab) {
        if let current = currentTab, current.id != tab.id {
            previousTabId = current.id
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentTab = tab
            addressBarText = tab.url
        }

        tab.lastUsedAt = Date()

        restoreTabIfNeeded(tab)
        discardNonWebTabs()
    }

    public func switchSpace(to spaceId: UUID) {
        let availableSpaceIds = Set(SpaceManager.shared.spaces.map { $0.id })
        guard availableSpaceIds.contains(spaceId) else { return }
        
        // Store previous space ID before switching
        let previousSpaceId = SpaceManager.shared.activeSpaceId
        
        // FIX: Clear currentTab if it doesn't belong to the new space
        // This ensures we don't have a "ghost" current tab from another space
        if let current = currentTab, current.spaceId != spaceId {
            // Don't tear down yet - just clear the reference
            currentTab = nil
        }

        SpaceManager.shared.switchSpace(to: spaceId)

        let spaceTabs = tabs.filter { $0.spaceId == spaceId }
        if let lastUsed = spaceTabs.max(by: { ($0.lastUsedAt ?? Date.distantPast) < ($1.lastUsedAt ?? Date.distantPast) }) {
            switchToTab(lastUsed)
        } else {
            addTab(in: spaceId)
        }
        
        // Background space discarding: Schedule discarding of previous space WebViews after delay
        if previousSpaceId != spaceId {
            scheduleBackgroundSpaceDiscarding(previousSpaceId: previousSpaceId)
        }
    }
    
    /// Schedules discarding of WebViews from a background space after a delay
    private func scheduleBackgroundSpaceDiscarding(previousSpaceId: UUID) {
        // Cancel any existing scheduled discard
        backgroundSpaceDiscardWorkItem?.cancel()
        
        // Create new work item to discard background space WebViews after 10 seconds
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            print("TabManager: Discarding WebViews from background space \(previousSpaceId)")
            
            // Get current active space to make sure we don't discard it
            let activeSpaceId = SpaceManager.shared.activeSpaceId
            
            var discardedCount = 0
            for tab in self.tabs {
                // Only discard tabs from the previous space (not current space)
                guard tab.spaceId == previousSpaceId else { continue }
                guard tab.spaceId != activeSpaceId else { continue } // Safety check
                guard tab.webView != nil else { continue }
                
                // Don't discard tabs playing media (they might be background music)
                guard !self.mediaPlayingTabs.contains(tab.id) else { continue }
                
                // Don't discard if it's the current tab
                guard tab.id != self.currentTab?.id else { continue }
                
                self.discardTabWebView(tab)
                discardedCount += 1
            }
            
            if discardedCount > 0 {
                print("TabManager: Discarded \(discardedCount) WebViews from background space")
            }
        }
        
        backgroundSpaceDiscardWorkItem = workItem
        
        // Schedule after 10 seconds - gives user time to switch back if accidental
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: workItem)
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

    // Duplicate Tab
    public func duplicate(_ tab: BrowserTab) {
        let space = SpaceManager.shared.spaces.first(where: { $0.id == tab.spaceId }) ?? SpaceManager.shared.activeSpace
        let dataStore = SpaceManager.shared.websiteDataStore(for: space)
        let webView = WebViewManager(dataStore: dataStore, isPrivateSpace: space.isPrivate)
        let newTab = BrowserTab(title: tab.title, url: tab.url, spaceId: tab.spaceId, webView: webView)
        setupManagerCallbacks(webView, for: newTab)
        
        // Load same content if available
        if !tab.url.isEmpty {
            webView.load(tab.url)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
                tabs.insert(newTab, at: min(idx + 1, tabs.count))
            } else {
                tabs.append(newTab)
            }
            switchToTab(newTab)
        }
    }

    public func duplicateCurrentTab() {
        guard let current = currentTab else { return }
        duplicate(current)
    }

    // MARK: - Internal Pages
    
    public func openSettings() {
        openInternalPage(url: "swiftbrowser://settings")
    }
    
    public func openHistory() {
        openInternalPage(url: "swiftbrowser://history")
    }
    
    public func openBookmarks() {
        openInternalPage(url: "swiftbrowser://bookmarks")
    }
    
    public func openShortcuts() {
        openInternalPage(url: "swiftbrowser://shortcuts")
    }
    
    public func openCookies() {
        openInternalPage(url: "swiftbrowser://cookies")
    }
    
    private func openInternalPage(url: String) {
        if let existing = tabs.first(where: { $0.url == url && $0.spaceId == SpaceManager.shared.activeSpaceId }) {
            switchToTab(existing)
        } else {
            addTab(url: url)
        }
    }
    
    public func loadCurrent() {
        guard let currentTab = currentTab else { return }
        var input = addressBarText.trimmingCharacters(in: .whitespacesAndNewlines)

        if input.isEmpty { return }
        
        // Remove focus from all elements by injecting script
        let webViewManager = ensureWebView(for: currentTab)
        webViewManager.webView.evaluateJavaScript("document.activeElement.blur()") { _, _ in }

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

        webViewManager.load(input)
        currentTab.url = input
        currentTab.lastUsedAt = Date()

        discardNonWebTabs()
    }

    // Settings Propagation
    public func updateContentBlocker(enabled: Bool) {
        for tab in tabs {
            tab.webView?.updateContentBlocker(enabled: enabled)
        }
    }

    public func updateDarkMode() {
        for tab in tabs {
            tab.webView?.updateDarkMode()
        }
    }
    
    public func updateDeveloperMode(enabled: Bool) {
        for tab in tabs {
            tab.webView?.updateDeveloperMode(enabled: enabled)
        }
    }

    public func refreshTabDiscarding() {
        if let tab = currentTab {
            restoreTabIfNeeded(tab)
        }
        configureIdleDiscardTimer()
        discardNonWebTabs()
        discardIdleTabsIfNeeded()
    }

    // MARK: - Tab Discarding

    private func isInternalPage(_ urlString: String) -> Bool {
        urlString.hasPrefix("swiftbrowser://")
    }

    private func restoreTabIfNeeded(_ tab: BrowserTab) {
        // Internal pages and empty tabs don't need a WKWebView.
        if tab.url.isEmpty || isInternalPage(tab.url) {
            discardTabWebView(tab)
            return
        }

        if tab.webView == nil {
            let space = SpaceManager.shared.spaces.first(where: { $0.id == tab.spaceId }) ?? SpaceManager.shared.activeSpace
            let dataStore = SpaceManager.shared.websiteDataStore(for: space)
            let manager = WebViewManager(dataStore: dataStore, isPrivateSpace: space.isPrivate)
            setupManagerCallbacks(manager, for: tab)
            tab.webView = manager
            manager.load(tab.url)
        }
    }

    @discardableResult
    private func ensureWebView(for tab: BrowserTab) -> WebViewManager {
        if let manager = tab.webView {
            return manager
        }

        let space = SpaceManager.shared.spaces.first(where: { $0.id == tab.spaceId }) ?? SpaceManager.shared.activeSpace
        let dataStore = SpaceManager.shared.websiteDataStore(for: space)
        let manager = WebViewManager(dataStore: dataStore, isPrivateSpace: space.isPrivate)
        setupManagerCallbacks(manager, for: tab)
        tab.webView = manager
        return manager
    }

    private func setupManagerCallbacks(_ manager: WebViewManager, for tab: BrowserTab) {
        manager.onNewTabRequested = { [weak self] configuration in
            return self?.addTab(configuration: configuration, in: tab.spaceId)
        }
        
        manager.onCloseRequested = { [weak self] in
            self?.closeTab(tab)
        }
        
        // Monitor media playback state changes
        manager.onMediaPlaybackStateChanged = { [weak self] isPlaying in
            guard let self = self else { return }
            if isPlaying {
                self.mediaPlayingTabs.insert(tab.id)
            } else {
                self.mediaPlayingTabs.remove(tab.id)
            }
        }
    }

    private func discardNonWebTabs() {
        for tab in tabs {
            if tab.url.isEmpty || isInternalPage(tab.url) {
                discardTabWebView(tab)
            }
        }
    }

    private func discardTabWebView(_ tab: BrowserTab) {
        tab.webView?.teardown()
        tab.webView = nil
    }

    private func configureIdleDiscardTimer() {
        idleDiscardTimerCancellable?.cancel()
        idleDiscardTimerCancellable = nil

        guard tabDiscardingEnabled else { return }

        idleDiscardTimerCancellable = Timer
            .publish(every: idleDiscardCheckInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.discardIdleTabsIfNeeded()
            }
    }

    private func discardIdleTabsIfNeeded(now: Date = Date()) {
        guard tabDiscardingEnabled else { return }
        guard let currentID = currentTab?.id else { return }

        for tab in tabs {
            guard tab.id != currentID else { continue }
            guard tab.webView != nil else { continue }
            guard !tab.url.isEmpty && !isInternalPage(tab.url) else { continue }

            let idle = now.timeIntervalSince(tab.lastUsedAt)
            guard idle >= idleDiscardInterval else { continue }

            guard let manager = tab.webView else { continue }
            if manager.isLoading { continue }

            if #available(macOS 12.0, *) {
                let webView = manager.webView

                // Don't discard tabs that are capturing camera/mic.
                if webView.cameraCaptureState != .none { continue }
                if webView.microphoneCaptureState != .none { continue }

                // PRIORITY: Don't discard tabs playing media (even in other spaces)
                if mediaPlayingTabs.contains(tab.id) { continue }

                // Don't discard tabs that are currently playing media.
                let tabID = tab.id
                webView.requestMediaPlaybackState { [weak self] (state: WKMediaPlaybackState) in
                    guard let self = self else { return }
                    guard let liveTab = self.tabs.first(where: { $0.id == tabID }) else { return }
                    guard liveTab.id != self.currentTab?.id else { return }
                    guard let liveManager = liveTab.webView else { return }
                    if liveManager.isLoading { return }

                    // Re-check idle (tab might have been used since the tick).
                    let now2 = Date()
                    let idle2 = now2.timeIntervalSince(liveTab.lastUsedAt)
                    guard idle2 >= self.idleDiscardInterval else { return }

                    if state == .playing { 
                        // Track this tab as playing media
                        self.mediaPlayingTabs.insert(tabID)
                        return 
                    }

                    self.discardTabWebView(liveTab)
                }
            } else {
                discardTabWebView(tab)
            }
        }
    }
    
    // MARK: - Session Persistence
    
    private func setupSessionPersistence() {
        // Observe tabs array changes
        $tabs
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveSession()
            }
            .store(in: &cancellables)
        
        // Observe current tab changes
        $currentTab
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveSession()
            }
            .store(in: &cancellables)
        
        // Observe SpaceManager active space changes
        SpaceManager.shared.$activeSpaceId
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveSession()
            }
            .store(in: &cancellables)
        
        // Save immediately on app termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveSessionOnTermination),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func saveSessionOnTermination() {
        SessionPersistence.shared.saveSessionImmediately(
            tabs: tabs,
            currentTab: currentTab,
            activeSpaceId: SpaceManager.shared.activeSpaceId
        )
    }
    
    private func saveSession() {
        SessionPersistence.shared.saveSession(
            tabs: tabs,
            currentTab: currentTab,
            activeSpaceId: SpaceManager.shared.activeSpaceId
        )
    }
    
    @discardableResult
    private func restoreSession() -> Bool {
        guard let session = SessionPersistence.shared.loadSession() else {
            return false
        }
        
        // Get available space IDs (filter out any spaces that no longer exist)
        let availableSpaceIds = Set(SpaceManager.shared.spaces.map { $0.id })
        let validTabs = session.tabs.filter { availableSpaceIds.contains($0.spaceId) }
        
        guard !validTabs.isEmpty else {
            return false
        }
        
        // Restore tabs (without webviews - they'll be lazy loaded)
        var restoredTabs: [BrowserTab] = []
        for persistedTab in validTabs {
            let tab = BrowserTab(
                id: persistedTab.id,
                title: persistedTab.title,
                url: persistedTab.url,
                spaceId: persistedTab.spaceId,
                webView: nil,
                lastUsedAt: persistedTab.lastUsedAt
            )
            restoredTabs.append(tab)
        }
        
        self.tabs = restoredTabs
        
        // Restore active space if valid and not private
        if let activeSpaceId = session.activeSpaceId,
           availableSpaceIds.contains(activeSpaceId),
           let space = SpaceManager.shared.spaces.first(where: { $0.id == activeSpaceId }),
           !space.isPrivate {
            SpaceManager.shared.switchSpace(to: activeSpaceId)
        } else {
            // Switch to first non-private space
            if let defaultSpace = SpaceManager.shared.spaces.first(where: { !$0.isPrivate }) {
                SpaceManager.shared.switchSpace(to: defaultSpace.id)
            }
        }
        
        // Restore current tab by index
        let targetIndex = min(max(0, session.currentTabIndex), restoredTabs.count - 1)
        self.currentTab = restoredTabs[targetIndex]

        if let currentTab = self.currentTab {
            self.addressBarText = currentTab.url
            restoreTabIfNeeded(currentTab)
        }

        print("TabManager: Restored session with \(restoredTabs.count) tabs")
        return true
    }
}
