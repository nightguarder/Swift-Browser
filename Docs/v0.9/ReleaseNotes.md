# Swift Browser v0.9 - Release & Developer Notes

**Release Date:** February 9, 2026

## 1. Overview
Version 0.9 focuses on refining the address bar experience with intelligent suggestions, improved keyboard navigation, and enhanced privacy controls for private spaces. This release also introduces typography standardization and resolves several UI layout issues.

---

## 2. New Features

### Smart Address Bar Suggestions
- **Unified Suggestion System:** Consolidated duplicate suggestion files into a single, maintainable component.
- **Multi-Source Suggestions:** Address bar now shows suggestions from Bookmarks, Browsing history, and DuckDuckGo search suggestions (max 5 each).
- **Visual Polish:** Suggestions appear in a floating overlay with rounded corners and `.ultraThinMaterial` background.

### Full Keyboard Navigation
- **Arrow Keys:** Navigate up/down through suggestions.
- **Return/Enter:** Select highlighted suggestion.
- **Escape:** Close suggestions and unfocus address bar.
- **Implementation:** Uses `NSEvent` monitor for reliable key capture even when the address bar has focus.

### Private Space Privacy Enhancements
- **Isolated Suggestions:** Private spaces no longer show history or bookmark suggestions.
- **Search-Only Mode:** Private tabs only display DuckDuckGo search suggestions.
- **Data Isolation:** Maintains separate `WKWebsiteDataStore` for each space.

### Typography & Layout
- **Standardization:** Added sidebar-specific typography to `AppStyles.swift`, eliminating scattered `.system(size:)` calls.
- **Layout Constants:** Created `AppSpacing.addressBarHorizontalPadding` as a single source of truth for toolbar layout.

---

## 3. Bug Fixes

### Address Bar & Suggestions
- **Fixed:** Suggestions no longer shift main content area; now a proper floating overlay.
- **Fixed:** Click-through to web content prevented with full-screen overlay.
- **Fixed:** Favicon flickering and excessive view updates.
- **Fixed:** Suggestion row selection now covers full width.

### Sidebar & UI
- **Fixed:** Space header positioning and excessive vertical padding (reduced from 40pt to 12pt).
- **Fixed:** Reduced gap between header and space switcher.

### Logic & Build
- **Fixed:** Address bar keyboard navigation event monitoring.
- **Fixed:** Removed `[weak self]` capture from struct-based view code.
- **Fixed:** `SessionPersistence.swift` function signature error.
- **Fixed:** `AppFont.captionBold` syntax error and complex expression timeouts.

---

## 4. Technical Decisions & Implementation

### NSEvent for Keyboard Handling
**Problem:** SwiftUI's `.onKeyPress` is unreliable when a `TextField` has focus.
**Solution:** Used `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` to intercept events at the application level. This allows capturing keys and consuming them (preventing typing) even when the field is focused.

### Suggestion Caching Strategy
**Problem:** Recreating suggestions on every view update caused flickering and performance hits.
**Solution:** Cache suggestions in `@State` and only recalculate when the query changes.
```swift
@State private var cachedSuggestions: [Suggestion] = []
@State private var lastQuery: String = ""

private func updateSuggestions() -> [Suggestion] {
    if currentQuery == lastQuery && !cachedSuggestions.isEmpty {
        return cachedSuggestions
    }
    // Recalculate and update cache
}
```

### Layout Architecture
- **GeometryReader Removal:** Replaced complex `GeometryReader` flows with shared constants in `AppStyles.swift`. This provides predictable layout without runtime overhead.
- **ZStack Composition:** Replaced nested overlays with a `ZStack` and `Color.clear` background to properly handle hit testing and prevent click-throughs.

### Privacy Model
- **Contextual Filtering:** Suggestion generation checks `spaceManager.activeSpace.isPrivate`. Managers still hold the data, but the view layer decides what to expose based on the active space context.

### Performance Considerations
- **Memory:** Suggestion cache limited to 8 items; event monitor is cleaned up `onDisappear`.
- **CPU:** Suggestions only recalculated on query change; no heavy GeometryReader passes.
- **Network:** DuckDuckGo API calls use debouncing and request deduplication.

---

## 5. Future Improvements & Debugging

### Potential Enhancements
1. **Frecency Algorithm:** Sort suggestions by frequency + recency.
2. **Favicon Caching:** Persistent storage for site icons.
3. **Custom Search Engines:** User-selectable search providers.
4. **Keyboard Shortcuts:** ⌘1-9 for direct suggestion selection.

### Debugging Tips
- **Keyboard Events:** If not working, verify `setupKeyboardMonitor()` and `removeKeyboardMonitor()` calls. Ensure `isAddressBarFocused` is true.
- **Suggestions Missing:** Check that the query isn't empty or a `swiftbrowser://` internal URL.
- **Layout:** Verify `AppSpacing` constants and check for conflicting frames in the `ZStack`.

---

## 6. Files Modified
- `Views/AddressBarSuggestionsView.swift`
- `Views/BrowserView.swift`
- `Views/TopToolbar.swift`
- `Views/SidebarView.swift`
- `Extensions/AppStyles.swift`
- `Managers/SessionPersistence.swift`

### Deleted Files (Consolidated)
- `Views/AddressSuggestions.swift` (Merged into `AddressBarSuggestionsView`)
- `Views/ToolbarLayout.swift` (Consolidated into `AppStyles`)

**Full Changelog:** Available in git history from commit `v0.8` to `v0.9`
