# Swift Browser v1.1

## No-Signature Build

Due to the lack of an active Apple Developer account, the v1.1 release is distributed **without code signing**. This means:

- Gatekeeper may show a warning on first launch
- Right-click the app and select "Open" to bypass
- Full functionality remains unchanged

## Cloudflare Fix

Resolved the "Are you a human?" loop issue that occurred when visiting Cloudflare-protected sites. Swift Browser now properly handles Cloudflare's browser integrity checks, providing a smoother browsing experience on sites using Cloudflare protection.

## Memory Comparison

Swift Browser continues to demonstrate its lightweight nature with reduced memory footprint compared to Safari.

| Browser | Tabs | RAM Usage |
|---------|------|-----------|
| Safari | 4 | 1,170 MB |
| Swift Browser | 5 | 716 MB |

**Swift Browser uses ~1.6x less RAM than Safari**

## What's Fixed

- Cloudflare browser integrity check handling
- Removed unnecessary Apple code signing requirements
- Documentation updated with performance comparisons

---

[← Back to v1.0](v1.0/ReleaseNotes.md)
