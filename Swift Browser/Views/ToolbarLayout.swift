//
//  ToolbarLayout.swift
//  Swift Browser
//
//  Created by Assistant on 02/09/26.
//

import SwiftUI

struct ToolbarLayout {
    static let navControlsWidth: CGFloat = 110
    static let menuButtonWidth: CGFloat = 40
    static let horizontalPadding: CGFloat = 12
    static let toolbarHeight: CGFloat = 44
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

    static var totalSidebarWidth: CGFloat {
        navControlsWidth + menuButtonWidth + (horizontalPadding * 2)
    }
}
