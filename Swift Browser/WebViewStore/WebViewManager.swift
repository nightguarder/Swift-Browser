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
public final class WebViewManager: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published public var webView: WKWebView
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var zoomLevel: Double = 1.0
    @Published public var currentURL: URL?
    @Published public var pageTitle: String?

    private var cancellables = Set<AnyCancellable>()

    // Shared process pool for memory efficiency across all tabs
    private static let sharedProcessPool = WKProcessPool()

    public override init() {
        let config = WKWebViewConfiguration()
        config.processPool = Self.sharedProcessPool
        
        // Disable media autoplay and require user interaction
        config.mediaTypesRequiringUserActionForPlayback = .all
        
        // Upgrade known hosts to HTTPS (Mixed Content Block)
        if #available(macOS 11.0, *) {
            config.upgradeKnownHostsToHTTPS = true
        }
        
        // Apply Do Not Track (DNT)
        let dntEnabled = UserDefaults.standard.bool(forKey: "doNotTrackEnabled")
        if dntEnabled {
            let dntScript = WKUserScript(
                source: "Object.defineProperty(navigator, 'doNotTrack', {get: () => '1'});",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            config.userContentController.addUserScript(dntScript)
        }
        
        // Setup Console Bridge Script
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
        config.userContentController.addUserScript(script)
        
        webView = WKWebView(frame: .zero, configuration: config)
        
        super.init()
        
        setupWebView()
        setupObservers()
    }

    private func setupWebView() {
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        
        // Disable aggressive QuickLook preview behavior which can cause leaks
        webView.allowsMagnification = false
        
        // Use WeakScriptMessageHandler to avoid retain cycle
        webView.configuration.userContentController.add(WeakScriptMessageHandler(self), name: "logger")
        
        // Enable Web Inspector for debugging
        if #available(macOS 13.3, iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        applyContentBlockerIfNeeded()
        applyDarkModeIfNeeded()
    }

    private func setupObservers() {
        webView.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.progress = value
            }
            .store(in: &cancellables)

        webView.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.pageTitle = value
            }
            .store(in: &cancellables)

        webView.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentURL = value
            }
            .store(in: &cancellables)

        webView.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canGoBack = value
            }
            .store(in: &cancellables)

        webView.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canGoForward = value
            }
            .store(in: &cancellables)

        webView.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
                if !loading {
                    self?.applyDarkModeIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        print("DEBUG: WebViewManager deinit")
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.allowsBackForwardNavigationGestures = false
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "logger")
        webView.configuration.userContentController.removeAllUserScripts()
        // Load blank page to detach content process
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        cancellables.removeAll()
    }

    // Load a webpage from a given string (auto-fixes if missing "https://")
    public func load(_ urlString: String) {
        if let url = URL(string: urlString), url.scheme != nil {
            if url.scheme == "swiftbrowser" {
                return
            }
            webView.load(URLRequest(url: url))
            return
        }
        
        let fixed = "https://\(urlString)"
        guard let url = URL(string: fixed) else { return }
        webView.load(URLRequest(url: url))
    }

    // Navigation controls
    public func goBack() {
        if webView.canGoBack { webView.goBack() }
    }

    public func goForward() {
        if webView.canGoForward { webView.goForward() }
    }

    public func reload() {
        webView.reload()
    }

    public func stopLoading() {
        webView.stopLoading()
    }

    // Zoom Controls
    public func zoomIn() {
        zoomLevel += 0.1
        webView.pageZoom = zoomLevel
    }

    public func zoomOut() {
        zoomLevel = max(0.25, zoomLevel - 0.1)
        webView.pageZoom = zoomLevel
    }

    public func resetZoom() {
        zoomLevel = 1.0
        webView.pageZoom = 1.0
    }

    // WKNavigationDelegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "swiftbrowser" {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("DEBUG: WebView didFail navigation: \(error.localizedDescription)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("DEBUG: WebView didFailProvisionalNavigation: \(error.localizedDescription)")
    }

    // Content Blocker
    private func applyContentBlockerIfNeeded() {
        let isEnabled = UserDefaults.standard.bool(forKey: "contentBlockerEnabled")
        if isEnabled {
            ContentBlockerManager.shared.applyBlocklist(to: webView.configuration) { }
        }
    }
    
    public func updateContentBlocker(enabled: Bool) {
        let userContentController = webView.configuration.userContentController
        
        if enabled {
            ContentBlockerManager.shared.applyBlocklist(to: webView.configuration) { }
        } else {
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: "SwiftBrowserBlockList") { ruleList, _ in
                if let ruleList = ruleList {
                    userContentController.remove(ruleList)
                }
            }
        }
        UserDefaults.standard.set(enabled, forKey: "contentBlockerEnabled")
    }

    // Dark Mode
    private func applyDarkModeIfNeeded() {
        let isEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        if isEnabled {
            DarkModeManager.shared.applyDarkMode(to: webView.configuration)
        }
    }
    
    public func updateDarkMode(enabled: Bool) {
        if enabled {
            DarkModeManager.shared.applyDarkMode(to: webView.configuration)
        } else {
            DarkModeManager.shared.removeDarkMode(from: webView.configuration)
        }
        UserDefaults.standard.set(enabled, forKey: "darkModeEnabled")
    }

    // WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              let content = body["message"] as? String else { return }
        
        let logLine = "[\(type)] \(content)\n"
        print(logLine, terminator: "")
    }
}

// Internal helper to avoid retain cycles with WKScriptMessageHandler
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?
    
    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
