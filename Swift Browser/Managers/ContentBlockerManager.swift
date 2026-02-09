//
//  ContentBlockerManager.swift
//  Swift Browser
//
//  Created by nightguarder on 2/2/26.
//

import Foundation
import WebKit

public final class ContentBlockerManager {
    public static let shared = ContentBlockerManager()
    
    private static let blocklistJSON = """
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
    
    private var compiledRuleList: WKContentRuleList?

    public func applyBlocklist(to configuration: WKWebViewConfiguration, completion: @escaping () -> Void) {
        if let ruleList = compiledRuleList {
            configuration.userContentController.add(ruleList)
            completion()
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "SwiftBrowserBlockList",
            encodedContentRuleList: Self.blocklistJSON
        ) { [weak self] ruleList, error in
            if let error = error {
                print("Content Blocker Error: \(error.localizedDescription)")
            } else if let ruleList = ruleList {
                self?.compiledRuleList = ruleList
                configuration.userContentController.add(ruleList)
            }
            completion()
        }
    }
}
