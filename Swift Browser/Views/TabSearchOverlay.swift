//
//  TabSearchOverlay.swift
//  Swift Browser
//
//  Created by opencode on 03/02/26.
//

import SwiftUI
import AppKit
import Combine

public struct TabSearchOverlay: View {
    @ObservedObject var tabManager: TabManager
    @Binding var isTabSearchVisible: Bool
    @Binding var tabSearchText: String
    @Binding var selectedSearchIndex: Int
    @FocusState.Binding var isTabSearchFocused: Bool
    
    @State private var keyboardMonitor: Any?
    
    public init(tabManager: TabManager, isTabSearchVisible: Binding<Bool>, tabSearchText: Binding<String>, selectedSearchIndex: Binding<Int>, isTabSearchFocused: FocusState<Bool>.Binding) {
        self.tabManager = tabManager
        self._isTabSearchVisible = isTabSearchVisible
        self._tabSearchText = tabSearchText
        self._selectedSearchIndex = selectedSearchIndex
        self._isTabSearchFocused = isTabSearchFocused
    }
    
    public var body: some View {
        if isTabSearchVisible {
            ZStack(alignment: .center) {
                // Backdrop
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isTabSearchVisible = false
                            tabSearchText = ""
                        }
                    }
                
                // Tab Search Panel
                tabSearchPanel
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(100)
            .onAppear {
                selectedSearchIndex = 0
                setupKeyboardMonitor()
            }
            .onDisappear {
                removeKeyboardMonitor()
            }
        }
    }
    
    private func setupKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak tabManager] event in
            guard isTabSearchVisible,
                  let window = NSApp.keyWindow,
                  window.isKeyWindow else {
                return event
            }
            
            // Check if the search text field is the first responder
            // Only consume navigation keys when the text field has focus
            let firstResponder = window.firstResponder
            let isTextFieldFocused = firstResponder is NSTextView || firstResponder is NSTextField
            
            // Handle Escape key (keyCode 53) - always consume when overlay is visible
            if event.keyCode == 53 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isTabSearchVisible = false
                    tabSearchText = ""
                }
                return nil // Consume the event
            }
            
            // Only consume navigation keys if text field is focused
            guard isTextFieldFocused else { return event }
            
            let count = filteredTabs.count
            guard count > 0 else { return event }
            
            // Handle Down Arrow (keyCode 125)
            if event.keyCode == 125 {
                selectedSearchIndex = (selectedSearchIndex + 1) % count
                return nil // Consume the event
            }
            
            // Handle Up Arrow (keyCode 126)
            if event.keyCode == 126 {
                selectedSearchIndex = (selectedSearchIndex - 1 + count) % count
                return nil // Consume the event
            }
            
            // Handle Return/Enter (keyCode 36)
            if event.keyCode == 36 {
                let filtered = filteredTabs
                if selectedSearchIndex < filtered.count {
                    tabManager?.switchToTab(filtered[selectedSearchIndex])
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isTabSearchVisible = false
                        tabSearchText = ""
                    }
                }
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    private func removeKeyboardMonitor() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }
    
    private var tabSearchPanel: some View {
        VStack(spacing: 0) {
            // Search Bar
            tabSearchBar
            
            Divider()
            
            // Tab List
            tabSearchResultsList
        }
        .frame(width: 600)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private var tabSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search tabs...", text: $tabSearchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($isTabSearchFocused)
                .onSubmit {
                    let filtered = filteredTabs
                    if selectedSearchIndex < filtered.count {
                        tabManager.switchToTab(filtered[selectedSearchIndex])
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isTabSearchVisible = false
                            tabSearchText = ""
                        }
                    }
                }
            
            if !tabSearchText.isEmpty {
                Button(action: { tabSearchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            
            KeyboardShortcutHint("⌘K", tooltip: "Close")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
    
    private var tabSearchResultsList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    let filtered = filteredTabs
                    ForEach(0..<filtered.count, id: \.self) { index in
                        TabSearchRow(
                            tab: filtered[index],
                            isSelected: index == selectedSearchIndex,
                            isCurrentTab: tabManager.currentTab?.id == filtered[index].id
                        ) {
                            tabManager.switchToTab(filtered[index])
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isTabSearchVisible = false
                                tabSearchText = ""
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
            .onChange(of: selectedSearchIndex) { _, newIndex in
                let filtered = filteredTabs
                if newIndex < filtered.count {
                    withAnimation {
                        proxy.scrollTo(filtered[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }
    
    private var filteredTabs: [BrowserTab] {
        if tabSearchText.isEmpty {
            return tabManager.tabs
        }
        let query = tabSearchText.lowercased()
        return tabManager.tabs.filter { tab in
            tab.title.lowercased().contains(query) || tab.url.lowercased().contains(query)
        }
    }
}

struct TabSearchRow: View {
    let tab: BrowserTab
    let isSelected: Bool
    let isCurrentTab: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Favicon or indicator
                ZStack {
                    if isCurrentTab {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    } else {
                        FaviconView(urlString: tab.url, title: tab.title, size: 20)
                    }
                }
                .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title.isEmpty ? "New Tab" : tab.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if !tab.url.isEmpty {
                        Text(tab.url)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Current tab indicator
                if isCurrentTab {
                    Text("Current")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(4)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected || isHovered ? Color.primary.opacity(0.08) : .clear)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .id(tab.id)
    }
}
