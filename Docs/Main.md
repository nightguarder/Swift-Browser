# Swift Browser Documentation

## Overview

Swift Browser is a lightweight, privacy-focused web browser for macOS built using native technologies (SwiftUI, WebKit, Combine).

## Documentation Structure

The documentation is versioned to track the evolution of the browser's features and architecture.

### Versions

- [**v0.1 - Core Browser**](v0.1/Core.md): Initial release focusing on essential browsing capabilities, memory safety, and basic privacy features.
- [**v0.2 - UX & System Appearance**](v0.2/ReleaseNotes.md): Find in page, History page, dark mode follows system (no CSS injection).
- [**v0.3 - Developer Tools & Shortcuts**](v0.3/ReleaseNotes.md): Web Inspector enablement and shortcuts page.
- [**v0.4 - Unified Styles**](v0.4/ReleaseNotes.md): Centralized fonts and icon sizes via `AppStyles.swift`.
- [**v0.5 - Stability & Memory**](v0.5/ReleaseNotes.md): Bug fixes, memory leak hardening, and simple tab discard.
- [**v0.6 - Tab Duplication & Favicon**](v0.6/ReleaseNotes.md): Duplicate current tab via ⌘D and double‑click in sidebar; Added Favicons to Tab previews.

## Philosophy

- **Lightweight:** Simple clean and robust code. Low RAM & CPU usage.
- **Native:** Built with standard Apple frameworks. No external dependencies.
- **Private:** Zero telemetry, aggressive content blocking, privacy in mind.
