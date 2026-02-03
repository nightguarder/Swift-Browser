//
//  TopToolbar.swift
//  Swift Browser
//
//  Created by opencode on 03/02/26.
//

import SwiftUI

public struct TopToolbar: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @FocusState.Binding var isAddressBarFocused: Bool
    @Binding var isMenuExpanded: Bool
    
    public init(tabManager: TabManager, bookmarkManager: BookmarkManager, isAddressBarFocused: FocusState<Bool>.Binding, isMenuExpanded: Binding<Bool>) {
        self.tabManager = tabManager
        self.bookmarkManager = bookmarkManager
        self._isAddressBarFocused = isAddressBarFocused
        self._isMenuExpanded = isMenuExpanded
    }
    
    public var body: some View {
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
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                TextField("Search or URL",
                          text: $tabManager.addressBarText)
                    .onSubmit {
                        tabManager.loadCurrent()
                    }
                    .textFieldStyle(.plain)
                    .focused($isAddressBarFocused)
                    .disableAutocorrection(true)
                
                // Privacy Shield Indicator
                if let currentTab = tabManager.currentTab, !currentTab.webView.isLoading {
                    Button(action: {
                        // Action for privacy shield details
                    }) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Privacy Shield Active")
                }
                
                // Bookmark Button
                if let current = tabManager.currentTab, !current.url.isEmpty {
                    let isBookmarked = bookmarkManager.isBookmarked(url: current.url)
                    Menu {
                        if !isBookmarked {
                            Button(action: {
                                bookmarkManager.addBookmark(title: current.title, url: current.url)
                            }) {
                                Label("Add Bookmark", systemImage: "plus")
                            }
                        }
                        
                        if !bookmarkManager.bookmarks.isEmpty {
                            if !isBookmarked {
                                Divider()
                            }
                            ForEach(bookmarkManager.bookmarks) { bm in
                                Button(bm.title) {
                                    tabManager.addressBarText = bm.url
                                    tabManager.loadCurrent()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isBookmarked ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Fix for macOS system beep
                Button(action: {
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

            // Control Center Menu Button
            ControlCenterMenuButton(isExpanded: $isMenuExpanded)
                .padding(.trailing, 10)
        }
        .padding(.vertical, 8)
        .frame(height: 44)
    }
}
