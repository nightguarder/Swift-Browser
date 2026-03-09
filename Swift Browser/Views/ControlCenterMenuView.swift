//
//  ControlCenterMenuView.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import SwiftUI
import WebKit

public struct ControlCenterMenuView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var tabManager: TabManager
    
    public init(isExpanded: Binding<Bool>, tabManager: TabManager) {
        self._isExpanded = isExpanded
        self.tabManager = tabManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MenuItem(icon: "clock", title: "History", isExpanded: $isExpanded) {
                tabManager.openHistory()
            }
            
            MenuItem(icon: "bookmark", title: "Bookmarks", isExpanded: $isExpanded) {
                tabManager.openBookmarks()
            }
            
            MenuItem(icon: "ladybug.fill", title: "Cookies", isExpanded: $isExpanded) {
                tabManager.openCookies()
            }
            
            MenuItem(icon: "keyboard", title: "Shortcuts", isExpanded: $isExpanded) {
                tabManager.openShortcuts()
            }
            
            MenuItem(icon: "gear", title: "Settings", isExpanded: $isExpanded) {
                tabManager.openSettings()
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .contentShape(Rectangle())
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let subtitle: String? = nil
    @Binding var isExpanded: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            isExpanded = false
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(AppFont.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.title)
                        .foregroundStyle(.primary)
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

public struct ControlCenterMenuButton: View {
    @Binding var isExpanded: Bool
    @State private var isHovered = false
    
    public init(isExpanded: Binding<Bool>) {
        self._isExpanded = isExpanded
    }
    
    public var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: "line.3.horizontal")
                .font(AppFont.mediumIcon)
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
