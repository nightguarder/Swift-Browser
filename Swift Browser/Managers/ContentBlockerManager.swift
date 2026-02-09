//
//  ContentBlockerManager.swift
//  Swift Browser
//
//  Created by nightguarder on 2/2/26.
//

import Foundation
import WebKit

/// Manager responsible for compiling and applying content blocking rules
/// Uses WKContentRuleList to block ads, trackers, and analytics in the most performant way
public final class ContentBlockerManager {
    public static let shared = ContentBlockerManager()
    
    // MARK: - Block List Rules
    
    /// Comprehensive block list targeting major tracking/advertising platforms
    /// Rules are organized by category for maintainability
    private static let blocklistJSON = """
    [
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?google-analytics\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?googletagmanager\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?googlesyndication\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?googletagservices\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?doubleclick\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?googleadservices\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?google\\.com/pagead/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?google\\.com/ads/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?gstatic\\.com/pagead/.*",
                "resource-type": ["script", "image"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://connect\\.facebook\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?facebook\\.com/tr/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?facebook\\.com/v[0-9]+\\.[0-9]+/plugins/.*",
                "resource-type": ["script"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?fbcdn\\.net/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://platform\\.twitter\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?twitter\\.com/i/[a-z]+/analytics\\..*",
                "resource-type": ["script"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://syndication\\.twitter\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?amazon-adsystem\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?assoc-amazon\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?bing\\.com/action/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?bat\\.bing\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?clarity\\.ms/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?linkedin\\.com/px/.*",
                "resource-type": ["image", "script"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?licdn\\.com/li/[a-z]+/insight\\.min\\.js",
                "resource-type": ["script"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?mixpanel\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?segment\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?segment\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://cdn\\.segment\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?hotjar\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?heap\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?plausible\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?amplitude\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?fullstory\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?kissmetrics\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?luckyorange\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?mouseflow\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?freshmarketer\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?pingdom\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?newrelic\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?nr-data\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?criteo\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?criteo\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?adnxs\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?adsafeprotected\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?moatads\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?taboola\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?outbrain\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?rubiconproject\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?pubmatic\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?openx\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?indexww\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?sharethrough\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?pinterest\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?snapchat\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?tiktok\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?redditstatic\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?reddit\\.com/api/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?youtube\\.com/ptracking",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?youtube\\.com/api/stats/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?youtube\\.com/pagead/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?disqus\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?disquscdn\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?intercom\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?intercomcdn\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?zendesk\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?zopim\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?driftt\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?crisp\\.chat/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?tidio\\.co/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?tawk\\.to/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?fingerprintjs\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://cdn\\.fingerprintjs\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?quantserve\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?scorecardresearch\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?comscore\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?mathtag\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?bluekai\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?addthis\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?sharethis\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?gravatar\\.com/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?mailchimp\\.com/mc/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?googleapis\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?gstatic\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?ajax\\.googleapis\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?fonts\\.googleapis\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?fonts\\.gstatic\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?cdnjs\\.cloudflare\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?unpkg\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?jsdelivr\\.net/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\.)?bootstrapcdn\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        }
    ]
    """
    
    // MARK: - Properties
    
    private var compiledRuleList: WKContentRuleList?
    private let compilationQueue = DispatchQueue(label: "com.swiftbrowser.contentblocker", qos: .utility)
    
    /// Tracks if rules are currently being compiled
    private var isCompiling = false
    
    // MARK: - Public Methods
    
    /// Applies the block list to a WKWebView configuration
    /// - Parameters:
    ///   - configuration: The WKWebViewConfiguration to apply rules to
    ///   - completion: Called when application is complete (success or failure)
    public func applyBlocklist(to configuration: WKWebViewConfiguration, completion: @escaping (Bool) -> Void) {
        // If already compiled, apply immediately
        if let ruleList = compiledRuleList {
            configuration.userContentController.add(ruleList)
            completion(true)
            return
        }
        
        // Prevent concurrent compilations
        guard !isCompiling else {
            // Wait a bit and retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.applyBlocklist(to: configuration, completion: completion)
            }
            return
        }
        
        isCompiling = true
        
        compilationQueue.async { [weak self] in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "SwiftBrowserBlockList",
                encodedContentRuleList: Self.blocklistJSON
            ) { [weak self] ruleList, error in
                DispatchQueue.main.async {
                    self?.isCompiling = false
                    
                    if let error = error {
                        print("Content Blocker Error: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    guard let ruleList = ruleList else {
                        print("Content Blocker Error: Rule list compilation returned nil")
                        completion(false)
                        return
                    }
                    
                    self?.compiledRuleList = ruleList
                    configuration.userContentController.add(ruleList)
                    completion(true)
                }
            }
        }
    }
    
    /// Removes the block list from a user content controller
    /// - Parameter userContentController: The controller to remove rules from
    public func removeBlocklist(from userContentController: WKUserContentController) {
        WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: "SwiftBrowserBlockList") { ruleList, _ in
            if let ruleList = ruleList {
                userContentController.remove(ruleList)
            }
        }
    }
    
    /// Clears the cached compiled rule list
    /// Call this if you need to force recompilation (e.g., after app update with new rules)
    public func clearCache() {
        compiledRuleList = nil
        WKContentRuleListStore.default().removeContentRuleList(forIdentifier: "SwiftBrowserBlockList") { _ in }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// Validates the JSON rule list syntax
    public func validateRules() -> Bool {
        guard let data = Self.blocklistJSON.data(using: .utf8) else { return false }
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            if let array = json as? [[String: Any]] {
                print("Content Blocker: \(array.count) rules loaded")
                return true
            }
            return false
        } catch {
            print("Content Blocker JSON Error: \(error)")
            return false
        }
    }
    #endif
}
