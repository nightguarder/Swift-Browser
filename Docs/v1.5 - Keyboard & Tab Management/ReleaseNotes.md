# Release Notes v1.5

**Version:** 1.5  
**Date:** March 2026

## New Features

### Touchpad Gestures
- **Pinch to Zoom**: Zoom in and out of web pages using touchpad pinch gestures. Pinch out to zoom in, pinch in to zoom out. Zoom level persists during the session.

## Bug Fixes

### Keyboard Navigation
- **Address Bar Arrow Keys**: Fixed arrow key navigation in address bar suggestions after scroll coalescer was introduced
- **Tab Search (Cmd+K)**: Fixed conflict between address bar and tab search overlay keyboard handling
- **TextField Focus**: Prevented TextField from losing focus on arrow key presses
- **Web Page Search Bars**: Fixed error sounds when pressing Enter in search bars on web pages (Google, DuckDuckGo). Removed scroll coalescer to restore proper WKWebView key event handling.

### Tab Management
- **Wrong Space Tab**: Fixed issue where closing a tab in Private space would show a tab from General/School space
- **Recent Tab Tracking**: Fixed issue where closing a tab would not return to the most recently used tab
- **Web Inspector**: Fixed Web Inspector going white/crashing when switching tabs. Now keeps top 2 most recently used tabs alive per space.

### Security & Privacy
- **History Space Isolation**: Fixed history showing from wrong space when viewing history page
- **Cookie Isolation**: Fixed General space using unencrypted cookie storage. All spaces now use unique identifiers.
- **Key Reset Cleanup**: Old encrypted cookie files are now deleted when encryption key is reset

### Content Blocker
- **JSON Optimization**: Removed pretty-printing to reduce rule list size (~30% smaller)
- **EasyList Added**: Added popular EasyList as default filter

## Technical Changes

### Files Modified
1. `Swift Browser/Views/BrowserView.swift`
2. `Swift Browser/Views/TopToolbar.swift`
3. `Swift Browser/Managers/TabManager.swift`
4. `Swift Browser/Views/WebViewContainer.swift` - Removed scroll coalescer
5. `Swift Browser/Views/HistoryView.swift` - Added space parameter
6. `Swift Browser/Managers/SpaceManager.swift` - Cookie isolation fix
7. `Swift Browser/Managers/ContentBlockerConverter.swift` - JSON optimization
8. `Swift Browser/Models/FilterList.swift` - Added EasyList

### Breaking Changes
- **Scroll Coalescer Removed**: The scroll coalescer optimization (d452b956) has been removed to fix web form input issues. Web page scrolling now works through native WKWebView handling.

## Documentation

New documentation added:
- `Keyboard_Event_Handling.md` - How keyboard events are handled across the app
- `Tab_Management_Fixes.md` - Detailed explanation of tab selection algorithm

## Related Issues

- Address bar arrow keys not working (d452b956 scroll coalescer)
- Tab switching showing wrong space
- Tab switching not returning to recent tab
