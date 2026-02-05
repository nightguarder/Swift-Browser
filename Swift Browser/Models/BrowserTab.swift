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
    public let id = UUID()
    
    @Published public var title: String
    @Published public var url: String
    
    /// The dedicated web view manager for this tab.
    /// When nil, this tab is "discarded" and holds only lightweight state.
    @Published public var webView: WebViewManager?

    /// Last time this tab was foregrounded or explicitly used.
    /// Used to discard idle background tabs.
    public var lastUsedAt: Date
    
    private var cancellables = Set<AnyCancellable>()

    public init(title: String, url: String, webView: WebViewManager? = nil) {
        self.title = title
        self.url = url
        self.webView = webView
        self.lastUsedAt = Date()
        
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
    }
}
