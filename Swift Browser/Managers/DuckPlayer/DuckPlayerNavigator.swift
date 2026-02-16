//
//  DuckPlayerNavigator.swift
//  Swift Browser
//
//  Adapted from DuckDuckGo/DuckPlayer
//

import Foundation
import WebKit

public struct DuckPlayerNavigator {
    
    /// Creates a privacy-focused embed URL using youtube-nocookie.com
    /// Format: youtube-nocookie.com/embed/{id}?rel=0&playsinline=1&color=white&autoplay=1
    public static func getEmbedURL(for youtubeURL: URL) -> URL? {
        guard let videoID = extractVideoID(from: youtubeURL) else {
            return nil
        }
        
        var components = URLComponents(string: "https://www.youtube-nocookie.com/embed/\(videoID)")
        guard components != nil else { return nil }
        components?.queryItems = [
            URLQueryItem(name: "rel", value: "0"),
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "color", value: "white"),
            URLQueryItem(name: "autoplay", value: "1"),
            URLQueryItem(name: "fs", value: "1"),  // Enable fullscreen button
            URLQueryItem(name: "modestbranding", value: "1"),  // Reduce YouTube branding
            URLQueryItem(name: "iv_load_policy", value: "3")  // Hide annotations
        ]
        
        return components?.url
    }
    
    /// Creates an internal duck://player/{videoID} URL for navigation interception
    public static func getDuckPlayerURL(videoID: String) -> URL? {
        return URL(string: "duck://player/\(videoID)")
    }

    public static func isYouTubeVideo(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "youtube.com" || host == "www.youtube.com" || host == "m.youtube.com" || host == "youtu.be"
    }
    
    public static func isYouTubeWatchPage(_ url: URL) -> Bool {
        guard isYouTubeVideo(url) else { return false }
        return url.path == "/watch" || url.path.hasPrefix("/watch")
    }

    public static func extractVideoID(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""

        // Handle youtu.be/{VIDEO_ID}
        if host == "youtu.be" {
            let videoID = url.lastPathComponent
            return isValidVideoID(videoID) ? videoID : nil
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
            let videoID = url.pathComponents[2]
            return isValidVideoID(videoID) ? videoID : nil
        }

        return nil
    }
    
    /// Validates that a string is a valid YouTube video ID format
    /// YouTube video IDs are typically 11 characters, alphanumeric with hyphens and underscores
    private static func isValidVideoID(_ id: String) -> Bool {
        guard !id.isEmpty else { return false }
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return id.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}
