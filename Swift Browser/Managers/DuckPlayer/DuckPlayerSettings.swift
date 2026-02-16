//
//  DuckPlayerSettings.swift
//  Swift Browser
//
//  Adapted from DuckDuckGo/DuckPlayer
//

import Foundation
import Combine

public enum DuckPlayerMode: String, CaseIterable, Codable, Identifiable {
    case enabled = "enabled"
    case alwaysAsk = "alwaysAsk"
    case disabled = "disabled"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .enabled: return "Always Open in Duck Player"
        case .alwaysAsk: return "Ask Every Time"
        case .disabled: return "Never Use Duck Player"
        }
    }

    public var subtitle: String {
        switch self {
        case .enabled: return "YouTube videos open in Duck Player automatically"
        case .alwaysAsk: return "Show a button on YouTube to open in Duck Player"
        case .disabled: return "YouTube videos load normally"
        }
    }
}

public final class DuckPlayerSettings: ObservableObject {
    public static let shared = DuckPlayerSettings()

    /// Posted when the mode changes so managers can react (e.g., re-inject scripts).
    public static let modeDidChangeNotification = Notification.Name("DuckPlayerModeDidChange")

    private let defaults = UserDefaults.standard

    private static let modeKey = "duckPlayerMode"
    private static let overlayHiddenKey = "duckPlayerAskOverlayHidden"

    private init() {
        let savedMode = defaults.string(forKey: Self.modeKey) ?? DuckPlayerMode.alwaysAsk.rawValue
        self.mode = DuckPlayerMode(rawValue: savedMode) ?? .alwaysAsk
        self.alwaysAskOverlayHidden = defaults.bool(forKey: Self.overlayHiddenKey)
    }

    @Published public var mode: DuckPlayerMode {
        didSet {
            defaults.set(mode.rawValue, forKey: Self.modeKey)
            NotificationCenter.default.post(name: Self.modeDidChangeNotification, object: nil)
        }
    }

    /// When true, the "Open in Duck Player" button is hidden even in Ask mode
    /// (the user checked "Don't show this again").
    @Published public var alwaysAskOverlayHidden: Bool {
        didSet {
            defaults.set(alwaysAskOverlayHidden, forKey: Self.overlayHiddenKey)
        }
    }

    /// Whether the JS overlay button should be shown on YouTube pages.
    public var shouldShowOverlay: Bool {
        switch mode {
        case .enabled:
            // In "Always Open" mode the user is redirected before the page loads,
            // so the overlay is unnecessary. But if they somehow land on the page
            // (e.g., SPA navigation), show it as a fallback.
            return true
        case .alwaysAsk:
            return !alwaysAskOverlayHidden
        case .disabled:
            return false
        }
    }

    /// Resets DuckPlayer settings to defaults.
    public func reset() {
        mode = .alwaysAsk
        alwaysAskOverlayHidden = false
    }
}
