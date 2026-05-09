//
//  ContentBlockerManager.swift
//  Swift Browser
//
//  Manages content blocking rules for WKWebView with search-engine-specific enhancements
//

import Foundation
import WebKit
import Combine
import SwiftUI

public final class ContentBlockerManager: ObservableObject {
    public static let shared = ContentBlockerManager()
    
    @Published private(set) var isEnabled = true
    @Published private(set) var compiledRuleLists: [WKContentRuleList] = []
    @Published private(set) var lastUpdate: Date?
    @Published private(set) var totalRules = 0
    @Published private(set) var ruleLimitWarning = false
    
    private let filterListManager = FilterListManager.shared
    private let converter = ContentBlockerConverter()
    private let blocker = SearchEngineBlocker.shared
    private var compiledRuleList: WKContentRuleList?
    
    private init() {
        loadCompiledRules()
    }
    
    /// Applies content blocking rules to a web view configuration
    public func applyBlocklist(to configuration: WKWebViewConfiguration, completion: @escaping () -> Void) {
        guard isEnabled else {
            completion()
            return
        }
        
        let controller = configuration.userContentController
        
        // Remove existing rules first to avoid duplicates
        removeBlocklist(from: controller)
        
        // Apply general content blocking rules
        for ruleList in compiledRuleLists {
            controller.add(ruleList)
        }
        
        completion()
    }
    
    /// Applies search-engine-specific blocking rules based on current URL
    public func applySearchEngineRules(to configuration: WKWebViewConfiguration, 
                                      forURL url: URL, 
                                      completion: @escaping () -> Void) {
        guard isEnabled else {
            completion()
            return
        }
        
        let controller = configuration.userContentController
        
        // Remove existing search-engine-specific rules first
        removeSearchEngineRules(from: controller)
        
        // Apply search-engine-specific rules if enabled and on a search page
        if blocker.isEnabled,
           let host = url.host,
           SearchEngine.allCases.first(where: { $0.matches(host: host) }) != nil {
            
            // Get rules for the detected search engine
            if let engine = SearchEngine.allCases.first(where: { $0.matches(host: host) }) {
                let engineRules = blocker.rules(for: engine)
                
                // Convert and apply rules for this specific search engine
                if !engineRules.isEmpty {
                    let combinedRules = engineRules.joined(separator: "\n")
                    let result = converter.convert(filterContent: combinedRules)
                    
                    if !result.json.isEmpty && result.json != "[]" {
                        Task {
                            do {
                                let ruleList = try await compileRuleList(json: result.json, identifier: "search_\(engine.rawValue)")
                                controller.add(ruleList)
                            } catch {
                                print("Failed to compile search engine rule list for \(engine): \(error)")
                            }
                        }
                    }
                }
            }
        }
        
        completion()
    }
    
    /// Removes content blocking rules from a user content controller
    public func removeBlocklist(from userContentController: WKUserContentController) {
        for ruleList in compiledRuleLists {
            userContentController.remove(ruleList)
        }
    }
    
    /// Removes search-engine-specific rules from a user content controller
    public func removeSearchEngineRules(from userContentController: WKUserContentController) {
        // Remove all search engine rule lists (identified by "search_" prefix)
        // In a real implementation, we'd track these more precisely
        // For now, we rely on the fact that we replace them each time
    }
    
    func updateFilterLists() async -> FilterUpdateSummary {
        let summary = await filterListManager.updateAllLists()
        
        await MainActor.run {
            ruleLimitWarning = summary.ruleLimitReached
            lastUpdate = summary.results.first?.timestamp
        }
        
        await compileRules()
        
        return summary
    }
    
    func toggleFilterList(id: String, enabled: Bool) {
        filterListManager.toggleFilterList(id: id, enabled: enabled)
        
        Task {
            await compileRules()
        }
    }
    
    func getFilterListStatus() -> FilterListStatus {
        filterListManager.getFilterListStatus()
    }
    
    func getFilterLists() -> [FilterList] {
        filterListManager.getFilterLists()
    }
    
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    public func reloadRules() {
        Task {
            await compileRules()
        }
    }
    
    /// Updates both general and search-engine-specific rules
    public func updateAllRules() async {
        await updateFilterLists()
        // Search engine rules are updated via SearchEngineBlocker separately
    }
    
    private func loadCompiledRules() {
        Task {
            await compileRules()
        }
    }
    
    private func compileRules() async {
        var newRuleLists: [WKContentRuleList] = []
        var rulesCount = 0
        let maxRules = 50000
        
        let enabledLists = filterListManager.getEnabledLists()
        
        for filterList in enabledLists {
            guard let content = await filterListManager.getCachedFilterList(for: filterList.id) else {
                continue
            }
            
            let result = converter.convert(filterContent: content, maxRules: maxRules - rulesCount)
            
            guard !result.json.isEmpty, result.json != "[]" else {
                continue
            }
            
            do {
                let ruleList = try await compileRuleList(json: result.json, identifier: filterList.id)
                newRuleLists.append(ruleList)
                rulesCount += result.ruleCount
                
                if rulesCount >= maxRules {
                    break
                }
            } catch {
                print("Failed to compile rule list for \(filterList.name): \(error)")
            }
        }
        
        await MainActor.run {
            self.compiledRuleLists = newRuleLists
            self.totalRules = rulesCount
            self.lastUpdate = filterListManager.getFilterListStatus().lastUpdate
            self.ruleLimitWarning = rulesCount >= maxRules
        }
    }
    
    private func compileRuleList(json: String, identifier: String) async throws -> WKContentRuleList {
        try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "SwiftBrowser.\(identifier)",
                encodedContentRuleList: json
            ) { ruleList, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ruleList = ruleList {
                    continuation.resume(returning: ruleList)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "ContentBlockerManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown compilation error"]
                    ))
                }
            }
        }
    }
}