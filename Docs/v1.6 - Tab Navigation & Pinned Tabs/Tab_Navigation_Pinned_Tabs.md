# Tab Navigation & Pinned Tabs

**Version:** 1.6  
**Date:** March 2026  
**Commit:** 0efe2ed32e3e8be037279a500511f371558ff510

This document describes the new tab navigation features and pinned tabs functionality introduced in version 1.6.

---

## New Keyboard Shortcuts

### Tab Navigation (within same space)
- **⌘+DownArrow** - Switch to next tab (within current space)
- **⌘+UpArrow** - Switch to previous tab (within current space)

### Space Navigation
- **⌘+RightArrow** - Switch to next space
- **⌘+LeftArrow** - Switch to previous space

### Tab Management
- **⌘+P** - Pin/unpin current tab

---

## Pinned Tabs

### Overview
Pinned tabs stay at the top of the tab list and cannot be accidentally closed. They are perfect for:
- Home page (default in each space)
- Frequently visited sites
- Important pages you always need access to

### Features
1. **Always on top** - Pinned tabs appear first in the sidebar
2. **Cannot be closed** - Close button is disabled for pinned tabs
3. **Visual indicator** - Pin icon (📌) shown next to pinned tab titles
4. **Session persistence** - Pinned state is saved and restored across app launches

### Default Behavior
- Each new space automatically gets a pinned "Home" tab
- The Home tab serves as the landing page when switching to a space with no tabs
- Users can pin/unpin any tab using ⌘+P

---

## Sidebar Improvements

### Tab Count Header
- Shows "Opened Tabs (count)" when sidebar is expanded
- Includes keyboard shortcut hint (⌘↑↓)
- Only visible when hovering over the sidebar

### Keyboard Shortcut Badges
- **⌘←→** - In Username + Space header (space navigation)
- **⌘↑↓** - In tab list header (tab navigation)
- **⌘K** - In search tabs field
- **⌘T** - In New Tab button

---

## Implementation Details

### BrowserTab Model
Added `isPinned` property to persist pin state:
```swift
@Published public var isPinned: Bool = false
```

### TabManager Changes
- `addTab(url:isPinned:)` - Added optional `isPinned` parameter
- `togglePinCurrentTab()` - New function to pin/unpin current tab
- `nextTab()` / `previousTab()` - Now only navigate within current space
- `closeTab()` - Prevents closing pinned tabs
- `switchSpace()` - Creates pinned Home tab for new spaces

### Session Persistence
- `PersistedTab` struct now includes `isPinned` field
- Pin state is saved/restored with session

---

## Bug Fixes

1. **Tab/Space navigation separation** - Tab navigation (⌘↑↓) now stays within the current space only
2. **Cursor stability** - Removed `.help()` modifiers that caused cursor flickering
3. **Sidebar hover** - Fixed sidebar not expanding on hover

---

## Related Documentation

- [v1.5 - Keyboard & Tab Management](./v1.5%20-%20Keyboard%20%26%20Tab%20Management/Keyboard_Event_Handling.md) - Previous keyboard handling fixes
