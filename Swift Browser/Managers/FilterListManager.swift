//
//  FilterListManager.swift
//  Swift Browser
//
//  Manages downloading and caching of filter lists from remote sources
//

import Foundation
import Combine

final class FilterListManager: ObservableObject {
    static let shared = FilterListManager()
    
    @Published private(set) var state: FilterListState
    @Published private(set) var isUpdating = false
    @Published private(set) var updateProgress: Double = 0
    
    private let fileManager = FileManager.default
    private let urlSession = URLSession.shared
    private let userDefaultsKey = "filterListState"
    
    private var cacheDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cacheDir = appSupport.appendingPathComponent("Swift Browser/FilterLists", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        return cacheDir
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedState = try? JSONDecoder().decode(FilterListState.self, from: data) {
            self.state = savedState
        } else {
            self.state = .empty
        }
    }
    
    func getFilterLists() -> [FilterList] {
        state.lists
    }
    
    func getEnabledLists() -> [FilterList] {
        state.lists.filter { $0.isEnabled }.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    func toggleFilterList(id: String, enabled: Bool) {
        guard let index = state.lists.firstIndex(where: { $0.id == id }) else { return }
        state.lists[index].isEnabled = enabled
        saveState()
    }
    
    func updateAllLists() async -> FilterUpdateSummary {
        await MainActor.run {
            isUpdating = true
            updateProgress = 0
        }
        
        var results: [FilterListUpdateResult] = []
        var skippedLists: [String] = []
        var totalRules = 0
        var ruleLimitReached = false
        let maxRulesPerList = 50000
        
        let enabledLists = getEnabledLists()
        let totalLists = enabledLists.count
        var processedLists = 0
        
        for var filterList in enabledLists {
            let result: FilterListUpdateResult
            
            do {
                let content = try await downloadFilterList(from: filterList.sourceURL)
                
                guard !content.isEmpty else {
                    result = FilterListUpdateResult(
                        listId: filterList.id,
                        listName: filterList.name,
                        success: false,
                        error: .noContent
                    )
                    results.append(result)
                    continue
                }
                
                try await cacheFilterList(content, for: filterList.id)
                
                let ruleCount = countFilterRules(in: content)
                let adjustedRuleCount = min(ruleCount, maxRulesPerList)
                
                filterList.lastUpdated = Date()
                filterList.ruleCount = adjustedRuleCount
                
                if let index = state.lists.firstIndex(where: { $0.id == filterList.id }) {
                    state.lists[index] = filterList
                }
                
                result = FilterListUpdateResult(
                    listId: filterList.id,
                    listName: filterList.name,
                    success: true,
                    rulesConverted: adjustedRuleCount
                )
                
                totalRules += adjustedRuleCount
                
                if totalRules >= maxRulesPerList {
                    ruleLimitReached = true
                }
                
            } catch let error as FilterListError {
                result = FilterListUpdateResult(
                    listId: filterList.id,
                    listName: filterList.name,
                    success: false,
                    error: error
                )
            } catch {
                result = FilterListUpdateResult(
                    listId: filterList.id,
                    listName: filterList.name,
                    success: false,
                    error: .downloadFailed(underlying: error)
                )
            }
            
            results.append(result)
            processedLists += 1
            
            await MainActor.run {
                updateProgress = Double(processedLists) / Double(totalLists)
            }
        }
        
        for disabledList in state.lists where !disabledList.isEnabled {
            skippedLists.append(disabledList.name)
        }
        
        state.lastFullUpdate = Date()
        state.ruleLimitWarning = ruleLimitReached
        saveState()
        
        let successCount = results.filter { $0.success }.count
        let failureCount = results.filter { !$0.success }.count
        
        await MainActor.run {
            isUpdating = false
            updateProgress = 1.0
        }
        
        return FilterUpdateSummary(
            totalLists: totalLists,
            successCount: successCount,
            failureCount: failureCount,
            totalRules: totalRules,
            results: results,
            ruleLimitReached: ruleLimitReached,
            skippedLists: skippedLists
        )
    }
    
    func getCachedFilterList(for id: String) async -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).txt")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }
        
        return content
    }
    
    func getFilterListStatus() -> FilterListStatus {
        let enabled = getEnabledLists()
        let totalRules = enabled.compactMap { $0.ruleCount }.reduce(0, +)
        
        return FilterListStatus(
            totalLists: state.lists.count,
            enabledLists: enabled.count,
            totalRules: totalRules,
            lastUpdate: state.lastFullUpdate,
            ruleLimitWarning: state.ruleLimitWarning
        )
    }
    
    private func downloadFilterList(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Swift-Browser/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FilterListError.downloadFailed(underlying: NSError(domain: "FilterListManager", code: -1))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw FilterListError.downloadFailed(underlying: NSError(
                domain: "FilterListManager",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
            ))
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw FilterListError.invalidContent
        }
        
        return content
    }
    
    private func cacheFilterList(_ content: String, for id: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).txt")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw FilterListError.downloadFailed(underlying: error)
        }
    }
    
    private func countFilterRules(in content: String) -> Int {
        let lines = content.components(separatedBy: .newlines)
        var count = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("!") { continue }
            if trimmed.hasPrefix("[") { continue }
            if trimmed.hasPrefix("#") { continue }
            
            count += 1
        }
        
        return count
    }
    
    private func saveState() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

struct FilterListStatus {
    let totalLists: Int
    let enabledLists: Int
    let totalRules: Int
    let lastUpdate: Date?
    let ruleLimitWarning: Bool
    
    var formattedLastUpdate: String {
        guard let date = lastUpdate else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
