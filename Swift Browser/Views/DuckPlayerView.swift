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

struct DuckPlayerView: View {
    let videoID: String
    @ObservedObject var manager: DuckPlayerManager
    
    // We use a dedicated state object for the player webview
    @StateObject var webViewManager: WebViewManager
    
    init(videoID: String, manager: DuckPlayerManager) {
        self.videoID = videoID
        self.manager = manager
        
        let config = WKWebViewConfiguration()
        // Allow inline playback and AirPlay
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Initialize WebViewManager with this custom config
        // Note: WebViewManager init accepts optional configuration
        _webViewManager = StateObject(wrappedValue: WebViewManager(configuration: config))
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    manager.closePlayer()
                }
            
            VStack {
                // Header with Close Button
                HStack {
                    Spacer()
                    Button(action: {
                        manager.closePlayer()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                
                // Video Player Container
                // We reuse the existing WebViewContainer but point it to our local webViewManager
                // WebViewContainer(webView: webViewManager.webView)
                Color.blue
                    .frame(maxWidth: 900, maxHeight: 506) // Approx 16:9
                    .shadow(radius: 20)
                    .onAppear {
                        loadVideo()
                    }
                
                Text("Watching in Duck Player")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
        }
        .transition(.opacity)
    }
    
    private func loadVideo() {
        // Use the privacy-enhanced embed URL
        // Reference: https://duckduckgo.com/duckduckgo-help-pages/privacy/duck-player/
        let embedURLString = "https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&iv_load_policy=1&modestbranding=1&rel=0"
        if let url = URL(string: embedURLString) {
            webViewManager.load(url.absoluteString)
        }
    }
}
