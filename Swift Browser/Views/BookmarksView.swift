//
//  BookmarksView.swift
//  Swift Browser
//

import SwiftUI

struct BookmarksView: View {
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @ObservedObject var tabManager: TabManager
    @State private var searchText = ""
    @State private var selectedBookmarkID: UUID?
    @FocusState private var isSearchFocused: Bool
    @State private var selectedFolder: String?
    @State private var addressSuggestions: [BookmarkSuggestion] = []
    @State private var addressBarWidth: CGFloat = 320
    
    struct BookmarkSuggestion: Identifiable {
        let id = UUID()
        let text: String
    }
    
    var filteredBookmarks: [Bookmark] {
        var result = bookmarkManager.bookmarks
        
        if let folder = selectedFolder {
            result = result.filter { $0.folder == folder }
        }
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { item in
                item.title.lowercased().contains(query) ||
                item.url.lowercased().contains(query)
            }
        }
        
        return result
    }
    
    var selectedIndex: Int? {
        guard let id = selectedBookmarkID else { return nil }
        return filteredBookmarks.firstIndex { $0.id == id }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Folders Sidebar
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Library")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    KeyboardShortcutHint("⌘B")
                }
                .padding(.horizontal, 12)
                .padding(.top, 20)
                
                FolderRow(title: "All Bookmarks", icon: "bookmark", isSelected: selectedFolder == nil) {
                    selectedFolder = nil
                }
                
                if !bookmarkManager.folders.isEmpty {
                    Text("Folders")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                    
                    ForEach(bookmarkManager.folders, id: \.self) { folder in
                        FolderRow(title: folder, icon: "folder", isSelected: selectedFolder == folder) {
                            selectedFolder = folder
                        }
                    }
                }
                
                Spacer()
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            VStack(spacing: 0) {
                HStack {
                    Text(selectedFolder ?? "All Bookmarks")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    TextField("Search Bookmarks", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                        .focused($isSearchFocused)
                        .onExitCommand {
                            isSearchFocused = false
                        }
                        .onChange(of: isSearchFocused) { _, newValue in
                            if !newValue {
                                NSApp.keyWindow?.makeFirstResponder(nil)
                            }
                        }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                .onTapGesture {
                    isSearchFocused = false
                }
                // Address suggestions dropdown (fixed height with internal scrolling)
                if !addressSuggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(addressSuggestions) { item in
                                Button(action: { self.searchText = item.text }) {
                                    Text(item.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(width: addressBarWidth)
                    .frame(minHeight: 150, maxHeight: 240, alignment: .topLeading)
                    .background(Color(NSColor.windowBackgroundColor))
                    .border(Color.gray.opacity(0.25))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if bookmarkManager.bookmarks.isEmpty {
                                Text("No bookmarks yet.")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 40)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else if filteredBookmarks.isEmpty {
                                Text("No bookmarks match your criteria.")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 40)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(filteredBookmarks) { bookmark in
                                    BookmarkItemRow(
                                        bookmark: bookmark,
                                        searchText: searchText,
                                        isSelected: selectedBookmarkID == bookmark.id,
                                        onDelete: {
                                            bookmarkManager.removeBookmark(bookmark)
                                        },
                                        onSelect: {
                                            tabManager.addressBarText = bookmark.url
                                            tabManager.loadCurrent()
                                        },
                                        onMove: { folder in
                                            bookmarkManager.moveToFolder(bookmarkId: bookmark.id, folder: folder)
                                        }
                                    )
                                    .id(bookmark.id)
                                }
                            }
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, minHeight: 400, alignment: .topLeading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isSearchFocused = false
                        }
                    }
                    .onChange(of: selectedBookmarkID) { _, newValue in
                        if let id = newValue {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isSearchFocused = true
        }
        .onTapGesture {
            isSearchFocused = false
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                addressSuggestions = []
            } else {
                let samples = ["https://example.com/search?q=", "https://swift.org/search?q=", "https://duckduckgo.com/?q="]
                addressSuggestions = samples.map { BookmarkSuggestion(text: $0 + newValue) }
            }
        }
    }
    
    private func moveSelection(direction: Int) {
        guard !filteredBookmarks.isEmpty else { return }
        let current = selectedIndex ?? -1
        let newIndex = max(0, min(filteredBookmarks.count - 1, current + direction))
        selectedBookmarkID = filteredBookmarks[newIndex].id
    }
    
    private func openSelected() {
        guard let id = selectedBookmarkID,
              let bookmark = filteredBookmarks.first(where: { $0.id == id }) else { return }
        tabManager.addressBarText = bookmark.url
        tabManager.loadCurrent()
    }
    
    private func copySelectedURL() {
        guard let id = selectedBookmarkID,
              let bookmark = filteredBookmarks.first(where: { $0.id == id }) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bookmark.url, forType: .string)
    }
    
    private func deleteSelected() {
        guard let id = selectedBookmarkID,
              let bookmark = filteredBookmarks.first(where: { $0.id == id }) else { return }
        bookmarkManager.removeBookmark(bookmark)
    }
}

struct FolderRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .frame(width: 16)
                Text(title)
                    .lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct BookmarkItemRow: View {
    let bookmark: Bookmark
    let searchText: String
    let isSelected: Bool
    let onDelete: () -> Void
    let onSelect: () -> Void
    let onMove: (String?) -> Void
    @State private var isHovered = false
    @State private var showingFolderInput = false
    @State private var newFolderName = ""
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                FaviconView(urlString: bookmark.url, title: bookmark.title, size: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        HighlightedText(
                            text: bookmark.title,
                            highlight: searchText
                        )
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        
                        if let folder = bookmark.folder {
                            Text(folder)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    
                    HighlightedText(
                        text: bookmark.url,
                        highlight: searchText
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                
                Spacer()
                
                if isHovered || isSelected {
                    HStack(spacing: 8) {
                        Menu {
                            Button("No Folder") { onMove(nil) }
                            Divider()
                            ForEach(BookmarkManager.shared.folders, id: \.self) { folder in
                                Button(folder) { onMove(folder) }
                            }
                            Divider()
                            Button("New Folder...") {
                                newFolderName = ""
                                showingFolderInput = true
                            }
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .sheet(isPresented: $showingFolderInput) {
            VStack(spacing: 16) {
                Text("New Folder")
                    .font(.headline)
                TextField("Folder Name", text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                HStack {
                    Button("Cancel") { showingFolderInput = false }
                    Button("Create") {
                        if !newFolderName.isEmpty {
                            onMove(newFolderName)
                        }
                        showingFolderInput = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .contextMenu {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(bookmark.url, forType: .string)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
            .keyboardShortcut("c", modifiers: .command)

            Button(action: onSelect) {
                Label("Open", systemImage: "arrow.right")
            }
            .keyboardShortcut("o", modifiers: .command)

            Menu("Move to Folder") {
                Button("No Folder") { onMove(nil) }
                Divider()
                ForEach(BookmarkManager.shared.folders, id: \.self) { folder in
                    Button(folder) { onMove(folder) }
                }
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .accentColor.opacity(0.1)
        } else if isHovered {
            return .primary.opacity(0.05)
        }
        return .clear
    }
}
