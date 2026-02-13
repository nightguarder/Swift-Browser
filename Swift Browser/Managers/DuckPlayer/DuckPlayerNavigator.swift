//
//  DuckPlayerNavigator.swift
//  Swift Browser
//
//  Adapted from DuckDuckGo/DuckPlayer
//

import Foundation
import WebKit

public struct DuckPlayerNavigator {
    
    public static func getDuckURL(for youtubeURL: URL) -> URL? {
        guard let components = URLComponents(url: youtubeURL, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              let videoID = queryItems.first(where: { $0.name == "v" })?.value else {
            return nil
        }
        
        // This is the Web Player URL.
        // Format: https://duckduckgo.com/?q={ID}&iax=videos&ia=videos&iai={ID}
        // We set 'q' to the ID or a generic term to ensure video vertical triggers.
        var duckComponents = URLComponents(string: "https://duckduckgo.com/")
        duckComponents?.queryItems = [
            URLQueryItem(name: "q", value: videoID), 
            URLQueryItem(name: "iax", value: "videos"),
            URLQueryItem(name: "ia", value: "videos"),
            URLQueryItem(name: "iai", value: videoID)
        ]
        
        return duckComponents?.url
    }
    
    // Alternative: The Embed Player (Private)
    public static func getEmbedURL(for youtubeURL: URL) -> URL? {
        guard let components = URLComponents(url: youtubeURL, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              let videoID = queryItems.first(where: { $0.name == "v" })?.value else {
            return nil
        }
        
        return URL(string: "https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&iv_load_policy=3&modestbranding=1&rel=0")
    }

    public static func isYouTubeVideo(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    public static func extractVideoID(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""

        // Handle youtu.be/{VIDEO_ID}
        if host.contains("youtu.be") {
            return url.lastPathComponent
        }

        // Handle youtube.com/watch?v={VIDEO_ID}
        if host.contains("youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let queryItems = components.queryItems {
                return queryItems.first(where: { $0.name == "v" })?.value
            }
        }

        // Handle youtube.com/embed/{VIDEO_ID}
        if url.pathComponents.count > 2 && url.pathComponents[1] == "embed" {
            return url.pathComponents[2]
        }

        return nil
    }
}
