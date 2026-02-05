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
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "logger")
        uiView.configuration.userContentController.removeAllUserScripts()
        uiView.configuration.userContentController.removeAllContentRuleLists()
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
        nsView.stopLoading()
        nsView.navigationDelegate = nil
        nsView.uiDelegate = nil
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "logger")
        nsView.configuration.userContentController.removeAllUserScripts()
        nsView.configuration.userContentController.removeAllContentRuleLists()
        nsView.removeFromSuperview()
    }
}
#endif
