# Keyboard Event Handling & Tab Management Fixes

**Version:** 1.5  
**Date:** March 2026

This document describes the fixes for keyboard event handling and tab management issues introduced in the scroll coalescer implementation.

---

## Issues Fixed

### 1. Address Bar Arrow Key Navigation (Commit: d452b956)

**Problem:** After implementing the scroll coalescer for up/down arrow keys in web pages, users could not navigate through address bar suggestions using arrow keys.

**Root Cause:** The `WebViewHostingView.keyDown()` method was intercepting ALL arrow key events and routing them to the scroll coalescer, preventing the address bar's keyboard monitor from receiving these events.

**Solution:** Added a check in `BrowserView.setupKeyboardMonitor()` to only consume arrow key events when specifically handling address bar suggestions:

```swift
// Only consume events if the address bar is focused AND the window is key
guard self.isAddressBarFocused,
      let window = NSApp.keyWindow,
      window.isKeyWindow else {
    return event
}
```

### 2. TextField Losing Focus on Arrow Keys

**Problem:** Pressing arrow keys in the address bar would cause the TextField to lose focus after the first press, preventing continuous navigation through suggestions.

**Root Cause:** SwiftUI's TextField was consuming arrow key events for its own navigation (cursor movement), which interfered with our suggestion navigation.

**Solution:** Added explicit key press handlers to the TextField to capture and handle arrow keys:

```swift
TextField("Search or URL", text: $tabManager.addressBarText)
    .onKeyPress(.upArrow) { .handled }
    .onKeyPress(.downArrow) { .handled }
```

### 3. Conflict with Tab Search Overlay (Cmd+K)

**Problem:** After fixing the address bar arrow key issue, users could not navigate inside the Cmd+K tab search overlay.

**Root Cause:** Both the address bar keyboard monitor and the tab search overlay were trying to handle arrow key events simultaneously.

**Solution:** Added a guard check in `BrowserView.setupKeyboardMonitor()` to skip processing when the tab search overlay is visible:

```swift
// Skip if tab search overlay is visible (it has its own keyboard handling)
if self.isTabSearchVisible {
    return event
}
```

### 4. Web Page Search Bar Error Sounds

**Problem:** When typing in search bars on web pages (Google, DuckDuckGo) and pressing Enter, users heard macOS error sounds. This prevented form submission in web pages.

**Root Cause:** The scroll coalescer implementation (d452b956) re-introduced `keyDown` and `keyUp` overrides in `WebViewHostingView`. These overrides intercepted ALL key events, including Enter key presses in web form inputs. The events were not properly forwarded to the WKWebView, causing the web page to not receive the input and triggering macOS error sounds.

**Solution (Final):** Rather than trying to fix the event interception, we completely removed the scroll coalescer from `WebViewHostingView`. This restores the v1.3 behavior where key events flow naturally through AppKit's responder chain to the WKWebView. The webview then handles all form inputs correctly.

Removed from `WebViewContainer.swift`:
- `KeyScrollCoalescer` class
- `AssociatedKeys` struct
- All `keyDown`/`keyUp` overrides in `WebViewHostingView`
- The `ObjectiveC` import

This is the correct approach because:
1. WKWebView handles key events natively and correctly
2. Form inputs (search bars, text fields) work properly
3. The responder chain is preserved as intended in v1.3

**Trade-off:** We no longer have the scroll coalescing optimization. If scroll delay is still an issue, it should be addressed with a different approach (e.g., window-level event monitor that only fires when no form input is focused).

### 4. Tab Switching - Wrong Space Tab

**Problem:** When closing the only tab in a Private space, the browser would incorrectly show a tab from a different space (General, School, etc.).

**Root Cause:** In `TabManager.closeTab()`, the fallback logic for selecting the next tab did not filter by space. It would pick ANY remaining tab regardless of which space it belonged to.

**Solution:** Added space-aware tab selection in `closeTab()`:

```swift
// Third try: any remaining tab in the SAME space
if nextTab == nil || nextTab?.spaceId != closingSpaceId {
    let sameSpaceTab = tabs.first(where: { 
        $0.spaceId == closingSpaceId && $0.id != closingId 
    })
    if sameSpaceTab != nil {
        nextTab = sameSpaceTab
    }
}
```

### 5. Tab Switching - Not Returning to Recent Tab

**Problem:** When closing a tab, users were not returned to the most recently used tab. Instead, they would be shown an older tab.

**Root Cause:** The `previousTabId` was only being tracked when switching tabs WITHIN the same space. When switching between spaces, `previousTabId` was not being updated.

