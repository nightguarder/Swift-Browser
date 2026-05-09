//
//  SearchEngineBlocker.swift
//  Swift Browser
//
//  Enhanced content blocker for search result filtering
//  Based on uBlacklist concepts adapted for WKWebView constraints
//

import Foundation
import WebKit
import Combine

private enum UBlocklistKeys {
    static let subscriptionURLs = "ublocklistSubscriptionURLs"
    static let lastRefresh = "ublocklistLastRefresh"
}

public struct UBlocklistSubscription: Codable, Identifiable {
    public let id: UUID
    public let url: URL
    public let name: String
    public var isEnabled: Bool
    
    public init(id: UUID = UUID(), url: URL, name: String, isEnabled: Bool = true) {
        self.id = id
        self.url = url
        self.name = name
        self.isEnabled = isEnabled
    }
}

/// Enumerates supported search engines for specialized blocking
public enum SearchEngine: String, CaseIterable {
    case google = "google.com"
    case bing = "bing.com"
    case yahoo = "yahoo.com"
    case duckduckgo = "duckduckgo.com"
    case ecosia = "ecosia.org"
    case startpage = "startpage.com"
    case searx = "searx"
    case kagi = "kagi.com"
    
    /// Returns the host pattern used for detection
    var hostPattern: String {
        switch self {
        case .searx: return "searx"  // Special case for self-hosted instances
        default: return rawValue
        }
    }
    
    /// Determines if a URL host matches this search engine
    func matches(host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        
        switch self {
        case .searx:
            // SearX instances vary widely, check for common indicators
            return host.contains("searx") || 
                   host.contains("searx") ||
                   host.hasSuffix(".searx.net")
        default:
            return host.contains(hostPattern)
        }
    }
}

/// Represents a search-engine-specific blocking rule
public struct SearchEngineRule {
    public let engine: SearchEngine
    public let pattern: String
    public let isEnabled: Bool
    
    public init(engine: SearchEngine, pattern: String, isEnabled: Bool = true) {
        self.engine = engine
        self.pattern = pattern
        self.isEnabled = isEnabled
    }
}

/// Manages search-engine-specific content blocking rules
public final class SearchEngineBlocker: ObservableObject {
    public static let shared = SearchEngineBlocker()
    
    @Published private(set) var searchRules: [SearchEngine: [String]] = [:]
    @Published private(set) var isEnabled = true
    @Published private(set) var subscriptions: [UBlocklistSubscription] = []
    @Published private(set) var lastRefresh: Date?
    
    private let defaults = UserDefaults.standard
    
    private init() {
        loadDefaultSearchRules()
        loadSubscriptions()
    }
    
    private func loadSubscriptions() {
        guard let data = defaults.data(forKey: UBlocklistKeys.subscriptionURLs),
              let saved = try? JSONDecoder().decode([UBlocklistSubscription].self, from: data) else {
            return
        }
        subscriptions = saved
    }
    
    private func saveSubscriptions() {
        guard let data = try? JSONEncoder().encode(subscriptions) else { return }
        defaults.set(data, forKey: UBlocklistKeys.subscriptionURLs)
    }
    
    public func addSubscription(url: URL, name: String) {
        let sub = UBlocklistSubscription(url: url, name: name)
        subscriptions.append(sub)
        saveSubscriptions()
        
        Task {
            await applyUBlacklistSubscription(from: url)
        }
    }
    
    public func removeSubscription(_ subscription: UBlocklistSubscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()
    }
    
    public func refreshSubscriptions() async {
        for sub in subscriptions where sub.isEnabled {
            await applyUBlacklistSubscription(from: sub.url)
        }
        lastRefresh = Date()
        defaults.set(lastRefresh, forKey: UBlocklistKeys.lastRefresh)
    }
    
    private func loadDefaultSearchRules() {
        for engine in SearchEngine.allCases {
            searchRules[engine] = []
        }
    }
    
    public func addRule(_ pattern: String, for engine: SearchEngine) {
        guard !pattern.isEmpty else { return }
        
        var engineRules = searchRules[engine] ?? []
        if !engineRules.contains(pattern) {
            engineRules.append(pattern)
            searchRules[engine] = engineRules
        }
    }
    
    public func removeRule(_ pattern: String, for engine: SearchEngine) {
        var engineRules = searchRules[engine] ?? []
        engineRules.removeAll { $0 == pattern }
        searchRules[engine] = engineRules
    }
    
    public func rules(for engine: SearchEngine) -> [String] {
        return searchRules[engine] ?? []
    }
    
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    public func shouldBlockURL(_ url: URL, inSearchResultsFor host: String?) -> Bool {
        guard isEnabled,
              let host = host,
              let engine = SearchEngine.allCases.first(where: { $0.matches(host: host) }) else {
            return false
        }
        
        let engineRules = rules(for: engine)
        let urlString = url.absoluteString.lowercased()
        
        for pattern in engineRules {
            if matchesPattern(urlString, pattern: pattern.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    private func matchesPattern(_ string: String, pattern: String) -> Bool {
        if !pattern.contains("*") {
            return string == pattern
        }
        
        var regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        
        regexPattern = "^\(regexPattern)$"
        
        return string.range(of: regexPattern, options: .regularExpression) != nil
    }
    
    public func convertUBlacklistRules(_ rules: [String]) -> [SearchEngine: [String]] {
        var converted: [SearchEngine: [String]] = [:]
        
        for engine in SearchEngine.allCases {
            converted[engine] = []
        }
        
        for rule in rules {
            let trimmed = rule.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("!") {
                continue
            }
            
            if trimmed.hasPrefix("@@") {
                continue
            }
            
            for engine in SearchEngine.allCases {
                converted[engine]?.append(trimmed)
            }
        }
        
        return converted
    }
    
    public func importUBlacklistSubscription(from url: URL) async throws -> [SearchEngine: [String]] {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        var rules: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty || 
               trimmed.hasPrefix("#") || 
               trimmed.hasPrefix("!") ||
               trimmed == "---" {
                continue
            }
            
            if trimmed.hasPrefix("@@") {
                continue
            }
            
            rules.append(trimmed)
        }
        
        return convertUBlacklistRules(rules)
    }
    
    public func applyUBlacklistSubscription(from url: URL) async {
        do {
            let importedRules = try await importUBlacklistSubscription(from: url)
            
            for engine in SearchEngine.allCases {
                searchRules[engine] = []
                if let engineRules = importedRules[engine] {
                    searchRules[engine] = engineRules
                }
            }
        } catch {
            print("Failed to import uBlacklist subscription from \(url): \(error)")
        }
    }
}