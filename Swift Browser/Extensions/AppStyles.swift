//
//  AppStyles.swift
//  Swift Browser
//
//  Created by Nightguarder on 05/02/26.
//
import SwiftUI

struct AppFont {
    static let icon = Font.system(size: 18, weight: .medium)
    static let title = Font.system(size: 15, weight: .medium)
    static let subtitle = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let captionBold = Font.system(size: 11, weight: .bold)
    static let body = Font.system(size: 14, weight: .regular)
    static let headline = Font.system(size: 14, weight: .semibold)
    static let hero = Font.system(size: 42, weight: .bold, design: .rounded)
    static let heroIcon = Font.system(size: 50, weight: .ultraLight)
    static let searchField = Font.system(size: 15, weight: .regular)
    static let smallIcon = Font.system(size: 13, weight: .medium)
    static let mediumIcon = Font.system(size: 15, weight: .medium)
    static let keyboardShortcut = Font.system(size: 11, weight: .medium)

    // Sidebar-specific typography
    static let sidebarHeader = Font.system(size: 11, weight: .semibold)
    static let sidebarTabTitle = Font.system(size: 14, weight: .medium)
    static let sidebarIcon = Font.system(size: 12, weight: .medium)
    static let sidebarSpaceIcon = Font.system(size: 16, weight: .medium)
    static let sidebarBadge = Font.system(size: 8, weight: .bold)
}

struct AppSpacing {
    static let iconSize: CGFloat = 24
    static let smallIconSize: CGFloat = 20
    static let toolbarHeight: CGFloat = 52
    static let sidebarWidthCollapsed: CGFloat = 60
    static let sidebarWidthExpanded: CGFloat = 240
    static let sidebarItemSpacing: CGFloat = 12
    static let sidebarSectionSpacing: CGFloat = 14
    static let sidebarTabHeight: CGFloat = 36
    static let menuItemPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 8

    // Toolbar layout constants (from @Toolbarlayout.swift)
    static let navControlsWidth: CGFloat = 110
    static let menuButtonWidth: CGFloat = 40
    static let horizontalPadding: CGFloat = 12
    static let addressBarMinWidth: CGFloat = 400
    static let addressBarIdealWidth: CGFloat = 600

    static var addressBarHorizontalPadding: EdgeInsets {
        EdgeInsets(
            top: 0,
            leading: navControlsWidth + horizontalPadding,
            bottom: 0,
            trailing: menuButtonWidth + horizontalPadding
        )
    }
}
