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
    public var title: String
    public var url: String
    public var folder: String?

    public init(id: UUID = UUID(), title: String, url: String, folder: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.folder = folder
    }
}

public final class BookmarkManager: ObservableObject {
    public static let shared = BookmarkManager()
    @Published public var bookmarks: [Bookmark] = []
    private var activeSpaceId: UUID?
    
    public var folders: [String] {
        let allFolders = bookmarks.compactMap { $0.folder }
        return Array(Set(allFolders)).sorted()
    }
    
    private let baseKey = "Bookmarks"
    private var storageKey: String {
        if let id = activeSpaceId {
            return "\(baseKey)_\(id.uuidString)"
        }
        return baseKey
    }
    
    private var saveWorkItem: DispatchWorkItem?
    
    init() {
        // Initial load will happen when activeSpaceId is set
    }
    
    public func setSpace(_ spaceId: UUID) {
        guard activeSpaceId != spaceId else { return }
        activeSpaceId = spaceId
        load()
    }
    
    public func addBookmark(title: String, url: String, folder: String? = nil) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty, !trimmedURL.isEmpty else { return }
        
        let normalizedURL = trimmedURL.lowercased()
        if let index = bookmarks.firstIndex(where: { $0.url.lowercased() == normalizedURL }) {
            // Update existing bookmark folder if provided
            if let folder = folder {
                bookmarks[index].folder = folder
                scheduleSave()
            }
            return
        }
        
        let bookmark = Bookmark(title: trimmedTitle, url: trimmedURL, folder: folder)
        bookmarks.append(bookmark)
        scheduleSave()
    }
    
    public func updateBookmark(_ bookmark: Bookmark, title: String, url: String, folder: String?) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index].title = title
            bookmarks[index].url = url
            bookmarks[index].folder = folder
            scheduleSave()
        }
    }
    
    public func moveToFolder(bookmarkId: UUID, folder: String?) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmarkId }) {
            bookmarks[index].folder = folder
            scheduleSave()
        }
    }
    
    public func isBookmarked(url: String) -> Bool {
        let normalizedURL = url.lowercased()
        return bookmarks.contains(where: { $0.url.lowercased() == normalizedURL })
    }

    public func removeBookmark(_ bookmark: Bookmark) {
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
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = saved
        } else {
            bookmarks = []
        }
    }
}
