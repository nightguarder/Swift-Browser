//
//  DarkModeManager.swift
//  Swift Browser
//
//  Created by Assistant on 02/03/26.
//

import Foundation
import WebKit
import SwiftUI

public final class DarkModeManager {
    public static let shared = DarkModeManager()
    
    @AppStorage("darkModePreference") public var preference: DarkModePreference = .system
    
    public enum DarkModePreference: String, CaseIterable {
        case light
        case dark
        case system
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "Follow System"
            }
        }
    }
    
    /// Returns whether dark mode should be active based on preference and system setting
    public var isDarkModeEnabled: Bool {
        switch preference {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            #if os(macOS)
            return NSApp.effectiveAppearance.name == .darkAqua
            #else
            return UITraitCollection.current.userInterfaceStyle == .dark
            #endif
        }
    }
    
    public func applyDarkMode(to webView: WKWebView) {
        // v0.2+: No CSS/JS injection. UI follows system; pages render as authored.
        // Intentionally no-op.
    }
    
    public func removeDarkMode(from webView: WKWebView) {
        // v0.2+: No CSS/JS injection. Intentionally no-op.
    }
}
