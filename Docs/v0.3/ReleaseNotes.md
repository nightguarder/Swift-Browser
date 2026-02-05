# Swift Browser v0.3

## Summary

Developer tooling and productivity enhancements.

## New Features

- Developer Tools: Enable WebKit developer extras and remote inspection. Right‑click any page to use “Inspect Element” or attach via Safari’s Develop menu.
- Shortcuts Page: Keyboard shortcut overlays for faster navigation and tab management.

## Implementation Details

- Developer Extras: On macOS, `WKPreferences.developerExtrasEnabled` is toggled with the Developer Mode setting; `WKWebView.isInspectable` enables remote inspection.
- Control Center: The Web Inspector item includes inline guidance under the button.

## Notes

- Web Inspector cannot be programmatically opened; use context menu or Safari Develop menu.
- Memory and lifecycle rules remain enforced per project guidelines.
