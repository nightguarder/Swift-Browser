# Fire Button & Storage Control

**Version:** 1.8  
**Date:** March 2026  
**Commit:** 94316026d1880fdbcbaaff098b65cab9739be2ce

This release addresses storage bloat in the WebKit data stores and introduces a Fire button for instant data clearing, inspired by DuckDuckGo's fireproofing approach. The `WebsiteDataStore` folder was observed growing to 1.5 GB with no cleanup mechanism in place. This version adds automatic pruning, a manual fire button, and fireproof domains to preserve login sessions.

**Previous version:** v1.7 (minor bug fixes, home tab)  
- `6c80668ebb3ebcf747ac41ea0a911d06dd1800f3`  
- `2cf3a9f3540bea3117e659f653002bfcd53e1195`

---

## Storage Problem

The browser uses `WKWebsiteDataStore(forIdentifier:)` for each non-private space (General, Work, School). WebKit's internal disk cache has no size limit by default, causing unbounded growth. Observed: 1.5 GB in `~/Library/Containers/apple.Swift-Browser/Data/Library/WebKit/WebsiteDataStore/`.

Additionally, the "Reset Browser" function in Settings only cleared `WKWebsiteDataStore.default()`, which was not used by any persistent space — meaning 3 out of 4 spaces were never actually reset.

---

## Bug Fix: Reset Browser Now Clears All Spaces

### Problem
`SettingsView.swift:394` called `WKWebsiteDataStore.default().removeData(...)` but all persistent spaces use `WKWebsiteDataStore(forIdentifier:)`, not `.default()`.

### Fix
The reset function now iterates all spaces and clears each one's data store:

```swift
for space in SpaceManager.shared.spaces {
    let store = SpaceManager.shared.cookieDataStore(for: space)
    store.removeData(ofTypes: websiteDataTypes, modifiedSince: date) { }
}
```

---

## Fire Button

### Overview
A flame icon in the toolbar that clears all cookies, cache, localStorage, IndexedDB, blobs, and other website data across all spaces in one action. Fireproofed domains are preserved.

### Usage
1. Click the 🔥 button in the toolbar (between Downloads and the menu button)
2. Confirm "Burn" in the dialog
3. All non-fireproofed data is cleared from every space

### How It Works
The `StorageManager.burnAll()` method:
1. Iterates all spaces (General, Work, School, Private)
2. For private spaces: clears everything unconditionally
3. For persistent spaces: fetches `WKWebsiteDataRecord` list, filters out fireproofed domains, then removes the rest using `WKWebsiteDataStore.removeData(ofTypes:for:)`

---

## Fireproof Domains

### Overview
A list of domains whose login sessions are preserved when using the Fire button. Domains are normalized (lowercased, `www.` stripped) for consistent matching.

### Managing Fireproof Domains
- **Settings > Privacy & Security > Fireproof Domains**
- Type a domain (e.g., `github.com`) and click "Add"
- Click the X button next to a domain to remove it
- Add/remove via `FireproofDomains.shared.add(_:)` / `.remove(_:)` in code

### Storage
Domains are persisted in `UserDefaults` under the key `com.swiftbrowser.fireproofDomains` as a string array.

---

## Auto-Cleanup on Launch

### Overview
Website data older than 30 days is automatically cleared when the browser launches. This prevents long-term storage accumulation without requiring manual intervention.

### Behavior
- **Non-private spaces:** data modified more than 30 days ago is removed
- **Private spaces:** all data is cleared on every launch (private sessions do not persist)

### Configuration
Called in `Swift_BrowserApp.swift` during `.onAppear`:

```swift
StorageManager.shared.cleanupOldData(olderThanDays: 30)
```

---

## Technical Details

### New Files

| File | Lines | Purpose |
|------|-------|---------|
| `Managers/FireproofDomains.swift` | 59 | Singleton managing fireproof domain set in UserDefaults |
| `Managers/StorageManager.swift` | 97 | `burnAll()`, `cleanupOldData()`, `fetchDataRecordCount()` |
| `Views/FireButton.swift` | 27 | Toolbar button with confirmation alert |

### Modified Files

| File | Change |
|------|--------|
| `Views/SettingsView.swift:394-400` | Reset clears all per-space data stores |
| `Views/SettingsView.swift:158` | Added `FireproofDomainsSection` in Privacy & Security |
| `Views/SettingsView.swift:421` | Reset clears fireproofed domains |
| `Views/TopToolbar.swift:141-143` | Added `FireButton()` between Downloads and Control Center |
| `Swift_BrowserApp.swift:39` | Calls `StorageManager.shared.cleanupOldData()` on launch |

### URLCache Limitation

Setting `URLCache.shared` with disk/memory caps was tested but does not affect WKWebView. WebKit manages its own internal HTTP cache through `WKWebsiteDataStore` and ignores the shared `URLCache`. This approach was abandoned in favor of the direct `WKWebsiteDataStore.removeData` API used by both the Fire button and auto-cleanup.

---

## Related Documentation

- [v1.4 - Cookies Security](../v1.4%20-%20Cookies%20Security/Cookies_Security.md) - Per-space cookie isolation
- [v1.0 - Release Notes](../v1.0/ReleaseNotes.md) - Security audit and content blocking
