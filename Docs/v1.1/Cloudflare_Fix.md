# Version 1.1 - Cloudflare Captcha Loop Fix

## Overview

Fixed critical Cloudflare captcha verification loop that caused infinite reload cycles on protected websites.

## Problem

Users were experiencing an infinite loop when accessing Cloudflare-protected sites:
- "Checking your browser" captcha would repeatedly reload
- Custom user agent was causing detection as non-standard browser
- NSURLErrorCancelled (-999) errors during redirects triggered unnecessary error handling
- Missing authentication challenge handling for verification tokens

## Changes

### 1. Shared Process Pool (SpaceManager.swift)

Added shared `WKProcessPool` across all web views to ensure consistent TLS/Network state:

```swift
public class SpaceManager: ObservableObject {
    /// Shared process pool for all web views to ensure consistent TLS/Network state
    public let processPool = WKProcessPool()
    // ...
}
```

**Why:** Cloudflare verification relies on TLS fingerprint consistency. Each web view using its own process pool caused verification state to be lost.

### 2. User Agent Strategy (WebViewManager.swift)

**Before:**
```swift
private let defaultUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
webView.customUserAgent = defaultUserAgent
```

**After:**
```swift
config.processPool = SpaceManager.shared.processPool
// Use applicationNameForUserAgent to allow WebKit to build a perfect Safari-like UA
config.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
```

**Why:** Using `applicationNameForUserAgent` lets WebKit construct a proper Safari user agent instead of hardcoding one. This makes the browser appear more like genuine Safari to Cloudflare.

### 3. Authentication Challenge Handling

Added explicit handling for authentication challenges including Private Access Tokens:

```swift
public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // For most challenges, we can just use the default handling
    // but explicitly allowing the challenge to proceed helps with some verification systems
    completionHandler(.performDefaultHandling, nil)
}
```

### 4. Error Handling Improvements

Filtered out `NSURLErrorCancelled` (-999) which is common during Cloudflare redirects:

```swift
public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    // NSURLErrorCancelled (-999) is common during redirects and Cloudflare challenges
    if (error as NSError).code == NSURLErrorCancelled { return }
    // ... error handling
}

public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    // NSURLErrorCancelled (-999) is common during redirects and Cloudflare challenges
    if (error as NSError).code == NSURLErrorCancelled { return }
    // ... error handling
}
```

### 5. Safari-Like Preferences

Added preferences to appear more like regular Safari:

```swift
webView.configuration.preferences.setValue(true, forKey: "javaScriptCanOpenWindowsAutomatically")
webView.configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
```

### 6. Removed Debug Console Bridge

Removed the JavaScript console bridge that was injecting scripts into pages:

```swift
// REMOVED: Console bridge script and WKScriptMessageHandler conformance
// This reduces fingerprinting surface and prevents interference with verification scripts
```

## Testing

- ✅ Cloudflare-protected sites now load without loops
- ✅ Verification completes successfully
- ✅ No regression on regular websites
- ✅ Private Access Token challenges handled correctly

## Files Modified

- `Swift Browser/Managers/SpaceManager.swift` (+3 lines)
- `Swift Browser/WebViewStore/WebViewManager.swift` (-63 lines, simplified)

## Commit

`5a041f9129de2cd55f850feaee2eaf7eb318b258`

## Impact

**Severity:** High (blocking bug)  
**User Impact:** Restored access to Cloudflare-protected websites  
**Technical Debt:** Reduced (removed debug code from production)

---

*Fixed by: nightguarder*  
*Date: Thu Feb 12 20:49:56 2026 +0100*
