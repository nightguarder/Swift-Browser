//
//  WebViewManager.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI
import WebKit
import Combine

// Observable store that owns the WKWebView and reports navigation state
final class WebViewManager: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published var webView: WKWebView
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0.0
    @Published var zoomLevel: Double = 1.0
    @Published var currentURL: URL?
    @Published var pageTitle: String?

    // Shared process pool for memory efficiency across all tabs
    private static let sharedProcessPool = WKProcessPool()

    override init() {
        let config = WKWebViewConfiguration()
        config.processPool = Self.sharedProcessPool
        
        // Setup Console Bridge
        let userController = WKUserContentController()
        let scriptSource = """
            (function() {
                var oldLog = console.log;
                var oldWarn = console.warn;
                var oldError = console.error;
                var oldDebug = console.debug;

                function sendToNative(type, args) {
                    var message = Array.from(args).map(v => {
                        try {
                            return typeof v === 'object' ? JSON.stringify(v) : String(v);
                        } catch(e) {
                            return String(v);
                        }
                    }).join(' ');
                    window.webkit.messageHandlers.logger.postMessage({type: type, message: message});
                }

                console.log = function() { sendToNative('LOG', arguments); oldLog.apply(console, arguments); };
                console.warn = function() { sendToNative('WARN', arguments); oldWarn.apply(console, arguments); };
                console.error = function() { sendToNative('ERROR', arguments); oldError.apply(console, arguments); };
                console.debug = function() { sendToNative('DEBUG', arguments); oldDebug.apply(console, arguments); };
            })();
        """
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userController.addUserScript(script)
        config.userContentController = userController
        
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        
        userController.add(self, name: "logger")
        webView.navigationDelegate = self
        
        // Enable Web Inspector for debugging
        if #available(macOS 13.3, iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        // Observe loading progress, title, and URL
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
        webView.removeObserver(self, forKeyPath: "URL")
    }

    // Load a webpage from a given string (auto-fixes if missing "https://")
    func load(_ urlString: String) {
        let fixed = urlString.starts(with: "http") ? urlString : "https://\(urlString)"
        guard let url = URL(string: fixed) else { return }
        webView.load(URLRequest(url: url))
    }

    // Navigation controls
    func goBack() {
        if webView.canGoBack { webView.goBack() }
    }

    func goForward() {
        if webView.canGoForward { webView.goForward() }
    }

    func reload() {
        webView.reload()
    }

    func stopLoading() {
        webView.stopLoading()
    }

    // Zoom Controls
    func zoomIn() {
        zoomLevel += 0.1
        webView.pageZoom = zoomLevel
    }

    func zoomOut() {
        zoomLevel = max(0.25, zoomLevel - 0.1)
        webView.pageZoom = zoomLevel
    }

    func resetZoom() {
        zoomLevel = 1.0
        webView.pageZoom = 1.0
    }

    // KVO observer for progress, title, and URL
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            DispatchQueue.main.async {
                self.progress = self.webView.estimatedProgress
            }
        } else if keyPath == "title" {
            DispatchQueue.main.async {
                self.pageTitle = self.webView.title
            }
        } else if keyPath == "URL" {
            DispatchQueue.main.async {
                self.currentURL = self.webView.url
            }
        }
    }

    // WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("DEBUG: WebView didFail navigation: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLoading = false
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("DEBUG: WebView didFailProvisionalNavigation: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLoading = false
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }

    // WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              let content = body["message"] as? String else { return }
        
        let logLine = "[\(type)] \(content)\n"
        print(logLine, terminator: "")
    }
}
