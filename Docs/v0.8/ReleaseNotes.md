# Swift Browser v0.8

## Summary

This release focuses on navigation intelligence and centralized event handling. We have finalized a new Suggestion Bar system that provides real-time address search results based on browsing history. Additionally, keyboard shortcuts have been unified under a new coordinator architecture.

## New Features

- **Address Bar Suggestions:** A finalized suggestion list that appears as you type in the address bar, leveraging history and common patterns for faster navigation.
- **Unified Shortcuts:** Comprehensive keyboard shortcut support across all major views (Sidebar, History, Settings, etc.).
- **Shortcut Overlays:** Added shortcut hints to `ShortcutsView` and `SidebarView` for better discoverability.

## Implementation Details

- **KeyboardCoordinator:** Introduced a centralized coordinator to manage keyboard events and state transitions, reducing duplication in individual views.
- **Per-View Architecture:** Shifted certain logic to a per-view approach to provide better context for future development and improve modularity.
- **Shared Components:** Standardized components in `SharedComponents.swift` for consistent UI elements like shortcut labels.

## Notes

- Address bar suggestions are filtered and ranked based on relevance to the user's history.
- The `KeyboardCoordinator` ensures that shortcuts don't conflict between different active overlays.

## Commits
- `9d05a7c074c26988b1c77f900ce0e790344990eb`
- `6cd87393d47addc264a11a12c8a2d67361065a5e`
