//
//  DarkModeManager.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import Foundation
import WebKit

public final class DarkModeManager {
    public static let shared = DarkModeManager()
    
    private let darkModeCSS = """
    :root {
        color-scheme: dark;
    }
    """
    
    public func applyDarkMode(to configuration: WKWebViewConfiguration) {
        let script = WKUserScript(
            source: "document.documentElement.style.cssText += '\(darkModeCSS)'",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(script)
    }
    
    public func removeDarkMode(from configuration: WKWebViewConfiguration) {
        let source = """
        var style = document.getElementById('swift-browser-dark-mode');
        if (style) { style.remove(); }
        """
        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)
    }
}
