import Foundation
import Combine
import WebKit

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var history: [HistoryItem] = []
    private var activeSpaceId: UUID?
    
    private let baseStorageKey = "browserHistory"
    private var storageKey: String {
        if let id = activeSpaceId {
            return "\(baseStorageKey)_\(id.uuidString)"
        }
        return baseStorageKey
    }
    
    private var saveWorkItem: DispatchWorkItem?
    
    private init() {
        // Initial load will happen when activeSpaceId is set
    }
    
    func setSpace(_ spaceId: UUID) {
        guard activeSpaceId != spaceId else { return }
        activeSpaceId = spaceId
        loadHistory()
    }
    
    func addVisit(url: URL, title: String?) {
        // Guard: Don't record history for private spaces
        guard let spaceId = activeSpaceId,
              let space = SpaceManager.shared.spaces.first(where: { $0.id == spaceId }),
              !space.isPrivate else { return }
        
        let item = HistoryItem(url: url, title: title, visitDate: Date())
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let first = self.history.first, first.url == url {
                self.history.removeFirst()
            }
            self.history.insert(item, at: 0)
            
            if self.history.count > 2000 {
                self.history = Array(self.history.prefix(2000))
            }
            
            self.scheduleSave()
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.history.removeAll()
            self.saveHistory()
        }
    }
    
    func deleteItem(_ item: HistoryItem) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.history.removeAll { $0.id == item.id }
            self.scheduleSave()
        }
    }
    
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveHistory()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }
    
    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(history) else {
            print("HistoryManager: Failed to encode history")
            return
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.history = decoded
        }
    }
}
