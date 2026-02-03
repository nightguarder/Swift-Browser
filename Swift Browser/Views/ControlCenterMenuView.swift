//
//  ControlCenterMenuView.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import SwiftUI

public struct ControlCenterMenuView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var tabManager: TabManager
    
    public init(isExpanded: Binding<Bool>, tabManager: TabManager) {
        self._isExpanded = isExpanded
        self.tabManager = tabManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MenuItem(icon: "gear", title: "Settings", isExpanded: $isExpanded) {
                tabManager.openSettings()
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .frame(width: 180)
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    @Binding var isExpanded: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            isExpanded = false
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
                .font(.system(size: 16, weight: .medium))
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
    }
}
