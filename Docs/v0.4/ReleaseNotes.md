# Swift Browser v0.4
## Summary

We standardized typography and icon sizing across the app with a single source of truth. This improves visual consistency, reduces one-off style usage, and simplifies future design changes.

## Centralized Styles

- File: `Swift Browser/Extensions/AppStyles.swift`
- Typography tokens (`AppFont`):
  - `icon`: 18 / medium
  - `title`: 15 / medium
  - `subtitle`: 13 / regular
  - `caption`: 13 / regular
  - `body`: 14 / regular
  - `headline`: 14 / semibold
  - `hero`: 42 / bold (rounded)
  - `heroIcon`: 50 / ultraLight
  - `searchField`: 15 / regular
  - `smallIcon`: 13 / medium
  - `mediumIcon`: 15 / medium
  - `keyboardShortcut`: 11 / medium
- Spacing & dimensions (`AppSpacing`):
  - `iconSize`: 24
  - `smallIconSize`: 20
  - `toolbarHeight`: 52
  - `sidebarWidthCollapsed`: 50
  - `sidebarWidthExpanded`: 200
  - `menuItemPadding`: 10
  - `cornerRadius`: 8

## Usage Guidelines

- Always use `AppFont.*` for text and `AppSpacing.*` for icon frames and layout dimensions.
- Avoid ad‑hoc `.font(.system(...))` and hardcoded numbers in views.
- Toolbars should use `AppFont.icon` for icon glyphs and `AppSpacing.iconSize` for frames.
- List/menu titles should use `AppFont.title`; secondary text should use `AppFont.subtitle` or `AppFont.caption`.

## Examples

```swift
// Title in a settings row
Text("Settings").font(AppFont.title)

// Icon sized consistently
Image(systemName: "gear")
    .font(AppFont.icon)
    .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)

// Secondary copy
Text("Choose your preferred appearance")
    .font(AppFont.subtitle)
    .foregroundColor(.secondary)
```

## Migration Checklist

- Replace inline font and size literals in:
  - `TopToolbar`, `SidebarView`, `ControlCenterMenuView`, `SettingsView`, `HistoryView`, `FindBarView`, `TabSearchOverlay`, `HomePage`, `WelcomeView`, `ShortcutsView`.
- Ensure icons use `AppFont.icon` and frames use `AppSpacing.iconSize` (or `smallIconSize` where appropriate).
- Align titles/subtitles to `AppFont.title` / `AppFont.subtitle`; body text to `AppFont.body`.

## Notes

- These values are the baseline for macOS; future scaling can be introduced centrally in `AppStyles.swift` without per-view changes.
