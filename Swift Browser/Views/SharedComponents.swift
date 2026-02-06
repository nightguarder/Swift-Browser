//
//  SharedComponents.swift
//  Swift Browser
//

import SwiftUI

public struct KeyboardShortcutHint: View {
    let keys: String
    var color: Color = .secondary

    public init(_ keys: String, color: Color = .secondary) {
        self.keys = keys
        self.color = color
    }

    public var body: some View {
        Text(keys)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
}

public struct HighlightedText: View {
    public let text: String
    public let highlight: String
    
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
        if let range = result.range(of: highlight, options: .caseInsensitive) {
            result[range].backgroundColor = .yellow.opacity(0.3)
        }
        return result
    }
}
