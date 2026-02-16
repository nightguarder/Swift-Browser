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

// Custom NSView that properly hosts a WKWebView and ensures it receives key events
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
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        // Forward first responder to the webview so it can handle key events
        if let webView = webView {
            window?.makeFirstResponder(webView)
            return true
        }
        return super.becomeFirstResponder()
    }
    
    override func keyDown(with event: NSEvent) {
        // Forward key events to the webview for proper handling (scrolling, etc.)
        if let webView = webView {
            webView.keyDown(with: event)
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let webView = webView {
            webView.keyUp(with: event)
        } else {
            super.keyUp(with: event)
        }
    }
}
#endif
