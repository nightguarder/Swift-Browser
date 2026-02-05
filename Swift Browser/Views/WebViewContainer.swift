//
//  WebViewContainer.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI
import WebKit

#if os(iOS)
public struct WebViewContainer: UIViewRepresentable {
    public let webView: WKWebView

    public init(webView: WKWebView) {
        self.webView = webView
    }

    public func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    public static func dismantleUIView(_ uiView: WKWebView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}
#elseif os(macOS)
public struct WebViewContainer: NSViewRepresentable {
    public let webView: WKWebView

    public init(webView: WKWebView) {
        self.webView = webView
    }

    public func makeNSView(context: Context) -> WKWebView {
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {}

    public static func dismantleNSView(_ nsView: WKWebView, coordinator: ()) {
        // Do not stopLoading here; switching views should not
        // interrupt the page or sever the Web Inspector connection.
        nsView.removeFromSuperview()
    }
}
#endif
