//
//  DuckPlayerView.swift
//  Swift Browser
//
//  Based on DuckDuckGo's DuckPlayer.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import WebKit
import Combine

struct DuckPlayerView: View {
    let videoID: String
    @ObservedObject var manager: DuckPlayerManager
    
    /// Dedicated WKWebView for the embed player, separate from the browser's web view.
    @StateObject private var playerWebViewManager: WebViewManager
    
    /// Error state for fallback UI
    @State private var hasError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = true
    
    /// Local cancellables for this view
    @State private var cancellables = Set<AnyCancellable>()
    
    init(videoID: String, manager: DuckPlayerManager) {
        self.videoID = videoID
        self.manager = manager
        
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        #if os(macOS)
        config.preferences.setValue(true, forKey: "allowsInlineMediaPlayback")
        
        // Enable fullscreen support for YouTube player
        // macOS 12.3+ uses public API, older versions use private API
        if #available(macOS 12.3, *) {
            config.preferences.isElementFullscreenEnabled = true
        } else {
            config.preferences.setValue(true, forKey: "fullScreenEnabled")
        }
        config.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
        #endif
        
        _playerWebViewManager = StateObject(wrappedValue: WebViewManager(configuration: config))
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Rectangle()
                .fill(Color.black.opacity(0.96))
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    closePlayer()
                }
            
            VStack(spacing: 0) {
                // Top padding to account for macOS title bar
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 28)
                
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duck Player")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                        Text("Privacy Protection Active")
                            .foregroundColor(.green.opacity(0.8))
                            .font(.system(size: 10, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Button(action: closePlayer) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .accessibilityLabel("Close Duck Player")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // Video Player or Error State
                ZStack {
                    Color.black
                    
                    if hasError {
                        // Error fallback view
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            
                            Text("Unable to load video")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(errorMessage.isEmpty ? "The video may be restricted or unavailable." : errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    loadVideo()
                                }) {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                
                                Button(action: {
                                    openOnYouTube()
                                }) {
                                    Label("Open on YouTube", systemImage: "arrow.up.forward")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .tint(.white)
                            }
                        }
                    } else {
                        // WebView - fills available space without restrictive constraints
                        WebViewContainer(webView: playerWebViewManager.webView)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.6), radius: 30)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                    }
                }
                .frame(maxWidth: 1100, maxHeight: 800)
                .padding(.vertical, 60)
                .padding(.horizontal, 40)
                
                // Footer
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("YouTube trackers and personalized ads are blocked in this player.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 25)
                
                Spacer()
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.05)),
            removal: .opacity
        ))
        .onAppear {
            setupErrorHandling()
            loadVideo()
        }
        .onDisappear {
            teardownPlayer()
        }
    }
    
    // MARK: - Private
    
    private func closePlayer() {
        teardownPlayer()
        manager.closePlayer()
    }
    
    /// Sets up error handling by observing navigation failures
    private func setupErrorHandling() {
        // Observe loading state
        playerWebViewManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { loading in
                if !loading {
                    self.isLoading = false
                    // Check if the page actually loaded content
                    self.checkForLoadErrors()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Checks if the embed actually loaded or shows an error
    private func checkForLoadErrors() {
        // Check the page title or URL to detect errors
        playerWebViewManager.webView.evaluateJavaScript("document.title") { result, error in
            DispatchQueue.main.async { [self] in
                if let title = result as? String {
                    // YouTube error pages often have specific titles
                    if title.contains("Error") || title.contains("unavailable") || title.contains("restricted") {
                        showError("This video is restricted or unavailable for embedding.")
                    }
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        self.errorMessage = message
        self.hasError = true
    }
    
    /// Opens the video directly on YouTube as a fallback
    private func openOnYouTube() {
        guard let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)") else { return }
        NSWorkspace.shared.open(url)
        closePlayer()
    }
    
    /// Aggressively tears down the player's WKWebView to stop audio/video.
    /// Per AGENTS.md: WKWebView objects are persistent and prone to leaking
    /// if not torn down aggressively.
    private func teardownPlayer() {
        let webView = playerWebViewManager.webView
        webView.stopLoading()
        
        // Navigate to about:blank to detach the web content process and stop media.
        if let blankURL = URL(string: "about:blank") {
            webView.load(URLRequest(url: blankURL))
        }
        
        // Full teardown of the WebViewManager (removes delegates, script handlers, etc.)
        playerWebViewManager.teardown()
    }
    
    private func loadVideo() {
        isLoading = true
        hasError = false
        errorMessage = ""
        
        let youtubeURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
        guard let embedURL = DuckPlayerNavigator.getEmbedURL(for: youtubeURL) else {
            showError("Unable to create embed URL for this video.")
            return
        }
        
        // Load the embed URL with localhost referer as specified
        var request = URLRequest(url: embedURL)
        request.setValue("http://localhost", forHTTPHeaderField: "Referer")
        playerWebViewManager.webView.load(request)
    }
}


