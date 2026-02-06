//
//  SidebarView.swift
//  Swift Browser
//
//  Created by opencode on 03/02/26.
//

import SwiftUI
import Foundation

public struct SidebarView: View {
    @ObservedObject var tabManager: TabManager
    @Binding var isSidebarHovered: Bool
    @Binding var tabSearchText: String
    @FocusState.Binding var isTabSearchFocused: Bool
    @Binding var hoveredTab: UUID?
    @AppStorage("userName") private var userName: String = "User"
    
    public init(tabManager: TabManager, isSidebarHovered: Binding<Bool>, tabSearchText: Binding<String>, isTabSearchFocused: FocusState<Bool>.Binding, hoveredTab: Binding<UUID?>) {
        self.tabManager = tabManager
        self._isSidebarHovered = isSidebarHovered
        self._tabSearchText = tabSearchText
        self._isTabSearchFocused = isTabSearchFocused
        self._hoveredTab = hoveredTab
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                HStack(spacing: isSidebarHovered ? 8 : 0) {
                    Image(systemName: "person.circle")
                        .font(AppFont.subtitle)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)

                    if isSidebarHovered {
                        Text("\(userName)'s Space")
                            .font(AppFont.subtitle)
                            .foregroundColor(.primary)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            .lineLimit(1)

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: isSidebarHovered ? .leading : .center)
                .padding(.horizontal, 6)
                .padding(.top, 8)
                .padding(.bottom, 4)

                HStack(spacing: isSidebarHovered ? 8 : 0) {
                    Image(systemName: "magnifyingglass")
                        .font(AppFont.subtitle)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                    
                    if isSidebarHovered {
                        TextField("Search tabs...", text: $tabSearchText)
                            .textFieldStyle(.plain)
                            .focused($isTabSearchFocused)
                        
                        Spacer()
                        
                        Text("⌘K")
                            .font(AppFont.keyboardShortcut)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                            .padding(.trailing, 8)
                    }
                }
                .background(Color.primary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .onTapGesture {
                    withAnimation {
                        isSidebarHovered = true
                        isTabSearchFocused = true
                    }
                }

                Divider()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        if tabSearchText.isEmpty {
                            ForEach(tabManager.tabs) { tab in
                                  SidebarTabButton(
                                      tab: tab,
                                      isCurrent: tabManager.currentTab?.id == tab.id,
                                      isSidebarHovered: isSidebarHovered,
                                      hoveredTabId: $hoveredTab,
                                      onClose: {
                                          if hoveredTab == tab.id {
                                              hoveredTab = nil
                                          }
                                          tabManager.closeTab(tab)
                                      },
                                      onSelect: {
                                          tabManager.switchToTab(tab)
                                      },
                                      onDuplicate: {
                                         tabManager.duplicate(tab)
                                     }
                                 )
                            }
                        } else {
                            let query = tabSearchText.lowercased()
                            let filteredTabs = tabManager.tabs.filter {
                                $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query)
                            }
                            ForEach(filteredTabs) { tab in
                                  SidebarTabButton(
                                      tab: tab,
                                      isCurrent: tabManager.currentTab?.id == tab.id,
                                      isSidebarHovered: isSidebarHovered,
                                      hoveredTabId: $hoveredTab,
                                      onClose: {
                                          if hoveredTab == tab.id {
                                              hoveredTab = nil
                                          }
                                          tabManager.closeTab(tab)
                                      },
                                      onSelect: {
                                          tabManager.switchToTab(tab)
                                      },
                                      onDuplicate: {
                                         tabManager.duplicate(tab)
                                     }
                                 )
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                Button(action: { tabManager.addTab() }) {
                    HStack(spacing: isSidebarHovered ? 8 : 0) {
                        Image(systemName: "plus")
                            .font(AppFont.subtitle)
                            .frame(width: 36, height: 36)
                        
                        if isSidebarHovered {
                            Text("New Tab")
                                .font(AppFont.caption)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            KeyboardShortcutHint("⌘T")
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
        .frame(width: isSidebarHovered ? AppSpacing.sidebarWidthExpanded : AppSpacing.sidebarWidthCollapsed)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSidebarHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSidebarHovered)
        .overlay(Divider().frame(maxWidth: 1), alignment: .trailing)
    }
}

public struct SidebarTabButton: View {
    @ObservedObject var tab: BrowserTab
    var isCurrent: Bool
    var isSidebarHovered: Bool
    @Binding var hoveredTabId: UUID?
    var onClose: () -> Void
    var onSelect: () -> Void
    var onDuplicate: () -> Void
    
    public init(tab: BrowserTab, isCurrent: Bool, isSidebarHovered: Bool, hoveredTabId: Binding<UUID?>, onClose: @escaping () -> Void, onSelect: @escaping () -> Void, onDuplicate: @escaping () -> Void) {
        self.tab = tab
        self.isCurrent = isCurrent
        self.isSidebarHovered = isSidebarHovered
        self._hoveredTabId = hoveredTabId
        self.onClose = onClose
        self.onSelect = onSelect
        self.onDuplicate = onDuplicate
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            FaviconView(urlString: tab.url, title: tab.title)
                .frame(width: 18, height: 18)
                .padding(.leading, 2)
                .padding(.trailing, 2)

            if isSidebarHovered {
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .lineLimit(1)
                    .font(AppFont.caption)
                    .foregroundColor(isCurrent ? .primary : .secondary)
                
                Spacer()
                
                if isCurrent || hoveredTabId == tab.id {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(AppFont.keyboardShortcut)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Close Tab (⌘W)")
                    
                    KeyboardShortcutHint("⌘W")
                        .opacity(hoveredTabId == tab.id || isCurrent ? 1 : 0)
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
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button("Duplicate Tab", action: onDuplicate)
            Button("Close Tab", action: onClose)
        }
        .onHover { hovering in
            hoveredTabId = hovering ? tab.id : nil
        }
    }
}
