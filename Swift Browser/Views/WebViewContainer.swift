//
//  WebViewContainer.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI
import WebKit
import ObjectiveC

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

// MARK: - Key Scroll Coalescer
// Lightweight coalescer to batch sequential Up/Down key events into a single scroll.
class KeyScrollCoalescer {
    weak var webView: WKWebView?
    private var pendingDeltaY: Double = 0
    private var workItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.swiftbrowser.scrollcoalescer")
    
    init(webView: WKWebView) {
        self.webView = webView
    }
    
    func enqueue(deltaY: Double) {
        pendingDeltaY += deltaY
        // Debounce bursts of key presses to a single scroll action
        workItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.flush()
        }
        workItem = item
        queue.asyncAfter(deadline: .now() + 0.02, execute: item)
    }
    
    private func flush() {
        guard let webView = webView else { return }
        let delta = pendingDeltaY
        pendingDeltaY = 0
        guard delta != 0 else { return }
        DispatchQueue.main.async {
            let js = "window.scrollBy({ top: \(delta), left: 0, behavior: 'auto' })"
            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("KeyScrollCoalescer JS error: \(error)")
                }
            }
        }
    }
}

// MARK: - Associated Keys for Coalescer
private struct AssociatedKeys {
    static var coalescer = "scrollCoalescer"
}

// MARK: - WebViewHostingView
// Custom NSView that hosts a WKWebView
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
    
    // MARK: - Associated Object for Coalescer
    private var scrollCoalescer: KeyScrollCoalescer? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.coalescer) as? KeyScrollCoalescer }
        set { objc_setAssociatedObject(self, &AssociatedKeys.coalescer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Focus Forwarding
    override var acceptsFirstResponder: Bool {
        // If the webView can become first responder, prefer it
        return webView?.acceptsFirstResponder ?? false
    }
    
    override func becomeFirstResponder() -> Bool {
        webView?.becomeFirstResponder()
        return true
    }
    
    // MARK: - Key Event Handling
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Ensure the coalescer is created after the webView is set up
        if webView != nil && self.scrollCoalescer == nil {
            self.scrollCoalescer = KeyScrollCoalescer(webView: webView!)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // 126 = Up, 125 = Down
        let upCode: UInt16 = 126
        let downCode: UInt16 = 125
        
        if event.keyCode == upCode {
            self.scrollCoalescer?.enqueue(deltaY: -120) // negative for up
            return
        } else if event.keyCode == downCode {
            self.scrollCoalescer?.enqueue(deltaY: 120) // positive for down
            return
        }
        
        // For non-arrow keys, forward to the webView for native handling
        webView?.interpretKeyEvents([event])
        super.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        // Let the web view handle key up if needed
        webView?.interpretKeyEvents([event])
        super.keyUp(with: event)
    }
}
#endif
