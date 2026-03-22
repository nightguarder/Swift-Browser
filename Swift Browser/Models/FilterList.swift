//
//  FilterList.swift
//  Swift Browser
//
//  Model for filter list metadata
//

import Foundation

enum FilterPriority: Int, CaseIterable, Codable {
    case critical = 1
    case high = 2
    case medium = 3
    case low = 4
    
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

struct FilterList: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let sourceURL: URL
    let priority: FilterPriority
    var isEnabled: Bool
    var lastUpdated: Date?
    var ruleCount: Int?
    
    static let defaultLists: [FilterList] = [
        FilterList(
            id: "easylist",
            name: "EasyList",
            description: "Primary ad blocking filter list",
            sourceURL: URL(string: "https://raw.githubusercontent.com/easylist/easylist/master/easylist/easylist.txt")!,
            priority: .critical,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "nordic-filters",
            name: "Nordic Filters",
            description: "Comprehensive ad and tracker blocking",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/NorwegianList.txt")!,
            priority: .critical,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "anti-malware",
            name: "Anti-Malware List",
            description: "Blocks malware, phishing, and scam domains",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion%20Sprout%27s%20Anti-Malware%20List.txt")!,
            priority: .critical,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "annoyances",
            name: "Annoyances List",
            description: "Cookie notices, popups, and newsletter banners",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/AnnoyancesList.txt")!,
            priority: .high,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "url-shortener",
            name: "Legitimate URL Shortener",
            description: "Removes tracking parameters from URLs",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt")!,
            priority: .high,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "social",
            name: "Social Media List",
            description: "Blocks social media widgets and tracking buttons",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/SocialShareList.txt")!,
            priority: .medium,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "login-bypass",
            name: "Browse Without Login",
            description: "Bypass login walls and subscription paywalls",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/BrowseWebsitesWithoutLoggingIn.txt")!,
            priority: .medium,
            isEnabled: true,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "german",
            name: "German Filters",
            description: "Regional filter for German websites",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion%20Sprout-s%20German%20Filter%20List.txt")!,
            priority: .low,
            isEnabled: false,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "czech-slovak",
            name: "EasyList Czech/Slovak",
            description: "Regional filter for Czech and Slovak websites",
            sourceURL: URL(string: "https://raw.githubusercontent.com/tomasko126/easylistczechandslovak/master/filters.txt")!,
            priority: .low,
            isEnabled: false,
            lastUpdated: nil,
            ruleCount: nil
        ),
        FilterList(
            id: "czech-dandelion",
            name: "Dandelion Czech",
            description: "Czech filter from Dandelion Sprout",
            sourceURL: URL(string: "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion%20Sprout-s%20Czech%20List.txt")!,
            priority: .low,
            isEnabled: false,
            lastUpdated: nil,
            ruleCount: nil
        )
    ]
}

struct FilterListState: Codable {
    var lists: [FilterList]
    var lastFullUpdate: Date?
    var ruleLimitWarning: Bool
    
    static let empty = FilterListState(
        lists: FilterList.defaultLists,
        lastFullUpdate: nil,
        ruleLimitWarning: false
    )
}
