//
//  BrowserView.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI

struct BrowserView: View {
    @StateObject var tabManager = TabManager()
    @StateObject var bookmarkManager = BookmarkManager()
    @FocusState private var isAddressBarFocused: Bool
    
    // Sidebar State
    @State private var isSidebarHovered: Bool = false
    @State private var hoveredTab: UUID?

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar (Tabs)
            sidebarView
                .zIndex(1)

            // MARK: - Main Content
            VStack(spacing: 0) {
                topToolbar
                
                Divider()
                
                // Show Home Page if URL is empty, otherwise show WebView
                if let currentTab = tabManager.currentTab, currentTab.url.isEmpty {
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
        }
        .background(.ultraThinMaterial)
        .background(shortcuts)
    }

    // MARK: - Sidebar View
    private var sidebarView: some View {
        ZStack(alignment: .leading) {

            // Background visual material
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Sidebar Content
            VStack(spacing: 0) {
                // Window Controls Spacer (Ensure it's high enough for traffic lights)
                Color.clear.frame(height: 40)
                
                // Tab List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(tabManager.tabs) { tab in
                            SidebarTabButton(
                                tab: tab,
                                isCurrent: tabManager.currentTab?.id == tab.id,
                                isSidebarHovered: isSidebarHovered,
                                hoveredTabId: $hoveredTab,
                                onClose: {
                                    withAnimation { tabManager.closeTab(tab) }
                                },
                                onSelect: {
                                    tabManager.switchToTab(tab)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // New Tab Button
                Button(action: { tabManager.addTab() }) {
                    HStack(spacing: isSidebarHovered ? 8 : 0) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 36, height: 36)
                        
                        if isSidebarHovered {
                            Text("New Tab")
                                .font(.system(size: 13))
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: isSidebarHovered ? .leading : .center)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
        .frame(width: isSidebarHovered ? 200 : 50)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSidebarHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarHovered)
        .overlay(Divider().frame(maxWidth: 1), alignment: .trailing)
    }

    // MARK: - Top Toolbar
    private var topToolbar: some View {
        HStack(spacing: 12) {
            // Navigation Controls
            HStack(spacing: 6) {
                Button(action: { tabManager.currentTab?.webView.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .disabled(!(tabManager.currentTab?.webView.canGoBack ?? false))
                .foregroundColor((tabManager.currentTab?.webView.canGoBack ?? false) ? .primary : .secondary.opacity(0.5))
                
                Button(action: { tabManager.currentTab?.webView.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .disabled(!(tabManager.currentTab?.webView.canGoForward ?? false))
                .foregroundColor((tabManager.currentTab?.webView.canGoForward ?? false) ? .primary : .secondary.opacity(0.5))
                
                Button(action: { tabManager.currentTab?.webView.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 10)

            // Address Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                TextField("Search or URL",
                          text: $tabManager.addressBarText)
                    .onSubmit {
                        print("DEBUG: TopToolbar TextField .onSubmit triggered")
                        // Only load if the address bar is actually focused to prevent intercepting Enter keys from the WebView
                        if isAddressBarFocused {
                            tabManager.loadCurrent()
                        }
                    }
                    .textFieldStyle(.plain)
                    .focused($isAddressBarFocused)
                    .disableAutocorrection(true)
                
                // Fix for macOS system beep: Explicitly capture the Enter key
                Button(action: {
                    print("DEBUG: TopToolbar Default Action triggered")
                    if isAddressBarFocused {
                        tabManager.loadCurrent()
                    }
                }) {
                    Text("Go")
                }
                .keyboardShortcut(.defaultAction)
                .opacity(0)
                .frame(width: 0, height: 0)
            }
            .padding(6)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )

            // Bookmarks / Menu
            HStack(spacing: 8) {
                Menu {
                    Button(action: {
                        if let current = tabManager.currentTab, !current.url.isEmpty {
                            bookmarkManager.addBookmark(title: current.title, url: current.url)
                        }
                    }) {
                        Label("Add Bookmark", systemImage: "plus")
                    }
                    
                    if !bookmarkManager.bookmarks.isEmpty {
                        Divider()
                        ForEach(bookmarkManager.bookmarks) { bm in
                            Button(bm.title) {
                                tabManager.addressBarText = bm.url
                                tabManager.loadCurrent()
                            }
                        }
                    }
                } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 10)
        }
        .padding(.vertical, 8)
        .frame(height: 44)
    }

    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            if let currentTab = tabManager.currentTab {
                WebViewContainer(webView: currentTab.webView.webView)
                    .id(currentTab.id) // Ensure view rebuilds on tab switch
                    .onTapGesture {
                        isAddressBarFocused = false
                    }
            } else {
                Text("No Tab Open")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // MARK: - Shortcuts
    private var shortcuts: some View {
        Group {
            Button("") { tabManager.addTab() }.keyboardShortcut("t", modifiers: .command)
            Button("") { if let tab = tabManager.currentTab { tabManager.closeTab(tab) } }.keyboardShortcut("w", modifiers: .command)
            Button("") { isAddressBarFocused = true }.keyboardShortcut("l", modifiers: .command)
            Button("") { tabManager.currentTab?.webView.reload() }.keyboardShortcut("r", modifiers: .command)
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
            Button("") { tabManager.currentTab?.webView.zoomIn() }.keyboardShortcut("=", modifiers: .command)
            Button("") { tabManager.currentTab?.webView.zoomOut() }.keyboardShortcut("-", modifiers: .command)
            Button("") { tabManager.currentTab?.webView.resetZoom() }.keyboardShortcut("0", modifiers: .command)
            Button("") {
                if let url = tabManager.currentTab?.url {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                }
            }.keyboardShortcut("c", modifiers: [.command, .shift])
        }
        .opacity(0)
    }
}

// MARK: - Extracted Tab Button for Observation
struct SidebarTabButton: View {
    @ObservedObject var tab: BrowserTab
    var isCurrent: Bool
    var isSidebarHovered: Bool
    @Binding var hoveredTabId: UUID?
    var onClose: () -> Void
    var onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Favicon / Indicator
            ZStack {
                if isCurrent {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 16, height: 16, alignment: .center)
            
            // Title (Visible only when expanded)
            if isSidebarHovered {
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .lineLimit(1)
                    .font(.system(size: 13))
                    .foregroundColor(isCurrent ? .primary : .secondary)
                
                Spacer()
                
                // Close Button
                if isCurrent || hoveredTabId == tab.id {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(
            isCurrent
            ? Color.primary.opacity(0.1)
            : (hoveredTabId == tab.id ? Color.primary.opacity(0.05) : Color.clear)
        )
        .cornerRadius(8)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            hoveredTabId = hovering ? tab.id : nil
        }
    }
}
