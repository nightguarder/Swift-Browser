//
//  ContentBlockerManager.swift
//  Swift Browser
//
//  Created by nightguarder on 2/2/26.
//

import Foundation
import WebKit

final class ContentBlockerManager {
    static let shared = ContentBlockerManager()
    
    // Foundational blocklist for common ads and trackers
    // Uses the WKContentRuleList format (JSON)
    private let blocklistJSON = """
    [
        {
            "trigger": {
                "url-filter": ".*google-analytics\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*doubleclick\\\\.net/.*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*adservice\\\\.google\\\\..*/.*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*facebook\\\\.com/tr/.*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*googletagmanager\\\\.com/.*"
            },
            "action": {
                "type": "block"
            }
        }
    ]
    """
    
    func applyBlocklist(to configuration: WKWebViewConfiguration, completion: @escaping () -> Void) {
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "SwiftBrowserBlockList",
            encodedContentRuleList: blocklistJSON
        ) { ruleList, error in
            if let error = error {
                print("Content Blocker Error: \(error.localizedDescription)")
            } else if let ruleList = ruleList {
                configuration.userContentController.add(ruleList)
            }
            completion()
        }
    }
}
