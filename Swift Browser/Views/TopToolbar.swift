//
//  TopToolbar.swift
//  Swift Browser
//
//  Created by opencode on 03/02/26.
//

import SwiftUI

struct TopToolbar: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var historyManager: HistoryManager
    @FocusState.Binding var isAddressBarFocused: Bool
    @Binding var isMenuExpanded: Bool

    init(tabManager: TabManager, bookmarkManager: BookmarkManager, historyManager: HistoryManager, isAddressBarFocused: FocusState<Bool>.Binding, isMenuExpanded: Binding<Bool>) {
        self.tabManager = tabManager
        self.bookmarkManager = bookmarkManager
        self.historyManager = historyManager
        self._isAddressBarFocused = isAddressBarFocused
        self._isMenuExpanded = isMenuExpanded
    }

    public var body: some View {
        HStack(spacing: 12) {
                // Navigation Controls
                HStack(spacing: 8) {
                    Button(action: { tabManager.currentTab?.webView?.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(AppFont.icon)
                    }
                    .buttonStyle(.plain)
                    .disabled(!(tabManager.currentTab?.webView?.canGoBack ?? false))
                    .foregroundColor((tabManager.currentTab?.webView?.canGoBack ?? false) ? .primary : .secondary.opacity(0.5))

                    Button(action: { tabManager.currentTab?.webView?.goForward() }) {
                        Image(systemName: "chevron.right")
                            .font(AppFont.icon)
                    }
                    .buttonStyle(.plain)
                    .disabled(!(tabManager.currentTab?.webView?.canGoForward ?? false))
                    .foregroundColor((tabManager.currentTab?.webView?.canGoForward ?? false) ? .primary : .secondary.opacity(0.5))

                    Button(action: { tabManager.currentTab?.webView?.reload() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(AppFont.smallIcon)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 12)

                // Address Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(AppFont.subtitle)

                    TextField("Search or URL",
                              text: $tabManager.addressBarText)
                        .onSubmit {
                            isAddressBarFocused = false
                            NSApp.keyWindow?.makeFirstResponder(nil)
                            tabManager.loadCurrent()
                        }
                        .textFieldStyle(.plain)
                        .focused($isAddressBarFocused)
                        .disableAutocorrection(true)
                        .font(AppFont.searchField)

                    KeyboardShortcutHint("⌘L")
                        .padding(.trailing, 4)

                    // Privacy Shield Indicator
                    if let currentTab = tabManager.currentTab, !(currentTab.webView?.isLoading ?? false) {
                        Button(action: {}) {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.blue)
                                .font(AppFont.subtitle)
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
                                        isAddressBarFocused = false
                                        NSApp.keyWindow?.makeFirstResponder(nil)
                                        tabManager.addressBarText = bm.url
                                        tabManager.loadCurrent()
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(AppFont.subtitle)
                                .foregroundColor(isBookmarked ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Fix for macOS system beep
                    Button(action: {
                        if isAddressBarFocused {
                            isAddressBarFocused = false
                            NSApp.keyWindow?.makeFirstResponder(nil)
                            tabManager.loadCurrent()
                        }
                    }) {
                        Text("Go")
                    }
                    .keyboardShortcut(.defaultAction)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                }
                .padding(10)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )

                // Control Center Menu Button
                ControlCenterMenuButton(isExpanded: $isMenuExpanded)
                    .padding(.trailing, 12)
            }
            .frame(height: AppSpacing.toolbarHeight)
        }
    }
