# Swift Browser v0.1 - Core Browser

## Release Notes

This initial version establishes the foundational architecture of the browser, prioritizing performance, memory safety, and a native macOS experience.

## Key Features

### 1. User Experience

- **First-Launch Onboarding:** "WelcomeView" prompts users for a name, stored locally in `UserDefaults`.
- **Customizable Profile:** Users can update their display name via the Settings panel.
- **Visuals:** Native macOS aesthetic with a sidebar-based navigation layout.

### 2. Architecture & Safety

- **Memory Management:**
  - Strict `[weak self]` usage in Combine pipelines to prevent retain cycles.
  - Aggressive `WKWebView` teardown using `dismantleNSView` and `about:blank` loading in `deinit`.
- **State Management:**
  - `TabManager` acts as the single source of truth.
  - `WebViewManager` handles `WKWebView` wrapping and navigation state.

### 3. Privacy (Foundational)

- **Do Not Track (DNT):** Runtime toggle to inject DNT headers/JS properties.
- **Content Blocking:** Integrated support for WebKit Content Blockers.
- **HTTPS Upgrade:** Automatic upgrade of known hosts to HTTPS.
- **Zero Telemetry:** No tracking scripts or analytics SDKs.

### 4. Settings Management

- **Local Storage:** All preferences (Name, DNT, Dark Mode) persist via `UserDefaults`.
- **Factory Reset:** Option to wipe all local data and reset the browser state.
- **Dark Mode: ** Toggle for changing the Default `prefers-color-scheme` to _light_ or _dark_

## Technical Details

### File Structure

- `Managers/`: Application logic (Tabs, Bookmarks, Content Blocking).
- `Models/`: Data structures (`BrowserTab`).
- `Views/`: SwiftUI components (`BrowserView`, `SettingsView`, `WelcomeView`).
- `WebViewStore/`: `WebViewManager` engine.

### Constraints

- No external dependencies (CocoaPods/SPM).
- Pure Swift implementation.
- Pay attention to memory leaks
