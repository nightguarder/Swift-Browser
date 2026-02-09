# Swift Browser v0.7

## Summary

This release introduces core organization features with a dedicated Bookmarks system and a significant overhaul of History management. We've also added native Favicon support to improve visual identification of sites across the browser and the Home Page.

## New Features

- **Bookmarks System:** A dedicated `BookmarksView` and `BookmarkManager` for saving and organizing favorite pages.
- **History Overhaul:** Enhanced `HistoryView` with full support for viewing and deleting browsing history entries.
- **Favicon Support:** Integrated `FaviconView` to fetch and display site icons in the Home Page, history lists, and bookmarks.

## Implementation Details

- **Tab Management:** Improved tab switching logic in `BrowserView` and `WebViewContainer` to handle state transitions more reliably.
- **Persistence:** Bookmarks and History use specialized managers to handle data state and persistence.

## Notes

- Favicon fetching is optimized to minimize network overhead.
- History deletion is permanent and affects the unified history store.

## Commits
- `0526a098ba9f18d41764120f2426ebd48590c098`
- `d37c081a67ae5b9949c441e09e1a216e964812e1`
- `aa38d48b18559984f376e95aa6badc62823d98e9`
