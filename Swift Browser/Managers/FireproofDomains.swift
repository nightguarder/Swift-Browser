import Foundation
import Combine

public class FireproofDomains: ObservableObject {
    public static let shared = FireproofDomains()

    private static let key = "com.swiftbrowser.fireproofDomains"

    @Published public private(set) var domains: Set<String>

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
        domains = Set(saved)
    }

    public func isFireproof(_ domain: String) -> Bool {
        domains.contains(normalize(domain))
    }

    public func add(_ domain: String) {
        let normalized = normalize(domain)
        guard !normalized.isEmpty else { return }
        domains.insert(normalized)
        save()
    }

    public func remove(_ domain: String) {
        domains.remove(normalize(domain))
        save()
    }

    public func toggle(_ domain: String) -> Bool {
        let normalized = normalize(domain)
        if domains.contains(normalized) {
            remove(normalized)
            return false
        } else {
            add(normalized)
            return true
        }
    }

    public func clearAll() {
        domains.removeAll()
        save()
    }

    private func save() {
        UserDefaults.standard.set(Array(domains), forKey: Self.key)
    }

    /// Strips `www.` prefix and lowercases the host for consistent matching.
    private func normalize(_ domain: String) -> String {
        domain
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