**Solution:** Added `previousTabId` tracking in `switchToTab()` when switching between spaces:

```swift
if tab.spaceId != SpaceManager.shared.activeSpaceId {
    // Track previous tab before switching spaces
    if let current = currentTab, current.id != tab.id {
        previousTabId = current.id
    }
    switchSpace(to: tab.spaceId)
    // ...
}
```

Additionally, changed `closeTab()` to use `switchToTab()` instead of directly setting `currentTab` to properly handle space switching when needed.

---

## Files Changed

1. **Swift Browser/Views/BrowserView.swift**
   - Added `isTabSearchVisible` check in keyboard monitor
   - Modified arrow key handling to consume events when address bar is focused

2. **Swift Browser/Views/TopToolbar.swift**
   - Added `.onKeyPress()` modifiers to TextField

3. **Swift Browser/Managers/TabManager.swift**
   - Added space-aware tab selection in `closeTab()`
   - Added `previousTabId` tracking in `switchToTab()` for cross-space switches
   - Changed to use `switchToTab()` for proper space switching

4. **Swift Browser/Views/WebViewContainer.swift**
   - REMOVED: `KeyScrollCoalescer` class
   - REMOVED: `AssociatedKeys` struct
   - REMOVED: All `keyDown`/`keyUp` overrides in `WebViewHostingView`
   - REMOVED: `ObjectiveC` import
   - Restored v1.3 behavior where WKWebView handles all key events naturally

---

## Best Practices for Keyboard Event Handling

To prevent similar issues in the future:

1. **Single Responsibility**: Each keyboard monitor should handle ONE specific UI component
2. **Priority Ordering**: Check for overlays and higher-priority handlers FIRST before consuming events
3. **Guard Early, Return Early**: Use early returns to pass events to other handlers
4. **Test All States**: Test keyboard navigation in all contexts (address bar, tab search, settings, etc.)
5. **Avoid Competing Handlers**: Never have two handlers try to consume the same key in the same context
6. **Document Event Flow**: Always document which component handles which keys

---

## Keyboard Handler Priority Order

When implementing keyboard handling, use this priority:

1. **Tab Search Overlay (Cmd+K)** - Highest priority, when visible
2. **Find in Page (Cmd+F)** - When visible
3. **Address Bar Suggestions** - When focused with suggestions
4. **WebView/Page Scrolling** - Default when nothing else is focused
5. **Sidebar Navigation** - When sidebar is focused

---

## Touchpad Gesture Handling

### Pinch to Zoom

**Implementation:** Touchpad pinch gestures are handled via SwiftUI's `.magnificationGesture()` modifier on the web view container.

**Behavior:**
- **Pinch out** → Zoom in (increase zoom scale)
- **Pinch in** → Zoom out (decrease zoom scale)
- Zoom level persists for the duration of the session
- Zoom range: 25% to 400%

**Code Structure:**
```swift
.gesture(
    MagnificationGesture()
        .onChanged { value in
            // Update zoom scale based on gesture
        }
        .onEnded { value in
            // Finalize zoom level
        }
)
```

---

## Web Inspector State Preservation

**Problem:** When switching between tabs in the same space, the Web Inspector would go white/blank and require re-opening.

**Root Cause:** WebKit automatically closes the inspector when the WebView is removed from the view hierarchy. Previously, only the current tab's WebView was rendered, so switching tabs would remove the old WebView and close the inspector.

**Solution:** Render WebViews for all tabs in the current space, but hide non-active ones with `opacity(0)` and `allowsHitTesting(false)`. This keeps the WebView in the view hierarchy so WebKit doesn't close the inspector.

```swift
// Only render tabs in current space to minimize memory
let currentSpaceId = SpaceManager.shared.activeSpaceId
let spaceTabs = tabManager.tabs.filter { $0.spaceId == currentSpaceId }

ForEach(spaceTabs) { tab in
    WebViewContainer(webView: webViewManager.webView)
        .opacity(tab.id == tabManager.currentTab?.id ? 1 : 0)
        .allowsHitTesting(tab.id == tabManager.currentTab?.id)
}
```

**Memory Optimization:** Only tabs in the active space are rendered. Tabs in other spaces are discarded as before (after 10 second delay).

**Trade-off:** Higher memory usage when multiple tabs are open in the same space. The tradeoff is necessary for Web Inspector functionality.

---

## Related Documentation

- [v1.3 - Keyboard & Sidebar Drag](./v1.3%20-%20Keyboard%20%26%20Sidebar%20Drag/Keyboard_Scrolling_Fix.md) - Original scroll coalescer implementation
