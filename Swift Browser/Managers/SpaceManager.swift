import Foundation
import WebKit
import Combine

public class SpaceManager: ObservableObject {
    public static let shared = SpaceManager()
    
    @Published public var spaces: [Space] = []
    @Published public var activeSpaceId: UUID
    @Published public var isLocked: Bool = true
    
    private let spacesKey = "com.swiftbrowser.spaces"
    private let hasInitializedKey = "com.swiftbrowser.hasInitializedEncryption"
    private var cookieStores: [UUID: WKWebsiteDataStore] = [:]
    
    public let processPool = WKProcessPool()
    
    private init() {
        self.activeSpaceId = UUID()
        
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
        
        HistoryManager.shared.setSpace(initialId)
        BookmarkManager.shared.setSpace(initialId)
        
        self.isLocked = !UserDefaults.standard.bool(forKey: hasInitializedKey)
    }
    
    public var activeSpace: Space {
        spaces.first { $0.id == activeSpaceId } ?? spaces.first ?? Space(name: "General", icon: "square.grid.2x2")
    }
    
    public func cookieDataStore(for space: Space) -> WKWebsiteDataStore {
        if space.isPrivate {
            return .nonPersistent()
        }
        
        if let existing = cookieStores[space.id] {
            return existing
        }
        
        let store: WKWebsiteDataStore
        if space.name == "General" {
            store = .default()
        } else if let identifier = space.dataStoreIdentifier {
            store = WKWebsiteDataStore(forIdentifier: identifier)
        } else {
            let newIdentifier = UUID()
            store = WKWebsiteDataStore(forIdentifier: newIdentifier)
            updateSpaceIdentifier(spaceId: space.id, identifier: newIdentifier)
        }
        
        cookieStores[space.id] = store
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
    
    public func initializeEncryption(with key: Data) {
        CookiePersistenceManager.shared.setEncryptionKey(key)
    }
    
    public func initializeEncryptionOnFirstLaunch() {
        let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)
        
        if hasInitialized {
            do {
                let key = try KeychainManager.shared.retrieveKey()
                CookiePersistenceManager.shared.setEncryptionKey(key)
            } catch {
                print("Failed to retrieve encryption key: \(error)")
            }
        } else {
            do {
                let newKey = try KeychainManager.shared.generateAndStoreKey()
                CookiePersistenceManager.shared.setEncryptionKey(newKey)
                UserDefaults.standard.set(true, forKey: hasInitializedKey)
            } catch {
                print("Failed to generate encryption key: \(error)")
            }
        }
    }
    
    public func unlock() {
        isLocked = false
    }
    
    public func lock() {
        isLocked = true
    }
    
    public func saveAllCookies() {
        // No-op - default storage auto-saves
    }
    
    public func hasEncryption() -> Bool {
        return CookiePersistenceManager.shared.hasEncryptionKey()
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
    
    public func resetToDefaultSpaces() {
        cookieStores.removeAll()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.spaces = [
                Space(name: "General", icon: "square.grid.2x2", colorName: "AccentColor"),
                Space(name: "Work", icon: "briefcase", colorName: "blue"),
                Space(name: "School", icon: "graduationcap", colorName: "orange"),
                Space(name: "Private", icon: "shield.lefthalf.filled", colorName: "purple", isPrivate: true)
            ]
            
            self.saveSpaces()
            
            if let defaultSpace = self.spaces.first(where: { !$0.isPrivate }) {
                self.activeSpaceId = defaultSpace.id
                HistoryManager.shared.setSpace(defaultSpace.id)
                BookmarkManager.shared.setSpace(defaultSpace.id)
            }
        }
    }
}
