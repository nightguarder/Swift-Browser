//
//  ContentBlockerManager.swift
//  Swift Browser
//
//  Manages content blocking rules for WKWebView
//

import Foundation
import WebKit
import Combine

public final class ContentBlockerManager: ObservableObject {
    public static let shared = ContentBlockerManager()
    
    @Published private(set) var isEnabled = true
    @Published private(set) var compiledRuleLists: [WKContentRuleList] = []
    @Published private(set) var lastUpdate: Date?
    @Published private(set) var totalRules = 0
    @Published private(set) var ruleLimitWarning = false
    
    private let filterListManager = FilterListManager.shared
    private let converter = ContentBlockerConverter()
    private var compiledRuleList: WKContentRuleList?
    
    private init() {
        loadCompiledRules()
    }
    
    public func applyBlocklist(to configuration: WKWebViewConfiguration, completion: @escaping () -> Void) {
        guard isEnabled else {
            completion()
            return
        }
        
        let controller = configuration.userContentController
        
        for ruleList in compiledRuleLists {
            controller.add(ruleList)
        }
        
        completion()
    }
    
    public func removeBlocklist(from userContentController: WKUserContentController) {
        for ruleList in compiledRuleLists {
            userContentController.remove(ruleList)
        }
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
