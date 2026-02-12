# Swift Browser

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.x-blue.svg)
![Platform](https://img.shields.io/badge/Platform-macOS-brightgreen.svg)

Swift Browser is a privacy-focused macOS browser built with SwiftUI and WebKit. It aims to provide a lightweight, fast, and user-friendly web experience with a strong emphasis on protecting user privacy.

## Docs

The documentation for this project is maintained in the Docs/ directory. It includes versioned release notes and a user-facing roadmap.

---

| ![Browser](/Docs/img/SwiftBrowser_v1.0.png) | ![Welcome](/Docs/img/SplashScreen.png) |
| :-----------------------------------------: | :------------------------------------: |
|               Main Interface                |             Welcome Screen             |

## Table of Contents

- [Swift Browser](#swift-browser)
  - [Docs](#docs)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Why another Browser?](#why-another-browser)
  - [Features](#features)
  - [Roadmap](#roadmap)
    - [v0.x:](#v0x)
    - [v1.0 - Core Browser:](#v10---core-browser)
    - [v2.0 - Improvements:](#v20---improvements)
    - [v.3.0 - Mobile](#v30---mobile)
  - [Getting Started](#getting-started)
  - [Build \& Run](#build--run)
    - [From Xcode](#from-xcode)
    - [From Command Line (Without Xcode Running)](#from-command-line-without-xcode-running)
  - [Releases](#releases)
  - [Privacy \& Security](#privacy--security)
  - [Ram usage \& Comparison](#ram-usage--comparison)
  - [Architecture](#architecture)
  - [Contributing \& Issues](#contributing--issues)
  - [License](#license)
  - [DevTools](#devtools)
  - [Credits](#credits)

---

## Overview

Swift Browser is a privacy-focused macOS browser designed to complement a modern Safari experience. Built with SwiftUI and WebKit, it focuses on lean performance, clear UX, and modular architecture to enable future privacy-centric features.

## Why another Browser?

The current market is dominated by Chromium. I really love Safari and WebKit, but since Safari 26 (with macOS Tahoe and Liquid Glass design) the browser became not that great to use and completely unusable on mobile.

The goal of this project is to keep it as lightweight as possible and prefer **speed and security** over multiple features. The browser should obstruct the user as little as possible.

> **Note:**
> Don’t login to your sensitive accounts (banks, Gmail, etc.) just yet.

---

## Features

- Private browsing with default search engine **[DuckDuckGo](https://github.com/duckduckgo)**
- Built-in content blocker and tracking protection
- macOS-native, accessible UI with SwiftUI
- Lightweight footprint and fast loading times
- Extensible architecture for Extensions and privacy features

---

## Roadmap

#### v0.x:

- [x] v0.1 - Core browser: tab management, tab navigation, settings page
- Basic features - Home, Local History, Bookmark shortcuts
- Testing: unit and UI tests, CI integration
- [x] v0.2 - UX improvements and initial enhancements to history and UI
- [x] v0.3 - Developer Tools & Shortcuts
- [x] v0.4 - Unified Styles
- [x] v0.5 - Stability & Memory
- [x] v0.6 - Tab Duplication & Favicon
- [x] v0.7 - Bookmarks page + Favicon support on the HomePage
- [x] v0.8 - Address bar shortcut suggestions; address bar suggestion list based on history

#### v1.0 - Core Browser:

- [x] Downloads support - Full download management with progress tracking, file organization, and popover UI
- [x] Functioning Web Inspector - Safari developer tools integration with context menu and keyboard shortcuts (F12, ⌘⌥I)
- [x] New Application Icon - Complete icon set for all macOS resolutions
- [x] Enhanced Content Blocker - Blocking rules for ads, trackers, analytics, and fingerprinting with essential services whitelist
- [x] Security Audit - App Transport Security enforcement, sandbox optimization, dark mode injection removal
- [x] Code Cleanup - WebView container improvements, SwiftUI modernization, UI unification

#### v2.0 - Improvements:

- [ ] Extensions Support - Browser extensions framework for privacy extensions
- [ ] Advanced Privacy - Enhanced anti-fingerprinting, smarter tracking protection
- [ ] Performance - Further memory footprint reductions, GPU acceleration optimizations

#### v.3.0 - Mobile

- [] Mobile Support? - Need an Apple Developer License...

---

## Getting Started

Prerequisites

- macOS 14+ (Ventura or newer)
- Xcode 15.x or later
- Swift 5.x

Clone the repository

- `git clone https://github.com/your-org/Swift-Browser.git`
- `cd Swift-Browser`

Open the project

- Open `Swift Browser.xcodeproj` or `Swift_BrowserApp.swift` in Xcode

Run

- In Xcode, select the target (macOS app) and run the scheme.
- To run tests: open the test navigator and run `Swift BrowserTests` and `Swift_BrowserUITests`.

---

## Build & Run

### From Xcode

- Build from Xcode: `Product > Build` (CMD + B)
- Run from Xcode: `Product > Run` (CMD + R)
- Run tests: `Product > Test` (CMD + U)
- Ensure you're targeting macOS and the correct scheme (e.g., App, Tests)

### From Command Line (Without Xcode Running)

You can build and run the project from the terminal without opening Xcode:

```bash
# 0. (Optional) Ensure Command Line Tools are set
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 1. Build the app
xcodebuild -project "Swift Browser.xcodeproj" -scheme "Swift Browser" -configuration Debug build

# 2. Run the app
open ~/Library/Developer/Xcode/DerivedData/Swift_Browser-*/Build/Products/Debug/Swift\ Browser.app
```

**Note:** The exact DerivedData path may vary slightly based on the hash suffix. If the wildcard doesn't work, check `~/Library/Developer/Xcode/DerivedData/` for the exact folder name.

---

## Releases

_Note: The application is not signed! I don't have an Apple developer account.._

1. Download latest version from Releases [page](https://github.com/nightguarder/Swift-Browser/releases)
2. Extract the `.zip` archive.
3. Move the `.app` into your `/Applications` folder
4. Launch the `Swift_Browser app`

---

## Privacy & Security

- No `telemetry` or acess to `Camera`, `Microphone` etc.
- Built-in content blocker to limit trackers and third-party tracking
- Design philosophy: minimize data collection and maximize user control

---

## Ram usage & Comparison

| ![Safari RAM Usage](/Docs/img/Safari_app_4tabs.png) | ![Swift Browser RAM Usage](/Docs/img/Swift_Browser_5tabs.png) |
| :-------------------------------------------------: | :-----------------------------------------------------------: |
|           Safari: 4 tabs + app = 1 170 MB           |             Swift_Browser: 5 tabs + app = 716 MB              |

Comparison between native `Safari` latest (18.0) and `Swift_Browser`. Not accurate but the same tabs were open. The result is **significant** - Swift uses **~1.6x less RAM** than Safari (1,170 MB → 716 MB)

## Architecture

- `Views/` - SwiftUI views for UI components
- `Managers/`:
  - `ContentBlockerManager.swift` - content-blocking rules
  - `TabManager.swift` - tab handling and navigation
  - `WebViewManager.swift` - WebKit integration
- `Models/` - data models for bookmarks, tabs, etc.
- `WebViewStore/` - persistence and state management
- Entry points:
  - `Swift_BrowserApp.swift`
  - `BrowserView.swift`
  - `SplashScreen.swift
- Use the integrated WebKit-based browser to navigate
- Manage tabs and windows with native MacOS shortcuts

---

## Contributing & Issues

**Contribution**
We welcome contributions from the community!

- Fork the repository
  - Create a feature/bugfix branch: `git checkout -b feature/your-feature`
  - Make your changes with clear, small commits
  - Run tests locally: `swift test` (if applicable) or run through Xcode
- Open a pull request with a concise description of the change and reason

**Issues:**
Use a clear, descriptive title

- Provide a detailed description including:
  - Steps to reproduce
  - Expected vs. actual behavior
  - Environment (macOS version, Xcode version, Swift version)
  - Logs or screenshots if relevant

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.

---

## DevTools

This build enables WebKit Web Inspector in WKWebView for development. To open DevTools, right-click on a page element and choose Inspect Element, or press Command-Option-I. A minimal DevTools button is available in the app's toolbar as a reminder.

---

## Credits

Thanks for the original idea and motivation to build Swift Browser to @idevanshrai and his [repository](https://github.com/idevanshrai/BrimBrowser-MacOS).
