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
- [**v0.7 - Bookmarks page + History page**](v0.7/ReleaseNotes.md): History page + Bookmarks page
- [**v0.8** - Adress Suggestion bar bugs\*\*](v0.8/ReleaseNotes.md): Polish new features, improve code, shortcuts control, Adress bar fix
- [**v1.0 - Major Feature Release**](v1.0/ReleaseNotes.md): Downloads support, functioning Web Inspector, new icon, enhanced content blocker, security audit, and code cleanup.
- [**v1.1 - No-Signature Build & Cloudflare Fix**](v1.1/ReleaseNotes.md): Cloudflare "Are you a human?" loop fix, no-signature distribution, RAM comparison with Safari.

## Philosophy

- **Lightweight:** Simple clean and robust code. Low RAM & CPU usage.
- **Native:** Built with standard Apple frameworks. No external dependencies.
- **Private:** Zero telemetry, aggressive content blocking, privacy in mind.
