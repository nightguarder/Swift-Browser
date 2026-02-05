import Foundation
import Combine
import WebKit

public class FindInPageManager: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var isVisible: Bool = false
    @Published public var currentResult: Int = 0
    @Published public var totalResults: Int = 0
    
    public init() {}
    
    public func find(_ text: String, webView: WKWebView?) {
        guard let webView = webView else { return }
        
        if text.isEmpty {
            totalResults = 0
            currentResult = 0
            return
        }
        
        if #available(macOS 11.0, *) {
            let config = WKFindConfiguration()
            config.backwards = false
            config.caseSensitive = false
            config.wraps = true
            
            webView.find(text, configuration: config) { result in
                 if result.matchFound {
                     // We found at least one.
                     // Accurate counting requires JS injection which is complex.
                     // For v0.3 prototype, we'll just indicate "Found".
                     // Ideally we would inject a script to count occurrences.
                 }
            }
        }
    }
    
    public func findNext(webView: WKWebView?) {
        guard let webView = webView else { return }
        if #available(macOS 11.0, *) {
            let config = WKFindConfiguration()
            config.backwards = false
            config.wraps = true
            webView.find(searchText, configuration: config) { _ in }
        }
    }
    
    public func findPrevious(webView: WKWebView?) {
        guard let webView = webView else { return }
        if #available(macOS 11.0, *) {
            let config = WKFindConfiguration()
            config.backwards = true
            config.wraps = true
            webView.find(searchText, configuration: config) { _ in }
        }
    }
    
    public func stopFinding(webView: WKWebView?) {
        guard let webView = webView else { return }
        isVisible = false
        searchText = ""
        if #available(macOS 11.0, *) {
             webView.find("", configuration: WKFindConfiguration()) { _ in }
        }
    }
}
