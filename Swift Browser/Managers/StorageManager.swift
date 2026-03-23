import Foundation
import WebKit

public class StorageManager {
    public static let shared = StorageManager()

    private init() {}

    // MARK: - Fire Button (Burn All)

    /// Clears all website data (cache, cookies, localStorage, IndexedDB, etc.)
    /// from every space, preserving fireproofed domains.
    public func burnAll(completion: (() -> Void)? = nil) {
        let fireproof = FireproofDomains.shared.domains
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let spaces = SpaceManager.shared.spaces
        let group = DispatchGroup()

        for space in spaces {
            let store = SpaceManager.shared.cookieDataStore(for: space)

            if space.isPrivate {
                // Private spaces: clear everything, nothing to preserve
                group.enter()
                store.removeData(ofTypes: allTypes, modifiedSince: Date.distantPast) {
                    group.leave()
                }
            } else {
                // Persistent spaces: fetch records, filter fireproofed, then remove
                group.enter()
                store.fetchDataRecords(ofTypes: allTypes) { records in
                    let toRemove = records.filter { record in
                        let host = record.displayName
                            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
                            .lowercased()
                        return !fireproof.contains(host)
                    }
                    if !toRemove.isEmpty {
                        store.removeData(ofTypes: allTypes, for: toRemove) {
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    // MARK: - Auto Cleanup (on launch)

    /// Removes website data older than the specified number of days.
    /// Files are removed from the WebKit folder inside Swift Browser data container.
    /// Applies to all non-private spaces. Private spaces are fully cleared.
    public func cleanupOldData(olderThanDays days: Int = 30) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        for space in SpaceManager.shared.spaces {
            let store = SpaceManager.shared.cookieDataStore(for: space)

            if space.isPrivate {
                // Private sessions: clear everything on launch
                store.removeData(ofTypes: allTypes, modifiedSince: Date.distantPast) { }
            } else {
                // Persistent spaces: remove data older than cutoff
                store.removeData(ofTypes: allTypes, modifiedSince: cutoff) { }
            }
        }
    }

    // MARK: - Storage Size (for UI)

    /// Fetches current website data record count for display purposes.
    public func fetchDataRecordCount(completion: @escaping (Int) -> Void) {
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        var total = 0
        let group = DispatchGroup()

        for space in SpaceManager.shared.spaces where !space.isPrivate {
            let store = SpaceManager.shared.cookieDataStore(for: space)
            group.enter()
            store.fetchDataRecords(ofTypes: allTypes) { records in
                total += records.count
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(total)
        }
    }
}
