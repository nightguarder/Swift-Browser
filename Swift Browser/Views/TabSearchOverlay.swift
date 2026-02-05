//
//  TabSearchOverlay.swift
//  Swift Browser
//
//  Created by opencode on 03/02/26.
//

import SwiftUI
import AppKit

// MARK: - Key Event Handling
private struct KeyEventView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyEventNSView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class KeyEventNSView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let onKeyDown = onKeyDown, onKeyDown(event) {
            return
        }
        super.keyDown(with: event)
    }
}

extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Bool) -> some View {
        self.background(KeyEventView(onKeyDown: action))
    }
}

public struct TabSearchOverlay: View {
    @ObservedObject var tabManager: TabManager
    @Binding var isTabSearchVisible: Bool
    @Binding var tabSearchText: String
    @Binding var selectedSearchIndex: Int
    @FocusState.Binding var isTabSearchFocused: Bool
    
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
                    .onKeyDown { event in
                        if event.keyCode == 53 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isTabSearchVisible = false
                                tabSearchText = ""
                            }
                            return true
                        }
                        return false
                    }
                
                // Tab Search Panel
                tabSearchPanel
                    .onKeyDown { event in
                        if event.keyCode == 53 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isTabSearchVisible = false
                                tabSearchText = ""
                            }
                            return true
                        }
                        return false
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(100)
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
        .frame(width: 400)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var tabSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            TextField("Search tabs...", text: $tabSearchText)
                .textFieldStyle(.plain)
                .focused($isTabSearchFocused)
                .onKeyDown { event in
                    if event.keyCode == 53 { // Esc
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isTabSearchVisible = false
                            tabSearchText = ""
                        }
                        return true
                    }
                    
                    let count = filteredTabs.count
                    if count == 0 { return false }
                    
                    if event.keyCode == 125 { // Down Arrow
                        selectedSearchIndex = (selectedSearchIndex + 1) % count
                        return true
                    } else if event.keyCode == 126 { // Up Arrow
                        selectedSearchIndex = (selectedSearchIndex - 1 + count) % count
                        return true
                    }
                    return false
                }
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
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            
            Text("⌘K")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    private var tabSearchResultsList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    let filtered = filteredTabs
                    ForEach(0..<filtered.count, id: \.self) { index in
                        tabSearchResultRow(for: filtered[index], index: index)
                        
                        if index != filtered.count - 1 {
                            Divider()
                                .padding(.leading, 30)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
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
    
    private func tabSearchResultRow(for tab: BrowserTab, index: Int) -> some View {
        let isSelected = index == selectedSearchIndex
        return Button(action: {
            tabManager.switchToTab(tab)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isTabSearchVisible = false
                tabSearchText = ""
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(tabManager.currentTab?.id == tab.id ? Color.accentColor : (isSelected ? Color.primary.opacity(0.5) : Color.secondary.opacity(0.3)))
                    .frame(width: 6, height: 6)
                
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .lineLimit(1)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if !tab.url.isEmpty {
                    Text(tab.url)
                        .lineLimit(1)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(isSelected ? 0.9 : 0.7))
                        .truncationMode(.middle)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(tab.id)
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
