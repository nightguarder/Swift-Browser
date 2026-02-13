//
//  BrowserView.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI
import Combine

struct BrowserView: View {
    @StateObject var tabManager = TabManager()
    @StateObject var bookmarkManager = BookmarkManager.shared
    @StateObject var historyManager = HistoryManager.shared
    @StateObject var findInPageManager = FindInPageManager()
    
    @FocusState private var isAddressBarFocused: Bool
    @AppStorage("userName") private var userName: String = "User"

    // Sidebar State
    @State private var isSidebarHovered: Bool = false
    @State private var hoveredTab: UUID?

    // Menu State
    @State private var isMenuExpanded: Bool = false

    // Tab Search State
    @State private var isTabSearchVisible: Bool = false
    @State private var tabSearchText: String = ""
    @State private var sidebarSearchText: String = ""
    @State private var selectedSearchIndex: Int = 0
    @FocusState private var isTabSearchFocused: Bool
    @FocusState private var isSidebarSearchFocused: Bool
    
    // Address Bar Suggestions State
    @State private var selectedSuggestionIndex: Int = -1
    @State private var keyEventMonitor: Any?

    init() {}

    public var body: some View {
        mainContentView
            .background(.ultraThinMaterial)
            .background(shortcuts)
            .overlay(addressBarSuggestionsOverlay)
            .overlay(controlCenterMenuOverlay)
            .onAppear {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            .overlay(
                Group {
                    if findInPageManager.isVisible {
                        VStack {
                             FindBarView(
                                  manager: findInPageManager,
                                  onNext: { findInPageManager.findNext(webView: tabManager.currentTab?.webView?.webView) },
                                  onPrevious: { findInPageManager.findPrevious(webView: tabManager.currentTab?.webView?.webView) },
                                  onClose: { findInPageManager.stopFinding(webView: tabManager.currentTab?.webView?.webView) }
                              )
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            )
            .onReceive(
                findInPageManager.$searchText
                    .removeDuplicates()
                    .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
             ) { value in
                findInPageManager.find(value, webView: tabManager.currentTab?.webView?.webView)
             }
            .overlay(
                TabSearchOverlay(
                    tabManager: tabManager,
                    isTabSearchVisible: $isTabSearchVisible,
                    tabSearchText: $tabSearchText,
                    selectedSearchIndex: $selectedSearchIndex,
                    isTabSearchFocused: $isTabSearchFocused
                )
            )
            .overlay(
                Group {
                    if let currentTab = tabManager.currentTab,
                       let webViewManager = currentTab.webView,
                       webViewManager.duckPlayer.isPresented,
                       let videoID = webViewManager.duckPlayer.currentVideoID {
                        DuckPlayerView(videoID: videoID, manager: webViewManager.duckPlayer)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ZStack {
            // Main Content Area
            mainContentArea

            // Sidebar Overlay
            HStack {
                SidebarView(
                    tabManager: tabManager,
                    isSidebarHovered: $isSidebarHovered,
                    tabSearchText: $sidebarSearchText,
                    isTabSearchFocused: $isSidebarSearchFocused,
                    hoveredTab: $hoveredTab
                )
                .frame(maxHeight: .infinity)
                .zIndex(10)
                Spacer()
            }
            .onChange(of: tabSearchText) { _, newValue in
                if !newValue.isEmpty {
                    selectedSearchIndex = 0
                    // Tab search overlay is already controlled by isTabSearchVisible in shortcuts
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Content Area
    private var mainContentArea: some View {
        VStack(spacing: 0) {
            TopToolbar(
                tabManager: tabManager,
                bookmarkManager: bookmarkManager,
                historyManager: historyManager,
                isAddressBarFocused: $isAddressBarFocused,
                isMenuExpanded: $isMenuExpanded
            )
            .zIndex(1)
            
            Divider()
            
            // Show Settings or Home Page or WebView
            if let currentTab = tabManager.currentTab, currentTab.url == "swiftbrowser://settings" {
                SettingsView(tabManager: tabManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentTab = tabManager.currentTab, currentTab.url == "swiftbrowser://history" {
                HistoryView(tabManager: tabManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentTab = tabManager.currentTab, currentTab.url == "swiftbrowser://bookmarks" {
                BookmarksView(tabManager: tabManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentTab = tabManager.currentTab, currentTab.url == "swiftbrowser://cookies" {
                let space = SpaceManager.shared.spaces.first { $0.id == currentTab.spaceId } ?? SpaceManager.shared.activeSpace
                CookiesView(dataStore: SpaceManager.shared.websiteDataStore(for: space))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentTab = tabManager.currentTab, currentTab.url == "swiftbrowser://shortcuts" {
                ShortcutsView(tabManager: tabManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentTab = tabManager.currentTab, currentTab.url.isEmpty {
                let space = SpaceManager.shared.spaces.first { $0.id == currentTab.spaceId } ?? SpaceManager.shared.activeSpace
                HomePage(onSearch: { query in
                    tabManager.addressBarText = query
                    tabManager.loadCurrent()
                }, bookmarks: bookmarkManager.bookmarks, isPrivate: space.isPrivate)
            } else {
                contentArea
            }
        }
        .padding(.leading, 50) // Fixed padding for collapsed sidebar
    }
    
    // MARK: - Address Bar Suggestions Overlay
    @ViewBuilder
    private var addressBarSuggestionsOverlay: some View {
        if isAddressBarFocused {
            // Full screen overlay to catch clicks outside suggestions
            ZStack {
                // Transparent background that catches taps
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isAddressBarFocused = false
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                
                // Suggestions positioned below the address bar
                VStack(spacing: 0) {
                    // Position exactly at the bottom edge of the toolbar
                    Color.clear
                        .frame(height: AppSpacing.toolbarHeight - 8)
                    
                    // Center the suggestions under the address bar
                    HStack {
                        Spacer()
                        
                        AddressBarSuggestionsView(
                            tabManager: tabManager,
                            bookmarkManager: bookmarkManager,
                            historyManager: historyManager,
                            isFocused: Binding(
                                get: { isAddressBarFocused },
                                set: { isAddressBarFocused = $0 }
                            ),
                            selectedIndex: $selectedSuggestionIndex
                        )
                        .frame(minWidth: 400, idealWidth: 600, maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .padding(.leading, AppSpacing.navControlsWidth + AppSpacing.horizontalPadding + 8) // Shift right a bit
                    .padding(.trailing, AppSpacing.menuButtonWidth + AppSpacing.horizontalPadding)
                    
                    Spacer()
                }
            }
            .onAppear {
                setupKeyboardMonitor()
            }
            .onDisappear {
                removeKeyboardMonitor()
            }
        }
    }
    
    private func setupKeyboardMonitor() {
        // Remove any existing monitor
        removeKeyboardMonitor()
        
        // Setup local monitor for key events when suggestions are showing
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isAddressBarFocused else { return event }
            
            switch event.keyCode {
            case 125: // Down arrow
                self.handleSuggestionNavigation(direction: .down)
                return nil // Consume event
            case 126: // Up arrow
                self.handleSuggestionNavigation(direction: .up)
                return nil // Consume event
            case 36: // Return
                self.handleSuggestionSelection()
                return nil // Consume event
            case 53: // Escape
                self.isAddressBarFocused = false
                NSApp.keyWindow?.makeFirstResponder(nil)
                return nil // Consume event
            default:
                return event // Pass through
            }
        }
    }
    
    private func removeKeyboardMonitor() {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
    }
    
    private enum NavigationDirection {
        case up, down
    }
    
    private func handleSuggestionNavigation(direction: NavigationDirection) {
        // Get current suggestion count
        let query = tabManager.addressBarText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        // Build suggestions list to get accurate count - must match AddressBarSuggestionsView logic
        var suggestions: [(title: String, url: String)] = []
        
        // Check if we're in a private space
        let currentSpaceId = SpaceManager.shared.activeSpaceId
        let isPrivateSpace = SpaceManager.shared.spaces.first { $0.id == currentSpaceId }?.isPrivate ?? false
        
        // Only show history and bookmarks in non-private spaces
        if !isPrivateSpace {
            // Add bookmarks
            suggestions.append(contentsOf: bookmarkManager.bookmarks
                .filter { $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query) }
                .prefix(5)
                .map { (title: $0.title, url: $0.url) })
            
            // Add history
            suggestions.append(contentsOf: historyManager.history
                .filter { ($0.title?.lowercased().contains(query) ?? false) || $0.url.absoluteString.lowercased().contains(query) }
                .prefix(5)
                .map { (title: $0.title ?? "Untitled", url: $0.url.absoluteString) })
        }
        
        // Add search option
        suggestions.append((title: "Search with DuckDuckGo", url: query))
        
        let suggestionCount = min(suggestions.count, 8)
        guard suggestionCount > 0 else { return }
        
        switch direction {
        case .down:
            selectedSuggestionIndex = min(suggestionCount - 1, selectedSuggestionIndex + 1)
        case .up:
            selectedSuggestionIndex = max(0, selectedSuggestionIndex - 1)
        }
    }
    
    private func handleSuggestionSelection() {
        let query = tabManager.addressBarText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            isAddressBarFocused = false
            NSApp.keyWindow?.makeFirstResponder(nil)
            tabManager.loadCurrent()
            return
        }
        
        // Build suggestions list to find the selected one - must match navigation logic
        var suggestions: [(title: String, url: String)] = []
        
        // Check if we're in a private space
        let currentSpaceId = SpaceManager.shared.activeSpaceId
        let isPrivateSpace = SpaceManager.shared.spaces.first { $0.id == currentSpaceId }?.isPrivate ?? false
        
        // Only show history and bookmarks in non-private spaces
        if !isPrivateSpace {
            // Add bookmarks
            suggestions.append(contentsOf: bookmarkManager.bookmarks
                .filter { $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query) }
                .prefix(5)
                .map { (title: $0.title, url: $0.url) })
            
            // Add history
            suggestions.append(contentsOf: historyManager.history
                .filter { ($0.title?.lowercased().contains(query) ?? false) || $0.url.absoluteString.lowercased().contains(query) }
                .prefix(5)
                .map { (title: $0.title ?? "Untitled", url: $0.url.absoluteString) })
        }
        
        // Add search option
        suggestions.append((title: "Search with DuckDuckGo", url: query))
        
        suggestions = Array(suggestions.prefix(8))
        
        if selectedSuggestionIndex >= 0 && selectedSuggestionIndex < suggestions.count {
            // Load selected suggestion
            tabManager.addressBarText = suggestions[selectedSuggestionIndex].url
            tabManager.loadCurrent()
        } else {
            // No selection, load current text as search
            tabManager.loadCurrent()
        }
        
        isAddressBarFocused = false
        NSApp.keyWindow?.makeFirstResponder(nil)
        selectedSuggestionIndex = -1
    }

    // MARK: - Control Center Menu Overlay
    @ViewBuilder
    private var controlCenterMenuOverlay: some View {
        if isMenuExpanded {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Color.clear.frame(height: 44) // Matches Toolbar Height
                    
                    ControlCenterMenuView(isExpanded: $isMenuExpanded, tabManager: tabManager)
                        .frame(width: 260)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.trailing, 10)
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isMenuExpanded = false
                        }
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isMenuExpanded)
        }
    }

    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            if let currentTab = tabManager.currentTab, let webView = currentTab.webView?.webView {
                WebViewContainer(webView: webView)
                    .id(currentTab.id)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Shortcuts
    @ViewBuilder
    private var shortcuts: some View {
        ZStack {
            Button("") { tabManager.addTab() }.keyboardShortcut("t", modifiers: .command)
            Button("") { tabManager.reopenClosedTab() }.keyboardShortcut("t", modifiers: [.command, .shift])
            Button("") { if let tab = tabManager.currentTab { tabManager.closeTab(tab) } }.keyboardShortcut("w", modifiers: .command)
            Button("") { NSApp.keyWindow?.close() }.keyboardShortcut("w", modifiers: [.command, .shift])
            Button("") { isAddressBarFocused = true }.keyboardShortcut("l", modifiers: .command)
            Button("") { tabManager.currentTab?.webView?.reload() }.keyboardShortcut("r", modifiers: .command)
            Button("") { tabManager.nextTab() }.keyboardShortcut("]", modifiers: [.command, .shift])
            Button("") { tabManager.previousTab() }.keyboardShortcut("[", modifiers: [.command, .shift])
            Button("") { tabManager.nextTab() }.keyboardShortcut(.tab, modifiers: .control)
            Button("") { tabManager.previousTab() }.keyboardShortcut(.tab, modifiers: [.control, .shift])
            Button("") { tabManager.switchToIndex(0) }.keyboardShortcut("1", modifiers: .command)
            Button("") { tabManager.switchToIndex(1) }.keyboardShortcut("2", modifiers: .command)
            Button("") { tabManager.switchToIndex(2) }.keyboardShortcut("3", modifiers: .command)
            Button("") { tabManager.switchToIndex(3) }.keyboardShortcut("4", modifiers: .command)
            Button("") { tabManager.switchToIndex(4) }.keyboardShortcut("5", modifiers: .command)
            Button("") { tabManager.switchToIndex(5) }.keyboardShortcut("6", modifiers: .command)
            Button("") { tabManager.switchToIndex(6) }.keyboardShortcut("7", modifiers: .command)
            Button("") { tabManager.switchToIndex(7) }.keyboardShortcut("8", modifiers: .command)
            Button("") { tabManager.switchToIndex(8) }.keyboardShortcut("9", modifiers: .command)
            Button("") { tabManager.currentTab?.webView?.zoomIn() }.keyboardShortcut("=", modifiers: .command)
            Button("") { tabManager.currentTab?.webView?.zoomOut() }.keyboardShortcut("-", modifiers: .command)
            Button("") { tabManager.currentTab?.webView?.resetZoom() }.keyboardShortcut("0", modifiers: .command)
            // Duplicate current tab
            Button("") { tabManager.duplicateCurrentTab() }.keyboardShortcut("d", modifiers: .command)
            Button("") {
                // Get the actual URL to copy: prefer webView's URL, then address bar text
                var urlToCopy: String? = nil
                
                if let webViewURL = tabManager.currentTab?.webView?.currentURL?.absoluteString,
                   !webViewURL.isEmpty,
                   !webViewURL.hasPrefix("swiftbrowser://") {
                    urlToCopy = webViewURL
                } else if let tabURL = tabManager.currentTab?.url,
                          !tabURL.isEmpty,
                          !tabURL.hasPrefix("swiftbrowser://") {
                    urlToCopy = tabURL
                } else if !tabManager.addressBarText.isEmpty,
                          !tabManager.addressBarText.hasPrefix("swiftbrowser://") {
                    urlToCopy = tabManager.addressBarText
                }
                
                if let url = urlToCopy {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                }
            }.keyboardShortcut("c", modifiers: [.command, .option])
            Button("") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isTabSearchVisible.toggle()
                    if isTabSearchVisible {
                        isTabSearchFocused = true
                    }
                }
            }.keyboardShortcut("k", modifiers: .command)
            Button("") { tabManager.openBookmarks() }.keyboardShortcut("b", modifiers: [.command, .option])
            Button("") { tabManager.openHistory() }.keyboardShortcut("y", modifiers: .command)
            Button("") { tabManager.openShortcuts() }.keyboardShortcut("/", modifiers: [.command, .shift])
            Button("") {
                withAnimation {
                    findInPageManager.isVisible.toggle()
                    if !findInPageManager.isVisible {
                         findInPageManager.stopFinding(webView: tabManager.currentTab?.webView?.webView)
                     }
                 }
             }.keyboardShortcut("f", modifiers: .command)
            
            Button("") {
                NotificationCenter.default.post(name: .toggleDownloadsPopover, object: nil)
            }.keyboardShortcut("j", modifiers: .command)
            
            // Developer Tools
            Button("") { 
                #if os(macOS)
                if UserDefaults.standard.bool(forKey: "developerModeEnabled") {
                    tabManager.currentTab?.webView?.webView.perform(Selector(("_showDeveloperTools:")))
                }
                #endif
            }
            .keyboardShortcut(.init(Character(UnicodeScalar(0xF70F)!)), modifiers: [])
            
            Button("") { 
                #if os(macOS)
                if UserDefaults.standard.bool(forKey: "developerModeEnabled") {
                    tabManager.currentTab?.webView?.webView.perform(Selector(("_showDeveloperTools:")))
                }
                #endif
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
}
