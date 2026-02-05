# Swift Browser v0.6

- Duplicate current tab via `⌘D` and right‑click (context menu) in sidebar
- Bug fixes: smoother sidebar hover animations; snappier tab selection (removed double‑click delay)
- Browser feels more responsive overall due to small interaction/pipeline tweaks
- Favicons in sidebar for sites (falls back to sensible system icons)
- Sidebar wiring uses direct closures (no NotificationCenter) for duplication
- Developer tools: use right‑click “Inspect Element” when Developer Mode is enabled (no double‑tap gesture)

Notes

- Duplication inserts the new tab next to the source, loads the same URL when present, then switches to it
- Favicons use `AsyncImage` to load `favicon.ico` when available; internal pages show themed system icons
- Follows memory safety rules; internal and discarded tabs don’t keep a `WKWebView` alive
