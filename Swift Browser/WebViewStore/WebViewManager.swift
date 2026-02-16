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
public final class WebViewManager: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    public let webView: WKWebView
    public let duckPlayer = DuckPlayerManager()
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var zoomLevel: Double = 1.0
    @Published public var currentURL: URL?
    @Published public var pageTitle: String?

    /// Closure called when the web view requests to open a new tab/window (e.g. window.open)
    public var onNewTabRequested: ((WKWebViewConfiguration) -> WKWebView?)?
    
    /// Closure called when the web view requests to close (e.g. window.close)
    public var onCloseRequested: (() -> Void)?
    
    /// Closure called when media playback state changes (isPlaying: Bool)
    public var onMediaPlaybackStateChanged: ((Bool) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private var mediaCheckTimer: Timer?
    private var lastMediaPlaybackState: Bool = false

    private var isTornDown = false
    private let dataStore: WKWebsiteDataStore
    private let isPrivateSpace: Bool

    // Pre-compiled static scripts for performance
    private static let dntScriptSource = "Object.defineProperty(navigator,'doNotTrack',{get:()=>'1'});"

    public init(dataStore: WKWebsiteDataStore = .default(), isPrivateSpace: Bool = false, configuration: WKWebViewConfiguration? = nil) {
        self.dataStore = dataStore
        self.isPrivateSpace = isPrivateSpace
        
        let config = configuration ?? WKWebViewConfiguration()
        config.websiteDataStore = dataStore
        config.processPool = SpaceManager.shared.processPool
        
        // Use applicationNameForUserAgent to allow WebKit to build a perfect Safari-like UA
        config.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        
        // Disable media autoplay and require user interaction ONLY if not explicitly configured
        if configuration == nil {
            config.mediaTypesRequiringUserActionForPlayback = .all
        }
        
        // Upgrade known hosts to HTTPS (Mixed Content Block)
        if #available(macOS 11.0, *) {
            config.upgradeKnownHostsToHTTPS = true
        }
        
        // Apply Do Not Track (DNT) - minimal script
        let dntEnabled = UserDefaults.standard.bool(forKey: "doNotTrackEnabled")
        if dntEnabled {
            let dntScript = WKUserScript(
                source: Self.dntScriptSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            config.userContentController.addUserScript(dntScript)
        }
        
        webView = WKWebView(frame: .zero, configuration: config)
        
        super.init()
        
        setupWebView()
        setupObservers()
        
        // Attach DuckPlayer KVO observer after webView is created
        duckPlayer.attach(to: webView)
    }

    private func setupWebView() {
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Disable aggressive QuickLook preview behavior which can cause leaks
        webView.allowsMagnification = false
        
        // Prevent white flash before page load by using transparent background
        // The web view's background shows before page content renders
        webView.setValue(false, forKey: "drawsBackground")
        
        // Configure WebKit preferences to appear more like regular Safari
        webView.configuration.preferences.setValue(true, forKey: "javaScriptCanOpenWindowsAutomatically")
        webView.configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
        
        // Enable Web Inspector for debugging (if enabled in settings)
        let devMode = UserDefaults.standard.bool(forKey: "developerModeEnabled")
        #if os(macOS)
        if devMode {
            // Enable context menu "Inspect Element" and Web Inspector on macOS
            webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        }
        #endif
        if #available(macOS 13.3, iOS 16.4, *) {
            // iOS/macOS 13.3+: enable remote inspection
            webView.isInspectable = devMode
        }
        
        applyContentBlockerIfNeeded()
        applyDarkModeIfNeeded()
    }

    private func setupObservers() {
        let mainQueue = DispatchQueue.main
        
        webView.publisher(for: \.estimatedProgress)
            .receive(on: mainQueue)
            .throttle(for: .milliseconds(50), scheduler: mainQueue, latest: true)
            .sink { [weak self] value in
                self?.progress = value
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(
            webView.publisher(for: \.title).removeDuplicates(),
            webView.publisher(for: \.url).removeDuplicates(),
            webView.publisher(for: \.canGoBack).removeDuplicates(),
            webView.publisher(for: \.canGoForward).removeDuplicates()
        )
        .receive(on: mainQueue)
        .sink { [weak self] title, url, canGoBack, canGoForward in
            self?.pageTitle = title
            self?.currentURL = url
            self?.canGoBack = canGoBack
            self?.canGoForward = canGoForward
        }
        .store(in: &cancellables)

        webView.publisher(for: \.isLoading)
            .receive(on: mainQueue)
            .removeDuplicates()
            .sink { [weak self] loading in
                self?.isLoading = loading
                if !loading {
                    self?.applyDarkModeIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        // Monitor media playback state changes
        startMediaPlaybackMonitoring()
        
        // Forward DuckPlayer changes
        duckPlayer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func startMediaPlaybackMonitoring() {
        guard mediaCheckTimer == nil else { return }
        
        mediaCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if #available(macOS 12.0, *) {
                self.webView.requestMediaPlaybackState { [weak self] state in
                    guard let self = self else { return }
                    let isPlaying = (state == .playing)
                    
                    if isPlaying != self.lastMediaPlaybackState {
                        self.lastMediaPlaybackState = isPlaying
                        self.onMediaPlaybackStateChanged?(isPlaying)
                    }
                }
            }
        }
    }
    
    private func stopMediaPlaybackMonitoring() {
        mediaCheckTimer?.invalidate()
        mediaCheckTimer = nil
    }

    deinit {
        let webView = self.webView
        if Thread.isMainThread {
            Self.teardownWebView(webView, cancellables: &cancellables, isTornDown: &isTornDown)
        } else {
            DispatchQueue.main.async {
                var empty = Set<AnyCancellable>()
                var tornDown = false
                Self.teardownWebView(webView, cancellables: &empty, isTornDown: &tornDown)
            }
        }
    }

    public func teardown() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.teardown()
            }
            return
        }

        stopMediaPlaybackMonitoring()
        onMediaPlaybackStateChanged?(false) // Notify that media stopped
        
        // Detach DuckPlayer KVO observer
        duckPlayer.detach()
        
        Self.teardownWebView(webView, cancellables: &cancellables, isTornDown: &isTornDown)
    }

    private static func teardownWebView(_ webView: WKWebView, cancellables: inout Set<AnyCancellable>, isTornDown: inout Bool) {
        guard !isTornDown else { return }
        isTornDown = true

        cancellables.removeAll()

        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.allowsBackForwardNavigationGestures = false

        let ucc = webView.configuration.userContentController
        ucc.removeScriptMessageHandler(forName: "logger")

        // Detach the web content process as aggressively as possible.
        if let blankURL = URL(string: "about:blank") {
            webView.load(URLRequest(url: blankURL))
        }

        webView.removeFromSuperview()
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
        
        // DuckPlayer Redirection (Main Frame Only)
        // In "Always Open" mode, intercept YouTube video navigations and open in DuckPlayer
        // instead of loading the YouTube page. In "Ask" mode, let the page load normally
        // and the injected JS will show the overlay button.
        if navigationAction.targetFrame?.isMainFrame == true,
           let url = navigationAction.request.url,
           self.duckPlayer.shouldInterceptNavigation(url: url) {
            
            self.duckPlayer.handleAutoRedirect(url: url)
            decisionHandler(.cancel)
            return
        }
        
        // Handle downloads
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    // Handle authentication challenges (e.g. Cloudflare Private Access Tokens)
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // For most challenges, we can just use the default handling
        // but explicitly allowing the challenge to proceed helps with some verification systems
        completionHandler(.performDefaultHandling, nil)
    }
    
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        DownloadManager.shared.startDownload(from: download, suggestedFilename: download.originalRequest?.url?.lastPathComponent ?? "download")
    }
    
    public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        DownloadManager.shared.startDownload(from: download, suggestedFilename: navigationResponse.response.suggestedFilename ?? "download")
    }

    // WKUIDelegate
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle window.open by calling our new tab callback
        return onNewTabRequested?(configuration)
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        // Handle window.close by calling our close callback
        onCloseRequested?()
    }

    // MARK: - File Upload Support (Native NSOpenPanel)
    
    public func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = parameters.allowsDirectories
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        
        openPanel.begin { result in
            if result == .OK {
                completionHandler(openPanel.urls)
            } else {
                completionHandler(nil)
            }
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // NSURLErrorCancelled (-999) is common during redirects and Cloudflare challenges
        if (error as NSError).code == NSURLErrorCancelled { return }
        
        #if DEBUG
        print("DEBUG: WebView didFail navigation: \(error.localizedDescription)")
        #endif
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // NSURLErrorCancelled (-999) is common during redirects and Cloudflare challenges
        if (error as NSError).code == NSURLErrorCancelled { return }

        #if DEBUG
        print("DEBUG: WebView didFailProvisionalNavigation: \(error.localizedDescription)")
        #endif
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Record history only if not in a private space
        if let url = webView.url, !isPrivateSpace {
            let pageTitle = webView.title?.isEmpty == false ? webView.title! : extractTitleFromURL(url)
            HistoryManager.shared.addVisit(url: url, title: pageTitle)
        }
        
        // Re-apply dark mode if needed (sometimes reliable on finish)
        applyDarkModeIfNeeded()
    }

    // Content Blocker
    private func applyContentBlockerIfNeeded() {
        let isEnabled = UserDefaults.standard.bool(forKey: "contentBlockerEnabled")
        if isEnabled {
            ContentBlockerManager.shared.applyBlocklist(to: webView.configuration) {}
        }
    }

    // Extract a readable title from URL when page title is not available
    private func extractTitleFromURL(_ url: URL) -> String {
        // Try to use the last path component if it's not empty
        let lastComponent = url.lastPathComponent
        if !lastComponent.isEmpty && lastComponent != "/" {
            // Remove file extension if present
            let withoutExtension = (lastComponent as NSString).deletingPathExtension
            if !withoutExtension.isEmpty {
                // Convert kebab-case or snake_case to spaces and capitalize
                return withoutExtension
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
            }
        }

        // Fallback to host name
        if let host = url.host {
            // Remove www. prefix if present
            return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        }

        // Final fallback
        return url.absoluteString
    }
    
    public func updateContentBlocker(enabled: Bool) {
        let userContentController = webView.configuration.userContentController
        
        if enabled {
            ContentBlockerManager.shared.applyBlocklist(to: webView.configuration) {}
        } else {
            ContentBlockerManager.shared.removeBlocklist(from: userContentController)
        }
        UserDefaults.standard.set(enabled, forKey: "contentBlockerEnabled")
    }

    // Dark Mode
    private func applyDarkModeIfNeeded() {
        DarkModeManager.shared.applyDarkMode(to: webView)
    }
    
    public func updateDarkMode() {
        if DarkModeManager.shared.isDarkModeEnabled {
            DarkModeManager.shared.applyDarkMode(to: webView)
        } else {
            DarkModeManager.shared.removeDarkMode(from: webView)
        }
    }
    
    // Developer Mode
    public func updateDeveloperMode(enabled: Bool) {
        #if os(macOS)
        webView.configuration.preferences.setValue(enabled, forKey: "developerExtrasEnabled")
        #endif
        if #available(macOS 13.3, iOS 16.4, *) {
            webView.isInspectable = enabled
        }
    }
}
