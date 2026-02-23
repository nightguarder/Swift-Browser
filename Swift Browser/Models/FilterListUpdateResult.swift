//
//  FilterListUpdateResult.swift
//  Swift Browser
//
//  Results from filter list update operations
//

import Foundation

struct FilterListUpdateResult: Identifiable {
    let id: String
    let listId: String
    let listName: String
    let success: Bool
    let rulesConverted: Int
    let error: FilterListError?
    let timestamp: Date
    
    init(listId: String, listName: String, success: Bool, rulesConverted: Int = 0, error: FilterListError? = nil) {
        self.id = UUID().uuidString
        self.listId = listId
        self.listName = listName
        self.success = success
        self.rulesConverted = rulesConverted
        self.error = error
        self.timestamp = Date()
    }
}

enum FilterListError: Error, LocalizedError {
    case downloadFailed(underlying: Error)
    case conversionFailed(underlying: Error)
    case compilationFailed(underlying: Error)
    case invalidContent
    case noContent
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .conversionFailed(let error):
            return "Conversion failed: \(error.localizedDescription)"
        case .compilationFailed(let error):
            return "Rule compilation failed: \(error.localizedDescription)"
        case .invalidContent:
            return "Invalid filter list content"
        case .noContent:
            return "Empty filter list (no rules found)"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

struct FilterUpdateSummary {
    let totalLists: Int
    let successCount: Int
    let failureCount: Int
    let totalRules: Int
    let results: [FilterListUpdateResult]
    let ruleLimitReached: Bool
    let skippedLists: [String]
    
    var allSuccessful: Bool {
        failureCount == 0
    }
}
