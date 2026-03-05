//
//  SharedComponents.swift
//  Swift Browser
//

import SwiftUI

/// A small badge displaying a keyboard shortcut.
/// This view is intended as a lightweight, reusable hint in toolbars, menus, or help overlays.
public struct KeyboardShortcutHint: View {
    let keys: String
    let tooltip: String?
    
    public init(_ keys: String, tooltip: String? = nil) {
        self.keys = keys
        self.tooltip = tooltip
    }

    public var body: some View {
        if let tooltip = tooltip {
            Text(keys)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(4)
                .help(tooltip)
        } else {
            Text(keys)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(4)
        }
    }
}

// Lightweight previews for quick visual checks in Xcode
#if DEBUG
struct SharedComponents_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading, spacing: 8) {
      KeyboardShortcutHint("⌘K")
      KeyboardShortcutHint("Ctrl+P")
      HighlightedText(text: "Swift Browser", highlight: "Swift")
      HighlightedText(text: "Swift Browser", highlight: "Browser")
      HighlightedText(text: "No highlight here", highlight: "")
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif

/// Text renderer that highlights a given substring within the main text.
/// - text: Full text to render
/// - highlight: Substring to emphasize by applying a background highlight
public struct HighlightedText: View {
    public let text: String
    public let highlight: String
    // Simple, fixed highlight color (no customization to keep the API small)
    private let highlightColor: Color = .yellow
    
    public init(text: String, highlight: String) {
        self.text = text
        self.highlight = highlight
    }
    
    public var body: some View {
        if highlight.isEmpty {
            Text(text)
        } else {
            Text(highlightedAttributedString)
        }
    }
    
    private var highlightedAttributedString: AttributedString {
        var result = AttributedString(text)
        if !highlight.isEmpty, let range = result.range(of: highlight, options: .caseInsensitive) {
            result[range].backgroundColor = highlightColor.opacity(0.3)
        }
        return result
    }
}
