# Tab Management Fixes

**Version:** 1.5  
**Date:** March 2026

This document describes the fixes for tab switching and space management issues.

---

## Tab Selection Algorithm

When closing a tab, the browser now follows this priority order to select the next tab:

### 1. Previous Tab (Same Space)
```swift
if let prevId = previousTabId, let prevTab = tabs.first(where: { $0.id == prevId }) {
    nextTab = prevTab
}
```
- Uses the tracked `previousTabId` which stores the last tab the user was on
- Only valid if the previous tab is still in the same space

### 2. Adjacent Tab in Array
```swift
if idx > 0 {
    nextTab = tabs[idx - 1]
} else if idx + 1 < tabs.count {
    nextTab = tabs[idx + 1]
}
```
- Falls back to adjacent tab in the tabs array
- Prefers the tab before the closed one, then tries after

### 3. Same Space Tab (NEW)
```swift
let sameSpaceTab = tabs.first(where: { 
    $0.spaceId == closingSpaceId && $0.id != closingId 
})
```
- **NEW in v1.5**: Filters to find ANY remaining tab in the same space
- Prevents showing a tab from a different space (General, School, Private)

### 4. Any Remaining Tab (Fallback)
```swift
nextTab = tabs.first(where: { $0.id != closingId })
```
- Last resort: pick any other tab regardless of space

---

## Space Switching Logic

### When Closing Last Tab in a Space

If the current space has no remaining tabs after closing:
1. The browser switches to a tab from a different space (if any exist)
2. This is handled by using `switchToTab()` which properly calls `switchSpace()`

### When Switching Spaces

The `switchToTab()` method now properly tracks `previousTabId`:

```swift
public func switchToTab(_ tab: BrowserTab) {
    if tab.spaceId != SpaceManager.shared.activeSpaceId {
        // Track previous tab before switching spaces
        if let current = currentTab, current.id != tab.id {
            previousTabId = current.id
        }
        switchSpace(to: tab.spaceId)
        // ...
    }
    // ...
}
```

This ensures that when you:
1. Open tab A in Space 1
2. Switch to Space 2 and open tab B
3. Close tab B → You return to tab A (not some random older tab)

---

## Key Properties

### TabManager
- `tabs`: All tabs across ALL spaces
- `currentTab`: The currently active tab
- `previousTabId`: UUID of the tab user was on before current

### BrowserTab
- `spaceId`: UUID of the space this tab belongs to
- `lastUsedAt`: Date of last interaction (used for sorting by recency)

### Space
- `id`: Unique identifier
- `isPrivate`: Whether this is a private/incognito space

---

## Common Pitfalls

### 1. Directly Setting `currentTab`
Never set `currentTab` directly when switching to a tab from a different space. Always use `switchToTab()` which handles space switching:

```swift
// WRONG
currentTab = tabFromDifferentSpace

// CORRECT
switchToTab(tabFromDifferentSpace)  // Handles switchSpace() internally
```

### 2. Not Tracking `previousTabId`
Always update `previousTabId` when switching tabs, especially across spaces:

```swift
if let current = currentTab, current.id != tab.id {
    previousTabId = current.id
}
```

### 3. Ignoring Space When Selecting Next Tab
When closing a tab, always prefer tabs from the same space:

```swift
// Filter by space first
let sameSpaceTabs = tabs.filter { $0.spaceId == currentSpaceId }
```

---

## Related Documentation

- [v1.3 - Keyboard Scrolling Fix](./v1.3%20-%20Keyboard%20%26%20Sidebar%20Drag/Keyboard_Scrolling_Fix.md) - Scroll coalescer that led to these issues
- [Keyboard Event Handling](./Keyboard_Event_Handling.md) - Keyboard handler documentation
