//
//  BookmarkManager.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//
import Foundation
import Combine

public struct Bookmark: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let url: String

    public init(id: UUID = UUID(), title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
}

public final class BookmarkManager: ObservableObject {
    @Published var bookmarks: [Bookmark] = []

    private let key = "Bookmarks"

    init() {
        load()
    }

    func addBookmark(title: String, url: String) {
        // Validate inputs
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty, !trimmedURL.isEmpty else { return }
        
        // Check for duplicates (case-insensitive URL comparison)
        let normalizedURL = trimmedURL.lowercased()
        if bookmarks.contains(where: { $0.url.lowercased() == normalizedURL }) {
            return // Already bookmarked
        }
        
        let bookmark = Bookmark(title: trimmedTitle, url: trimmedURL)
        bookmarks.append(bookmark)
        save()
    }
    
    func isBookmarked(url: String) -> Bool {
        let normalizedURL = url.lowercased()
        return bookmarks.contains(where: { $0.url.lowercased() == normalizedURL })
    }

    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = saved
        }
    }
}
