# Swift Browser

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.x-blue.svg)
![Platform](https://img.shields.io/badge/Platform-macOS-brightgreen.svg)

Swift Browser is a privacy-focused macOS browser built with SwiftUI and WebKit. It aims to provide a lightweight, fast, and user-friendly web experience with a strong emphasis on protecting user privacy.

---

![HomePage](/Docs/img/HomePage_v0.1.png)

## Table of Contents

- [Swift Browser](#swift-browser)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Why another Browser?](#why-another-browser)
  - [Features](#features)
  - [Roadmap](#roadmap)
      - [v0.x:](#v0x)
      - [v1.0:](#v10)
      - [v2.0:](#v20)
  - [Getting Started](#getting-started)
  - [Build \& Run](#build--run)
  - [Usage](#usage)
  - [Privacy \& Security](#privacy--security)
  - [Architecture](#architecture)
  - [Contributing \& Issues](#contributing--issues)
  - [License](#license)
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

- Core browser – tab management, navigation, WebKit integration
- Basic features - Home, Local History, Bookmark shortcuts
- Testing: unit and UI tests, CI integration

#### v1.0:

- Developer-oriented features: sandboxed profiles, Developer Tools (F12)
- Design features: Improve toolbar, Sidebar Tab search

#### v2.0:

- Privacy features: content blocker, tracking protection, and anti-fingerprinting basics
- Performance: memory footprint reductions, lazy loading, GPU acceleration optimizations

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

- Build from Xcode: `Product > Build` (CMD + B)
- Run from Xcode: `Product > Run` (CMD + R)
- Run tests: `Product > Test` (CMD + U)
- Ensure you’re targeting macOS and the correct scheme (e.g., App, Tests)

---

## Usage

- Launch the app from `/Applications` or `Xcode`
- Use the integrated WebKit-based browser to navigate
- Manage tabs and windows with native MacOS shortcuts

---

## Privacy & Security

- No `telemetry` or acess to `Camera`, `Microphone` etc.
- Built-in content blocker to limit trackers and third-party tracking
- Design philosophy: minimize data collection and maximize user control

---

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

## Credits

Thanks for the original idea and motivation to build Swift Browser to @idevanshrai and his [repository](https://github.com/idevanshrai/BrimBrowser-MacOS).
