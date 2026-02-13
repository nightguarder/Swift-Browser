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
        case .enabled: return "Always Open Duck Player"
        case .alwaysAsk: return "Ask to Open"
        case .disabled: return "Disabled"
        }
    }
}

public class DuckPlayerSettings: ObservableObject {
    public static let shared = DuckPlayerSettings()
    
    private let defaults = UserDefaults.standard
    
    private init() {
        let savedMode = defaults.string(forKey: "duckPlayerMode") ?? DuckPlayerMode.alwaysAsk.rawValue
        self.mode = DuckPlayerMode(rawValue: savedMode) ?? .alwaysAsk
        self.alwaysAskOverlayHidden = defaults.bool(forKey: "duckPlayerAskOverlayHidden")
    }
    
    @Published public var mode: DuckPlayerMode {
        didSet {
            defaults.set(mode.rawValue, forKey: "duckPlayerMode")
        }
    }
    
    @Published public var alwaysAskOverlayHidden: Bool {
        didSet {
            defaults.set(alwaysAskOverlayHidden, forKey: "duckPlayerAskOverlayHidden")
        }
    }
    
    public init(mode: DuckPlayerMode = .alwaysAsk, alwaysAskOverlayHidden: Bool = false) {
        let savedMode = defaults.string(forKey: "duckPlayerMode") ?? DuckPlayerMode.alwaysAsk.rawValue
        self.mode = DuckPlayerMode(rawValue: savedMode) ?? .alwaysAsk
        self.alwaysAskOverlayHidden = defaults.bool(forKey: "duckPlayerAskOverlayHidden")
    }
    
    // Check if the URL is a valid video for Duck Player
    public func shouldOfferPlayer(for url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains("youtube.com") && url.path.hasPrefix("/watch")
    }
}
