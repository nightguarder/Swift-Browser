import Foundation
import WebKit
import Combine

public class SpaceManager: ObservableObject {
    public static let shared = SpaceManager()
    
    @Published public var spaces: [Space] = []
    @Published public var activeSpaceId: UUID
    
    private let spacesKey = "com.swiftbrowser.spaces"
    private var dataStores: [UUID: WKWebsiteDataStore] = [:]
    
    private init() {
        self.activeSpaceId = UUID() // Temporary init to allow self access
        
        if let data = UserDefaults.standard.data(forKey: spacesKey),
           let decoded = try? JSONDecoder().decode([Space].self, from: data) {
            self.spaces = decoded
        } else {
            self.spaces = [
                Space(name: "General", icon: "square.grid.2x2", colorName: "AccentColor"),
                Space(name: "Work", icon: "briefcase", colorName: "blue"),
                Space(name: "School", icon: "graduationcap", colorName: "orange"),
                Space(name: "Private", icon: "shield.lefthalf.filled", colorName: "purple", isPrivate: true)
            ]
            saveSpaces()
        }
        let initialId = self.spaces.first?.id ?? UUID()
        self.activeSpaceId = initialId
        
        // Synchronize managers
        HistoryManager.shared.setSpace(initialId)
        BookmarkManager.shared.setSpace(initialId)
    }
    
    public var activeSpace: Space {
        spaces.first { $0.id == activeSpaceId } ?? spaces[0]
    }
    
    public func websiteDataStore(for space: Space) -> WKWebsiteDataStore {
        if space.isPrivate {
            return .nonPersistent()
        }
        
        if let existing = dataStores[space.id] {
            return existing
        }
        
        let store: WKWebsiteDataStore
        if let identifier = space.dataStoreIdentifier {
            store = WKWebsiteDataStore(forIdentifier: identifier)
        } else {
            // If it's a persistent space without an identifier (like General), use default
            if space.name == "General" {
                store = .default()
            } else {
                let newIdentifier = UUID()
                store = WKWebsiteDataStore(forIdentifier: newIdentifier)
                updateSpaceIdentifier(spaceId: space.id, identifier: newIdentifier)
            }
        }
        
        dataStores[space.id] = store
        return store
    }
    
    private func updateSpaceIdentifier(spaceId: UUID, identifier: UUID) {
        if let index = spaces.firstIndex(where: { $0.id == spaceId }) {
            var updatedSpace = spaces[index]
            updatedSpace.dataStoreIdentifier = identifier
            spaces[index] = updatedSpace
            saveSpaces()
        }
    }
    
    private func saveSpaces() {
        if let encoded = try? JSONEncoder().encode(spaces) {
            UserDefaults.standard.set(encoded, forKey: spacesKey)
        }
    }
    
    public func switchSpace(to spaceId: UUID) {
        activeSpaceId = spaceId
        HistoryManager.shared.setSpace(spaceId)
        BookmarkManager.shared.setSpace(spaceId)
    }
}
