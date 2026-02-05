# Swift Browser v0.5

Bug fixes - hard to find but worth it

- Hardened teardown paths for `WKWebView` and message handlers
- Implemented idle tab discard (15 min) with media/capture safety checks
- Minor bug fixes in navigation state observation and address bar updates

Notes

- `WebViewManager.teardown()` stops loading, clears delegates, removes scripts/rules, loads `about:blank`, and removes from superview
- Discarding skips tabs that are playing media or capturing camera/microphone; internal tabs and empty tabs are kept lightweight
