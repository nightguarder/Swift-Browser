//
//  SidebarView.swift
//  Swift Browser
//
//  Created by opencode on 03/02/26.
//

import SwiftUI

public struct SidebarView: View {
    @ObservedObject var tabManager: TabManager
    @StateObject private var spaceManager = SpaceManager.shared
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
            
                VStack(spacing: AppSpacing.sidebarSectionSpacing) {
                // Space Header
                if isSidebarHovered {
                    HStack(spacing: AppSpacing.sidebarItemSpacing) {
                        ZStack {
                            Circle()
                                .fill(spaceManager.activeSpace.color)
                                .frame(width: AppSpacing.smallIconSize, height: AppSpacing.smallIconSize)

                            Image(systemName: spaceManager.activeSpace.icon)
                                .font(AppFont.sidebarSpaceIcon)
                                .foregroundColor(.white)
                        }

                        Text("\(userName)'s \(spaceManager.activeSpace.name) Space")
                            .font(AppFont.sidebarHeader)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                } else {
                    ZStack {
                        Circle()
                            .fill(spaceManager.activeSpace.color)
                            .frame(width: AppSpacing.smallIconSize, height: AppSpacing.smallIconSize)

                        Image(systemName: spaceManager.activeSpace.icon)
                            .font(AppFont.sidebarIcon)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }

                // Space Switcher
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sidebarItemSpacing) {
                        ForEach(spaceManager.spaces) { space in
                            SpaceIcon(
                                space: space,
                                isActive: spaceManager.activeSpaceId == space.id,
                                isSidebarHovered: isSidebarHovered,
                                 onSelect: {
                                    tabManager.switchSpace(to: space.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, isSidebarHovered ? 8 : 4)
                }
                .frame(height: 48)
                .padding(.top, 2)

                Divider()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)

                HStack(spacing: isSidebarHovered ? AppSpacing.sidebarItemSpacing : 0) {
                    Image(systemName: "magnifyingglass")
                        .font(AppFont.subtitle)
                        .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
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
                .cornerRadius(AppSpacing.cornerRadius)
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
                    LazyVStack(spacing: AppSpacing.sidebarItemSpacing) {
                        if tabSearchText.isEmpty {
                            let spaceTabs = tabManager.tabs.filter { $0.spaceId == spaceManager.activeSpaceId }
                            ForEach(spaceTabs) { tab in
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
                                ($0.title.lowercased().contains(query) || $0.url.lowercased().contains(query)) &&
                                $0.spaceId == spaceManager.activeSpaceId
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
                 
                  Button(action: { tabManager.addTab(in: spaceManager.activeSpaceId) }) {
                      HStack(spacing: isSidebarHovered ? AppSpacing.sidebarItemSpacing : 0) {

                      Image(systemName: "plus")
                          .font(AppFont.subtitle)
                          .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                         
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
                      .cornerRadius(AppSpacing.cornerRadius)
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

struct SpaceIcon: View {
    let space: Space
    let isActive: Bool
    let isSidebarHovered: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 1) {
            Button(action: onSelect) {
                ZStack {
                    Circle()
                        .fill(isActive ? space.color : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: space.icon)
                        .font(AppFont.sidebarSpaceIcon)
                        .foregroundColor(isActive ? .white : .primary)
                }
                .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                .background(isActive ? Color.clear : Color.primary.opacity(0.05))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(space.color.opacity(0.3), lineWidth: isActive ? 1.5 : 0)
                )
            }
            .buttonStyle(.plain)
            .help(space.name)
            
            // Space name label
            if isSidebarHovered && isActive {
                Text(space.name)
                    .font(AppFont.sidebarBadge)
                    .lineLimit(1)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(3)
            } else {
                // Placeholder to maintain consistent spacing
                Color.clear
                    .frame(height: 12)
            }
        }
        .frame(width: 40)
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
        HStack(spacing: AppSpacing.sidebarItemSpacing) {
            FaviconView(urlString: tab.url, title: tab.title)
                .frame(width: AppSpacing.smallIconSize, height: AppSpacing.smallIconSize)
                .padding(.leading, 2)
                .padding(.trailing, 2)

            if isSidebarHovered {
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .lineLimit(1)
                    .font(AppFont.sidebarTabTitle)
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
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .frame(height: AppSpacing.sidebarTabHeight)
        .background(
            isCurrent
            ? Color.primary.opacity(0.1)
            : (hoveredTabId == tab.id ? Color.primary.opacity(0.05) : Color.clear)
        )
        .cornerRadius(AppSpacing.cornerRadius)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .contextMenu {
            Button("Duplicate Tab", action: onDuplicate)
            Button("Close Tab", action: onClose)
        }
        .onHover { hovering in
            hoveredTabId = hovering ? tab.id : nil
        }
    }
}
