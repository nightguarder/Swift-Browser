//
//  BrowserTab.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import Foundation
import Combine

final class BrowserTab: Identifiable, ObservableObject {
    let id = UUID()
    @Published var title: String
    @Published var url: String
    var webView: WebViewManager

    init(title: String, url: String, webView: WebViewManager) {
        self.title = title
        self.url = url
        self.webView = webView
    }
}
