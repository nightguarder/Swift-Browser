import SwiftUI

struct AddressBarSuggestionsView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var historyManager: HistoryManager
    @Binding var isFocused: Bool
    @Binding var selectedIndex: Int
    @State private var searchSuggestions: [SearchSuggestion] = []
    @State private var isLoadingSuggestions = false
    @State private var cachedSuggestions: [Suggestion] = []
    @State private var lastQuery: String = ""
    
    // Capture space ID at view creation to prevent race conditions when switching spaces
    private let currentSpaceId: UUID
    
    private var isPrivateSpace: Bool {
        SpaceManager.shared.spaces.first { $0.id == currentSpaceId }?.isPrivate ?? false
    }
    
    init(tabManager: TabManager, bookmarkManager: BookmarkManager, historyManager: HistoryManager, isFocused: Binding<Bool>, selectedIndex: Binding<Int>) {
        self.tabManager = tabManager
        self.bookmarkManager = bookmarkManager
        self.historyManager = historyManager
        self._isFocused = isFocused
        self._selectedIndex = selectedIndex
        self.currentSpaceId = SpaceManager.shared.activeSpaceId
    }

    struct Suggestion: Identifiable, Equatable, Hashable {
        let id = UUID()
        let title: String
        let url: String
        let type: SuggestionType
        let isSearch: Bool
        
        static func == (lhs: Suggestion, rhs: Suggestion) -> Bool {
            lhs.id == rhs.id && lhs.url == rhs.url
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    enum SuggestionType {
        case history
        case bookmark
        case search
    }

    struct SearchSuggestion: Decodable, Equatable {
        let phrase: String
    }

    private var query: String {
        tabManager.addressBarText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateSuggestions() -> [Suggestion] {
        let currentQuery = query
        guard !currentQuery.isEmpty, !currentQuery.hasPrefix("swiftbrowser://") else { return [] }
        
        // Only recalculate if query changed
        if currentQuery == lastQuery && !cachedSuggestions.isEmpty {
            return cachedSuggestions
        }

        var result: [Suggestion] = []

        // Only show history and bookmarks in non-private spaces
        if !isPrivateSpace {
            result.append(contentsOf: bookmarkManager.bookmarks
                .filter { $0.title.lowercased().contains(currentQuery) || $0.url.lowercased().contains(currentQuery) }
                .prefix(5)
                .map { Suggestion(title: $0.title, url: $0.url, type: .bookmark, isSearch: false) })

            result.append(contentsOf: historyManager.history
                .filter { ($0.title?.lowercased().contains(currentQuery) ?? false) || $0.url.absoluteString.lowercased().contains(currentQuery) }
                .prefix(5)
                .map { 
                    let title = $0.title?.isEmpty == false ? $0.title! : extractTitleFromURL($0.url)
                    return Suggestion(title: title, url: $0.url.absoluteString, type: .history, isSearch: false) 
                })
        }

        result.append(contentsOf: searchSuggestions.prefix(5)
            .map { Suggestion(title: $0.phrase, url: $0.phrase, type: .search, isSearch: true) })

        if result.isEmpty || !result.contains(where: { $0.type == .search }) {
            result.append(Suggestion(title: "Search with DuckDuckGo", url: currentQuery, type: .search, isSearch: true))
        }

        return Array(result.prefix(8))
    }

    var body: some View {
        Group {
            if !cachedSuggestions.isEmpty {
                suggestionsList
            }
        }
        .onAppear {
            selectedIndex = -1
            cachedSuggestions = updateSuggestions()
            lastQuery = query
        }
        .onChange(of: query) { _, newValue in
            fetchSearchSuggestions(for: newValue)
            if newValue != lastQuery {
                cachedSuggestions = updateSuggestions()
                lastQuery = newValue
                selectedIndex = -1
            }
        }
        .onChange(of: searchSuggestions) { _, _ in
            cachedSuggestions = updateSuggestions()
        }
    }
    
    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<cachedSuggestions.count, id: \.self) { index in
                    let suggestion = cachedSuggestions[index]
                    SuggestionRow(
                        suggestion: suggestion,
                        isSelected: index == selectedIndex,
                        query: query
                    ) {
                        selectSuggestion(suggestion)
                    }
                }
            }
        }
        .frame(maxHeight: 280)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func dismissAndUnfocus() {
        isFocused = false
        NSApp.keyWindow?.makeFirstResponder(nil)
    }

    private func fetchSearchSuggestions(for query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, !trimmedQuery.hasPrefix("http"), !trimmedQuery.hasPrefix("swiftbrowser://") else {
            searchSuggestions = []
            return
        }

        guard !isLoadingSuggestions else { return }
        isLoadingSuggestions = true

        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://duckduckgo.com/ac/?q=\(encodedQuery)&kl=us-en") else {
            isLoadingSuggestions = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingSuggestions = false
                guard let data = data, error == nil else { return }
                do {
                    let decoded = try JSONDecoder().decode([SearchSuggestion].self, from: data)
                    self.searchSuggestions = decoded.filter { $0.phrase.lowercased().contains(trimmedQuery.lowercased()) }
                } catch {
                    self.searchSuggestions = []
                }
            }
        }.resume()
    }

    private func selectSuggestion(_ suggestion: Suggestion) {
        tabManager.addressBarText = suggestion.url
        tabManager.loadCurrent()
        dismissAndUnfocus()
    }

    // Extract a readable title from URL when page title is not available
    private func extractTitleFromURL(_ url: URL) -> String {
        // Try to use the last path component if it's not empty
        let lastComponent = url.lastPathComponent
        if !lastComponent.isEmpty && lastComponent != "/" {
            // Remove file extension if present
            let withoutExtension = (lastComponent as NSString).deletingPathExtension
            if !withoutExtension.isEmpty {
                // Convert kebab-case or snake_case to spaces and capitalize
                return withoutExtension
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
            }
        }

        // Fallback to host name
        if let host = url.host {
            // Remove www. prefix if present
            return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        }

        // Final fallback
        return url.absoluteString
    }
}

struct SuggestionRow: View {
    let suggestion: AddressBarSuggestionsView.Suggestion
    let isSelected: Bool
    let query: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                FaviconView(urlString: suggestion.url, title: suggestion.title, size: 20)

                VStack(alignment: .leading, spacing: 2) {
                    HighlightedText(text: suggestion.title, highlight: query)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if suggestion.type != .search {
                        HighlightedText(text: suggestion.url, highlight: query)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if suggestion.type == .bookmark {
                    Text("Bookmark")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundStyle(Color.accentColor)
                }

                if suggestion.type == .search {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected || isHovered ? Color.primary.opacity(0.1) : .clear)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
