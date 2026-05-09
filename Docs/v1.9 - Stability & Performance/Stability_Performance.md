# Stability & Performance

**Version:** 1.9  
**Date:** May 2026  
**Commit:** (uncommitted)

## Build & Release

### Copying to Applications

After building, copy the app to your Applications folder:

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/Swift_Browser-*/Build/Products/Debug/Swift\ Browser.app /Applications/
```

This release addresses critical bugs discovered during development and introduces performance optimizations for tab management. The most significant fix resolves an inverted logic error in tab discarding that was causing incorrect tab lifecycle behavior.

**Previous version:** v1.8 (Fire Button & Storage Control)  
- `94316026d1880fdbcbaaff098b65cab9739be2ce`

---

## Critical Bug Fix: Tab Discarding Logic

### Problem
In `TabManager.swift:334`, the condition for discarding tabs was inverted:

```swift
// BEFORE (buggy)
guard tabsToKeep.contains(tab.id) else { continue }

// AFTER (fixed)
guard !tabsToKeep.contains(tab.id) else { continue }
```

This caused the browser to:
- **Keep** tabs that should have been discarded (wasting memory)
- **Discard** tabs that should have been kept (losing page state)

### Impact
Background tabs in inactive spaces were not being properly released, leading to increased memory usage and WebKit process bloat.

---

## Performance: Idle Discard Interval

### Change
Reduced the frequency of idle tab discard checks from **1 minute to 5 minutes**:

```swift
// Before
private let idleDiscardCheckInterval: TimeInterval = 60

// After
private let idleDiscardCheckInterval: TimeInterval = 300 // 5 minutes
```

### Rationale
Checking every minute was too aggressive for marginal benefit. Most users don't switch spaces frequently, and WebKit already manages its own memory. The 5-minute interval strikes a better balance between responsiveness and CPU efficiency.

---

## Feature: Tab Limit

### Overview
Added a maximum of **50 tabs** to prevent unbounded WebKit process growth:

```swift
private static let maxTabs = 50

public func addTab(...) {
    guard tabs.count < Self.maxTabs else { return }
    // ... create tab
}
```

### Rationale
Each tab with a WebView consumes significant memory. With multiple spaces and many tabs, users could inadvertently create dozens of WebKit processes. The 50-tab limit is generous (10 tabs per space for 5 spaces) while remaining memory-conscious.

---

## Bug Fix: Async Cookie Injection

### Problem
When restoring or duplicating tabs, cookies were not properly injected before the page loaded, causing session loss on some sites.

### Solution
Added completion handlers to ensure cookies are fully injected before loading URLs:

```swift
// Before
CookiePersistenceManager.shared.injectCookiesIntoDataStore(for: space, dataStore: dataStore)
webView.load(tab.url)

// After
CookiePersistenceManager.shared.injectCookiesIntoDataStore(for: space, dataStore: dataStore) {
    webView.load(tab.url)
}
```

### Affected Functions
- `TabManager.restoreTabIfNeeded(_:)`
- `TabManager.ensureWebView(for:urlToLoad:)`
- `TabManager.duplicate(_:)` 

---

## Bug Fix: Stale Subscriptions

### Problem
When a tab's WebView was discarded, the Combine subscriptions remained active, potentially causing memory leaks and unexpected behavior.

### Solution
Clear subscriptions when WebView is nil:

```swift
@Published public var webView: WebViewManager? {
    didSet {
        if webView == nil && oldValue != nil {
            cancellables.removeAll()
            setupBindings()
        }
    }
}
```

---

## Bug Fix: Double-Free in WebViewManager

### Problem
The `teardown()` and `deinit` methods could trigger double-cleanup, causing crashes.

### Solution
Improved teardown logic with proper guards:

```swift
deinit {
    guard !isTornDown else { return }
    // ... cleanup
}

public func teardown() {
    guard !isTornDown else { return }
    isTornDown = true
    // ... cleanup
}
```

---

## Cleanup: NotificationCenter Observer

### Change
Added proper cleanup in `TabManager.deinit`:

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
    // ... existing cleanup
}
```

---

## Critical Bug Fix: Locked-Tab Navigation Interception

### Problem
In `WebViewManager.swift:322-329`, the locked-tab navigation handler unconditionally cancelled **all** main-frame navigations when `onLockedTabNavigation` was non-nil, before checking whether the tab was actually locked. Since `setupManagerCallbacks` sets this closure on every WebView, every page load was silently cancelled.

```swift
// BEFORE (buggy)
if onLockedTabNavigation != nil {
    onLockedTabNavigation?(url)
    decisionHandler(.cancel)   // ← Always cancels, even for unlocked tabs
    return
}

// AFTER (fixed)
if onLockedTabNavigation?(url) == true {
    decisionHandler(.cancel)   // ← Only cancels when closure returns true
    return
}
```

### Impact
No webpage could load — every navigation was intercepted and cancelled before the page started rendering. Affected all tabs, locked or unlocked.

---

## Session File Reset

If the session file becomes corrupted (e.g., duplicate pinned tabs that cannot be closed), delete the session file and relaunch:

```bash
rm ~/Library/Application\ Support/SwiftBrowser/session.json
```

The app will recreate a fresh set of locked Home tabs on next launch.

---

## Notes

- `WKProcessPool` is deprecated – creating multiple instances has no effect. See https://developer.apple.com/documentation/webkit/wkprocesspool

---

## Modified Files

| File | Changes |
|------|---------|
| `Managers/TabManager.swift` | +50 tab limit, 5-min idle interval, bug fix, async cookies, notification cleanup |
| `Managers/CookiePersistenceManager.swift` | Added completion handler to `injectCookiesIntoDataStore` |
| `Models/BrowserTab.swift` | Clear stale subscriptions on discard |
| `WebViewStore/WebViewManager.swift` | Improved teardown prevents double-free |

---

## Related Documentation

- [v1.8 - Fire Button & Storage Control](../v1.8%20-%20Fire%20Button%20&%20Storage%20Control/Fire_Button_Storage_Control.md) - Storage management
- [v1.6 - Tab Navigation & Pinned Tabs](../v1.6%20-%20Tab%20Navigation%20&%20Pinned%20Tabs/Tab_Navigation.md) - Tab management basics
