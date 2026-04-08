//
//  BrowserTab.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import Foundation
import Combine
import WebKit

// WebViewManager is defined in WebViewStore/WebViewManager.swift

/// Represents a single browser tab, holding its state and its own WebViewManager
public final class BrowserTab: Identifiable, ObservableObject {
    public let id: UUID
    public let spaceId: UUID
    
    @Published public var title: String
    @Published public var url: String
    @Published public var isPinned: Bool = false
    /// Locked tabs (like Home) cannot be closed or unpinned
    public let isLocked: Bool
    
    /// The dedicated web view manager for this tab.
    /// When nil, this tab is "discarded" and holds only lightweight state.
    @Published public var webView: WebViewManager? {
        didSet {
            // Clear stale subscriptions when webView is released (tab discard)
            if webView == nil && oldValue != nil {
                cancellables.removeAll()
                setupBindings()
            }
        }
    }

    /// Last time this tab was foregrounded or explicitly used.
    /// Used to discard idle background tabs.
    public var lastUsedAt: Date
    
    private var cancellables = Set<AnyCancellable>()

    public init(id: UUID? = nil, title: String, url: String, spaceId: UUID, webView: WebViewManager? = nil, lastUsedAt: Date? = nil, isPinned: Bool = false, isLocked: Bool = false) {
        self.id = id ?? UUID()
        self.title = title
        self.url = url
        self.spaceId = spaceId
        self.webView = webView
        self.lastUsedAt = lastUsedAt ?? Date()
        self.isPinned = isPinned
        self.isLocked = isLocked
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Sync pageTitle from WebViewManager to BrowserTab title
        $webView
            .map { manager -> AnyPublisher<String?, Never> in
                guard let manager else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return manager.$pageTitle.eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newTitle: String?) in
                if let newTitle, !newTitle.isEmpty {
                    self?.title = newTitle
                }
            }
            .store(in: &cancellables)

        // Sync currentURL from WebViewManager to BrowserTab url
        $webView
            .map { manager -> AnyPublisher<URL?, Never> in
                guard let manager else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return manager.$currentURL.eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newURL: URL?) in
                if let absoluteString = newURL?.absoluteString {
                    self?.url = absoluteString
                }
            }
            .store(in: &cancellables)
            
        // Forward general WebViewManager changes (e.g. DuckPlayer state)
        $webView
            .compactMap { $0 }
            .flatMap { $0.objectWillChange }
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
