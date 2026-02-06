import SwiftUI

struct AddressBarSuggestionsView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var historyManager: HistoryManager
    @Binding var isFocused: Bool
    @State private var selectedIndex: Int = -1
    @State private var searchSuggestions: [SearchSuggestion] = []
    @State private var isLoadingSuggestions = false

    struct Suggestion: Identifiable {
        let id = UUID()
        let title: String
        let url: String
        let type: SuggestionType
        let isSearch: Bool
    }

    enum SuggestionType {
        case history
        case bookmark
        case search
    }

    struct SearchSuggestion: Decodable {
        let phrase: String
    }

    var suggestions: [Suggestion] {
        let query = tabManager.addressBarText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty || query.hasPrefix("swiftbrowser://") { return [] }

        var result: [Suggestion] = []

        let matchedBookmarks = bookmarkManager.bookmarks.filter {
            $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query)
        }.prefix(5)

        result.append(contentsOf: matchedBookmarks.map {
            Suggestion(title: $0.title, url: $0.url, type: .bookmark, isSearch: false)
        })

        let matchedHistory = historyManager.history.filter {
            ($0.title?.lowercased().contains(query) ?? false) || $0.url.absoluteString.lowercased().contains(query)
        }.prefix(5)

        result.append(contentsOf: matchedHistory.map {
            Suggestion(title: $0.title ?? "Untitled", url: $0.url.absoluteString, type: .history, isSearch: false)
        })

        for suggestion in searchSuggestions.prefix(5) {
            result.append(Suggestion(title: suggestion.phrase, url: suggestion.phrase, type: .search, isSearch: true))
        }

        if result.isEmpty || !result.contains(where: { $0.type == .search }) {
            result.append(Suggestion(title: "Search with DuckDuckGo", url: query, type: .search, isSearch: true))
        }

        return result
    }

    var body: some View {
        if isFocused && !suggestions.isEmpty {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                            SuggestionRow(
                                suggestion: suggestion,
                                isSelected: index == selectedIndex,
                                query: tabManager.addressBarText
                            ) {
                                selectSuggestion(suggestion)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.top, 4)
            .onAppear {
                selectedIndex = -1
            }
            .onChange(of: tabManager.addressBarText) { _, newValue in
                fetchSearchSuggestions(for: newValue)
            }
            .background(
                NSEventView { event in
                    if event.keyCode == 125 {
                        selectedIndex = min(suggestions.count - 1, selectedIndex + 1)
                        return true
                    } else if event.keyCode == 126 {
                        selectedIndex = max(0, selectedIndex - 1)
                        return true
                    } else if event.keyCode == 36 {
                        if selectedIndex >= 0 && selectedIndex < suggestions.count {
                            selectSuggestion(suggestions[selectedIndex])
                            return true
                        }
                    }
                    return false
                }
            )
            .onTapGesture {
                isFocused = false
            }
        }
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
                isLoadingSuggestions = false
                guard let data = data, error == nil else { return }
                do {
                    let decoded = try JSONDecoder().decode([SearchSuggestion].self, from: data)
                    self.searchSuggestions = decoded.filter { suggestion in
                        suggestion.phrase.lowercased().contains(trimmedQuery.lowercased())
                    }
                } catch {
                    self.searchSuggestions = []
                }
            }
        }.resume()
    }

    private func selectSuggestion(_ suggestion: Suggestion) {
        tabManager.addressBarText = suggestion.url
        tabManager.loadCurrent()
        isFocused = false
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
                    HighlightedText(
                        text: suggestion.title,
                        highlight: query
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                    if suggestion.type != .search {
                        HighlightedText(
                            text: suggestion.url,
                            highlight: query
                        )
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
            .background(isSelected || isHovered ? Color.primary.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct NSEventView: NSViewRepresentable {
    let onEvent: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSView {
        let view = EventView()
        view.onEvent = onEvent
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class EventView: NSView {
        var onEvent: ((NSEvent) -> Bool)?
        var monitor: Any?

        override func viewDidMoveToWindow() {
            if window != nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    if self?.onEvent?(event) == true {
                        return nil
                    }
                    return event
                }
            } else if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}
