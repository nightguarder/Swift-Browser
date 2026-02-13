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

/// Manages DuckPlayer state and navigation interception.
public final class DuckPlayerManager: ObservableObject {
    @Published public var isPresented: Bool = false
    @Published public var currentVideoID: String?
    
    private var settings: DuckPlayerSettings {
        return DuckPlayerSettings.shared
    }
    
    public init() {}
    
    /// Determines if a navigation action should be intercepted for DuckPlayer.
    public func shouldIntercept(url: URL) -> Bool {
        guard DuckPlayerNavigator.extractVideoID(from: url) != nil,
              DuckPlayerNavigator.isYouTubeVideo(url) else {
            return false
        }
        
        switch settings.mode {
        case .enabled, .alwaysAsk:
            return true
        case .disabled:
            return false
        }
    }
    
    /// Handles the interception by potentially presenting the player.
    public func handleInterception(url: URL) {
        guard let videoID = DuckPlayerNavigator.extractVideoID(from: url) else { return }
        
        switch settings.mode {
        case .enabled:
            playVideo(id: videoID)
        case .alwaysAsk:
            // For MVP: Auto-open. Ideally, this would show a prompt.
            playVideo(id: videoID)
        case .disabled:
            break
        }
    }
    
    public func playVideo(id: String) {
        self.currentVideoID = id
        self.isPresented = true
    }
    
    public func closePlayer() {
        self.isPresented = false
        self.currentVideoID = nil
    }
}
