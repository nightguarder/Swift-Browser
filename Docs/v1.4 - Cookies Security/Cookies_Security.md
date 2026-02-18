# Cookies Security & Persistence

**Commits:** 
- `db32f2e98025852a51a48757f137654296fa49ea`
- `44db1760b28d9d2937a41ae44f6258a73f0d1f0c`
- `125e6e3e10837423e995af42b36abb5bd8fc8dcf`

## Overview

Implemented secure cookie persistence with encryption. Cookies are now stored encrypted on disk and loaded into memory on app launch, ensuring cookies persist across sessions while maintaining security.

## Architecture

### Cookie Flow

1. **First Visit** → Cookies saved to encrypted file via `saveCookies()` in `didFinish`
2. **App Launch** → `preloadAllCookies()` loads cookies from encrypted files into memory cache
3. **Tab Opens** → `injectCookiesIntoDataStore()` injects cached cookies into WebView
4. **Cookies Page** → Checks cache first, injects if available

### Key Components

#### CookiePersistenceManager.swift
- Handles encryption/decryption of cookie files
- Manages file I/O for cookie storage
- Stores encrypted cookies per space

#### WebViewManager.swift
- Saves cookies on page load (`didFinish` navigation delegate)
- Integrates with cookie persistence layer

#### TabManager.swift
- Injects cookies when creating new WebViews
- Coordinates cookie loading across spaces

#### CookiesView.swift
- Displays cached cookies immediately
- Shows cookies from memory cache

## Security Features

### Encryption
- Cookies encrypted before writing to disk
- Decryption happens only in memory
- Each space has its own encrypted cookie file

### Keychain Integration
- Encryption keys stored in macOS Keychain
- Secure key retrieval on app launch
- Keys protected by user's login keychain

### Block All Cookies (Per-Space)
- Option to block cookies per space
- Independent cookie policies for different workspaces
- Configurable via space settings

## Files Modified

1. **Created:** `Swift Browser/Managers/CookiePersistenceManager.swift`
2. **Modified:** `Swift Browser/WebViewStore/WebViewManager.swift`
3. **Modified:** `Swift Browser/Managers/TabManager.swift`
4. **Modified:** `Swift Browser/Views/CookiesView.swift`

## Testing

1. Visit a website with cookies (e.g., login to a site)
2. Quit the app completely
3. Reopen the app
4. Verify cookies persist - should remain logged in or cookies visible in Cookies page

## Notes

- Some DEBUG print statements remain in `CookiePersistenceManager.swift` (wrapped in `#if DEBUG`)
- Cookies are space-specific - each space has isolated cookie storage
- First launch creates encrypted cookie storage for each space
