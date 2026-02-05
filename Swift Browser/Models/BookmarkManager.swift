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
    private var saveWorkItem: DispatchWorkItem?
    
    init() {
        load()
    }
    
    func addBookmark(title: String, url: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty, !trimmedURL.isEmpty else { return }
        
        let normalizedURL = trimmedURL.lowercased()
        if bookmarks.contains(where: { $0.url.lowercased() == normalizedURL }) {
            return
        }
        
        let bookmark = Bookmark(title: trimmedTitle, url: trimmedURL)
        bookmarks.append(bookmark)
        scheduleSave()
    }
    
    func isBookmarked(url: String) -> Bool {
        let normalizedURL = url.lowercased()
        return bookmarks.contains(where: { $0.url.lowercased() == normalizedURL })
    }

    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        scheduleSave()
    }
    
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.save()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
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
