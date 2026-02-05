# Swift Browser v0.2

## Summary

This release focuses on user experience improvements and system-respecting appearance.

## New Features

- Find in Page: Quickly search for keywords within the current page.
- History Page: View and revisit previously visited pages.
- Dark Mode Follows System: The app UI now follows macOS appearance when configured to “Follow System”. No CSS or script injection is used to alter website colors.

## Technical Notes

- Dark mode: UI respects `darkModePreference`. When `.system`, the app does not override color scheme. Web content is rendered as authored; no color-scheme injection.
- Memory Safety: Existing WebKit teardown remains intact; no changes that impact lifecycle.
