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
                "url-filter": "^https?://([^/]+\\\\.)?googleadservices\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?google\\\\.com/pagead/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?google\\\\.com/ads/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?gstatic\\\\.com/pagead/.*",
                "resource-type": ["script", "image"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://connect\\\\.facebook\\\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?facebook\\\\.com/tr/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?facebook\\\\.com/v[0-9]+\\\\.[0-9]+/plugins/.*",
                "resource-type": ["script"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?fbcdn\\\\.net/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://platform\\\\.twitter\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?twitter\\\\.com/i/[a-z]+/analytics\\\\..*",
                "resource-type": ["script"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://syndication\\\\.twitter\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?amazon-adsystem\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?assoc-amazon\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?bing\\\\.com/action/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?bat\\\\.bing\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?clarity\\\\.ms/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?linkedin\\\\.com/px/.*",
                "resource-type": ["image", "script"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?licdn\\\\.com/li/[a-z]+/insight\\\\.min\\\\.js",
                "resource-type": ["script"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?mixpanel\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?segment\\\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?segment\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://cdn\\\\.segment\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?hotjar\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?heap\\\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?plausible\\\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?amplitude\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?fullstory\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?kissmetrics\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?luckyorange\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?mouseflow\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?freshmarketer\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?pingdom\\\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?newrelic\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?nr-data\\\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?criteo\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?criteo\\\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?adnxs\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?adsafeprotected\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?moatads\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?taboola\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?outbrain\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?rubiconproject\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?pubmatic\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?openx\\\\.net/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?indexww\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?sharethrough\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?pinterest\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?snapchat\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?tiktok\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?redditstatic\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?reddit\\\\.com/api/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?youtube\\\\.com/ptracking",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?youtube\\\\.com/api/stats/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?youtube\\\\.com/pagead/.*",
                "resource-type": ["script", "image", "xmlhttprequest"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?disqus\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?disquscdn\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?intercom\\\\.io/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?intercomcdn\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?zendesk\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?zopim\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?driftt\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?crisp\\\\.chat/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?tidio\\\\.co/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?tawk\\\\.to/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?fingerprintjs\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://cdn\\\\.fingerprintjs\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?quantserve\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?scorecardresearch\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?comscore\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?mathtag\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?bluekai\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?addthis\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?sharethis\\\\.com/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?gravatar\\\\.com/.*",
                "resource-type": ["script", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?mailchimp\\\\.com/mc/.*",
                "resource-type": ["script", "image", "xmlhttprequest"],
                "load-type": ["third-party"]
            },
            "action": { "type": "block" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?googleapis\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?gstatic\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?ajax\\\\.googleapis\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?fonts\\\\.googleapis\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?fonts\\\\.gstatic\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?cdnjs\\\\.cloudflare\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?unpkg\\\\.com/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?jsdelivr\\\\.net/.*",
                "load-type": ["third-party"]
            },
            "action": { "type": "ignore-previous-rules" }
        },
        {
            "trigger": {
                "url-filter": "^https?://([^/]+\\\\.)?bootstrapcdn\\\\.com/.*",
                "load-type": ["third-party"]
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

    public func removeBlocklist(from userContentController: WKUserContentController) {
        guard let ruleList = compiledRuleList else { return }
        userContentController.remove(ruleList)
        compiledRuleList = nil
    }
}
