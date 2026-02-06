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

    init() {}

    public var body: some View {
        mainContentView
            .background(.ultraThinMaterial)
            .background(shortcuts)
            .overlay(controlCenterMenuOverlay)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full window coverage for overlays
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
            } else if let currentTab = tabManager.currentTab, currentTab.url == "swiftbrowser://shortcuts" {
                ShortcutsView(tabManager: tabManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentTab = tabManager.currentTab, currentTab.url.isEmpty {
                HomePage(onSearch: { query in
                    tabManager.addressBarText = query
                    tabManager.loadCurrent()
                }, bookmarks: bookmarkManager.bookmarks)
            } else {
                contentArea
                    .onTapGesture {
                        isAddressBarFocused = false
                    }
            }
        }
        .padding(.leading, 50) // Fixed padding for collapsed sidebar
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
        ZStack {
            ForEach(tabManager.tabs, id: \.id) { tab in
                Group {
                    if let webView = tab.webView?.webView {
                        WebViewContainer(webView: webView)
                    } else if tab.id == tabManager.currentTab?.id {
                        // If the selected tab was discarded, TabManager restores it on selection.
                        // Show a lightweight fallback while it restores.
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Keep a placeholder to avoid tearing down view hierarchy for non-selected tabs
                        Color.clear
                    }
                }
                .id(tab.id)
                .opacity(tab.id == tabManager.currentTab?.id ? 1 : 0)
                .allowsHitTesting(tab.id == tabManager.currentTab?.id)
            }
        }
    }
    
    // MARK: - Shortcuts
    private var shortcuts: some View {
        Group {
            Button("") { tabManager.addTab() }.keyboardShortcut("t", modifiers: .command)
            Button("") { if let tab = tabManager.currentTab { tabManager.closeTab(tab) } }.keyboardShortcut("w", modifiers: .command)
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
                if let url = tabManager.currentTab?.url {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                }
            }.keyboardShortcut("c", modifiers: [.command, .shift])
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
        }
        .opacity(0)
    }
}
