import SwiftUI

struct AppFont {
    static let icon = Font.system(size: 18, weight: .medium)
    static let title = Font.system(size: 15, weight: .medium)
    static let subtitle = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let body = Font.system(size: 14, weight: .regular)
    static let headline = Font.system(size: 14, weight: .semibold)
    static let hero = Font.system(size: 42, weight: .bold, design: .rounded)
    static let heroIcon = Font.system(size: 50, weight: .ultraLight)
    static let searchField = Font.system(size: 15, weight: .regular)
    static let smallIcon = Font.system(size: 13, weight: .medium)
    static let mediumIcon = Font.system(size: 15, weight: .medium)
    static let keyboardShortcut = Font.system(size: 11, weight: .medium)
}

struct AppSpacing {
    static let iconSize: CGFloat = 24
    static let smallIconSize: CGFloat = 20
    static let toolbarHeight: CGFloat = 52
    static let sidebarWidthCollapsed: CGFloat = 50
    static let sidebarWidthExpanded: CGFloat = 200
    static let menuItemPadding: CGFloat = 10
    static let cornerRadius: CGFloat = 8
}
