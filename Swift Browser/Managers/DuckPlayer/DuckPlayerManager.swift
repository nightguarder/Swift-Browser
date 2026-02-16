//
//  DuckPlayerManager.swift
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

import Foundation
import Combine
import WebKit

/// Manages DuckPlayer state, navigation interception, and native overlay presentation.
/// Uses KVO on webView.url to detect YouTube SPA navigations instead of JavaScript injection.
public final class DuckPlayerManager: ObservableObject {
    @Published public var isPresented: Bool = false
    @Published public var currentVideoID: String?
    
    /// Whether to show the native pill overlay on the current YouTube page
    @Published public var shouldShowOverlay: Bool = false
    
    /// The current YouTube video ID detected on the page (for overlay)
    @Published public var overlayVideoID: String?
    
    private var settings: DuckPlayerSettings {
        return DuckPlayerSettings.shared
    }
    
    private var closeWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    private var urlObservation: AnyCancellable?
    
    public init() {
        setupNotificationObservers()
    }
    
    deinit {
        closeWorkItem?.cancel()
        urlObservation?.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Observe mode changes to update overlay visibility
        NotificationCenter.default.publisher(for: DuckPlayerSettings.modeDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateOverlayVisibility()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - URL Observation (KVO)
    
    /// Attaches KVO observer to the webView's URL to detect YouTube SPA navigations
    public func attach(to webView: WKWebView) {
        urlObservation?.cancel()
        
        urlObservation = webView.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] url in
                self?.handleURLChange(url)
            }
    }
    
    /// Detaches the URL observer
    public func detach() {
        urlObservation?.cancel()
        urlObservation = nil
        shouldShowOverlay = false
        overlayVideoID = nil
    }
    
    /// Handles URL changes from KVO - detects YouTube video pages
    private func handleURLChange(_ url: URL?) {
        guard let url = url else {
            shouldShowOverlay = false
            overlayVideoID = nil
            return
        }
        
        // Check if we're on a YouTube watch page
        if DuckPlayerNavigator.isYouTubeWatchPage(url),
           let videoID = DuckPlayerNavigator.extractVideoID(from: url) {
            overlayVideoID = videoID
            updateOverlayVisibility()
        } else {
            shouldShowOverlay = false
            overlayVideoID = nil
        }
    }
    
    /// Updates overlay visibility based on current settings and page state
    private func updateOverlayVisibility() {
        guard overlayVideoID != nil else {
            shouldShowOverlay = false
            return
        }
        
        switch settings.mode {
        case .enabled:
            // In "Always Open" mode, we don't show the overlay (navigation is intercepted before page loads)
            shouldShowOverlay = false
            
        case .alwaysAsk:
            // Show overlay unless user dismissed it
            shouldShowOverlay = !settings.alwaysAskOverlayHidden
            
        case .disabled:
            shouldShowOverlay = false
        }
    }
    
    // MARK: - Navigation Interception
    
    /// Called from `decidePolicyFor navigationAction`.
    /// Returns `true` only when we should CANCEL the navigation (i.e., auto-redirect).
    public func shouldInterceptNavigation(url: URL) -> Bool {
        guard DuckPlayerNavigator.isYouTubeVideo(url),
              DuckPlayerNavigator.extractVideoID(from: url) != nil else {
            return false
        }
        
        // Only auto-intercept in "Always Open" mode
        return settings.mode == .enabled
    }
    
    /// Handles the auto-redirect for `.enabled` mode.
    /// Called after `shouldInterceptNavigation` returns true.
    public func handleAutoRedirect(url: URL) {
        guard let videoID = DuckPlayerNavigator.extractVideoID(from: url) else { return }
        playVideo(id: videoID)
    }
    
    // MARK: - Player Control
    
    public func playVideo(id: String) {
        // Cancel any pending close cleanup to prevent it from clearing this new video
        closeWorkItem?.cancel()
        closeWorkItem = nil
        
        self.currentVideoID = id
        self.isPresented = true
    }
    
    public func closePlayer() {
        self.isPresented = false
        // Delay clearing videoID so the closing animation can complete.
        // Uses a cancellable work item so that a rapid playVideo() call
        // during the delay window won't have its video ID cleared.
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isPresented {
                self.currentVideoID = nil
            }
            // Restore the pill overlay if we're still on a YouTube page
            self.updateOverlayVisibility()
            self.closeWorkItem = nil
        }
        self.closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    /// Opens the overlay's video in Duck Player
    public func openOverlayVideo() {
        guard let videoID = overlayVideoID else { return }
        playVideo(id: videoID)
        // Hide overlay after opening
        shouldShowOverlay = false
    }
    
    /// Dismisses the overlay permanently
    public func dismissOverlay() {
        settings.alwaysAskOverlayHidden = true
        shouldShowOverlay = false
    }
}
