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

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        setupView(webView, in: view)
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        if webView.superview != uiView {
            setupView(webView, in: uiView)
        }
    }

    private func setupView(_ webView: WKWebView, in container: UIView) {
        webView.removeFromSuperview()
        webView.frame = container.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(webView)
    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // Properly remove the webView from superview to prevent memory leaks.
        // Heavy cleanup (stopLoading, remove delegates) happens in WebViewManager.teardown().
        for subview in uiView.subviews {
            subview.removeFromSuperview()
        }
    }
}
#elseif os(macOS)
public struct WebViewContainer: NSViewRepresentable {
    public let webView: WKWebView

    public init(webView: WKWebView) {
        self.webView = webView
    }

    public func makeNSView(context: Context) -> NSView {
        let view = WebViewHostingView(webView: webView)
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let hostingView = nsView as? WebViewHostingView {
            hostingView.updateWebView(webView)
        }
    }

    public static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        // Properly remove the webView from superview to prevent memory leaks.
        // The webView is safely managed by the WebViewManager/BrowserTab lifecycle.
        // Heavy cleanup (stopLoading, remove delegates) happens in WebViewManager.teardown().
        // No dark mode injection - content renders with natural page colors.
        for subview in nsView.subviews {
            subview.removeFromSuperview()
        }
    }
}

// MARK: - WebViewHostingView
// Custom NSView that hosts a WKWebView
// NOTE: We deliberately do NOT override keyDown/keyUp here.
// This allows the WKWebView to receive key events naturally through AppKit's responder chain,
// which is essential for proper handling of form inputs (search bars, text fields) on web pages.
// See v1.3 Keyboard_Scrolling_Fix.md for details.
class WebViewHostingView: NSView {
    private var webView: WKWebView?
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupWebView() {
        guard let webView = webView else { return }
        webView.removeFromSuperview()
        webView.frame = bounds
        webView.autoresizingMask = [.width, .height]
        addSubview(webView)
    }
    
    func updateWebView(_ newWebView: WKWebView) {
        if webView !== newWebView {
            webView?.removeFromSuperview()
            webView = newWebView
            setupWebView()
        }
    }
}
#endif
