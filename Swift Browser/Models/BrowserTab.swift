//
//  BrowserTab.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import Foundation
import Combine

/// Represents a single browser tab, holding its state and its own WebViewManager
public final class BrowserTab: Identifiable, ObservableObject {
    public let id = UUID()
    
    @Published public var title: String
    @Published public var url: String
    
    /// The dedicated web view manager for this tab
    public var webView: WebViewManager
    
    private var cancellables = Set<AnyCancellable>()

    public init(title: String, url: String, webView: WebViewManager) {
        self.title = title
        self.url = url
        self.webView = webView
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Sync pageTitle from WebViewManager to BrowserTab title
        webView.$pageTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newTitle: String?) in
                if let newTitle = newTitle, !newTitle.isEmpty {
                    self?.title = newTitle
                }
            }
            .store(in: &cancellables)
            
        // Sync currentURL from WebViewManager to BrowserTab url
        webView.$currentURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (newURL: URL?) in
                if let absoluteString = newURL?.absoluteString {
                    self?.url = absoluteString
                }
            }
            .store(in: &cancellables)
    }
}
