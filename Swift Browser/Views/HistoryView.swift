import SwiftUI

final class HistoryKeyboardCoordinator: NSObject {
    private var moveAction: ((Int) -> Void)?
    private var openAction: (() -> Void)?
    private var focusSearchAction: (() -> Void)?
    private var copyURLAction: (() -> Void)?
    
    init(moveAction: @escaping (Int) -> Void,
         openAction: @escaping () -> Void,
         focusSearchAction: @escaping () -> Void,
         copyURLAction: @escaping () -> Void) {
        self.moveAction = moveAction
        self.openAction = openAction
        self.focusSearchAction = focusSearchAction
        self.copyURLAction = copyURLAction
        super.init()
        setupMonitor()
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private var monitor: Any?
    
    private func setupMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if event.isARepeat { return event }
            
            if event.keyCode == 123 {
                self.moveAction?(-1)
                return nil
            } else if event.keyCode == 124 {
                self.moveAction?(1)
                return nil
            } else if event.keyCode == 36 {
                self.openAction?()
                return nil
            } else if event.keyCode == 53 {
                self.focusSearchAction?()
                return nil
            }
            
            if event.modifierFlags.contains(.command) && event.characters == "c" {
                self.copyURLAction?()
                return nil
            }
            
            return event
        }
    }
}

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @ObservedObject var tabManager: TabManager
    @State private var searchText = ""
    @State private var selectedItemID: UUID?
    @FocusState private var isSearchFocused: Bool
    @State private var keyboardCoordinator: HistoryKeyboardCoordinator?
    
    var filteredHistory: [HistoryItem] {
        if searchText.isEmpty {
            return historyManager.history
        } else {
            let query = searchText.lowercased()
            return historyManager.history.filter { item in
                (item.title?.lowercased().contains(query) ?? false) ||
                item.url.absoluteString.lowercased().contains(query)
            }
        }
    }
    
    var groupedHistory: [Date: [HistoryItem]] {
        Dictionary(grouping: filteredHistory) { item in
            Calendar.current.startOfDay(for: item.visitDate)
        }
    }
    
    var sortedDates: [Date] {
        groupedHistory.keys.sorted(by: >)
    }
    
    var flatItems: [(date: Date, item: HistoryItem)] {
        sortedDates.flatMap { date in
            (groupedHistory[date] ?? []).map { (date, $0) }
        }
    }
    
    var selectedIndex: Int? {
        guard let id = selectedItemID else { return nil }
        return flatItems.firstIndex { $0.item.id == id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                TextField("Search History", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .focused($isSearchFocused)
                
                Button("Clear History") {
                    historyManager.clearHistory()
                }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if historyManager.history.isEmpty {
                            Text("No history yet.")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(sortedDates, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(Self.dateFormatter.string(from: date))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(groupedHistory[date] ?? []) { item in
                                        HistoryItemRow(
                                            item: item,
                                            searchText: searchText,
                                            isSelected: selectedItemID == item.id
                                        ) {
                                            tabManager.addressBarText = item.url.absoluteString
                                            tabManager.loadCurrent()
                                        }
                                        .id(item.id)
                                        .contextMenu {
                                            Button {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(item.url.absoluteString, forType: .string)
                                            } label: {
                                                Label("Copy URL", systemImage: "doc.on.doc")
                                            }
                                            
                                            Button {
                                                tabManager.addressBarText = item.url.absoluteString
                                                tabManager.loadCurrent()
                                            } label: {
                                                Label("Open", systemImage: "arrow.right")
                                            }
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                historyManager.deleteItem(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .onChange(of: selectedItemID) { _, newValue in
                    if let id = newValue {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isSearchFocused = true
            keyboardCoordinator = HistoryKeyboardCoordinator(
                moveAction: { direction in
                    self.moveSelection(direction: direction)
                },
                openAction: {
                    self.openSelected()
                },
                focusSearchAction: {
                    self.isSearchFocused = true
                },
                copyURLAction: {
                    self.copySelectedURL()
                }
            )
        }
        .onDisappear {
            keyboardCoordinator = nil
        }
    }
    
    private func moveSelection(direction: Int) {
        guard !flatItems.isEmpty else { return }
        let current = selectedIndex ?? -1
        let newIndex = max(0, min(flatItems.count - 1, current + direction))
        selectedItemID = flatItems[newIndex].item.id
    }
    
    private func openSelected() {
        guard let id = selectedItemID,
              let item = flatItems.first(where: { $0.item.id == id }) else { return }
        tabManager.addressBarText = item.item.url.absoluteString
        tabManager.loadCurrent()
    }
    
    private func copySelectedURL() {
        guard let id = selectedItemID,
              let item = flatItems.first(where: { $0.item.id == id }) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.item.url.absoluteString, forType: .string)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

struct HighlightedText: View {
    let text: String
    let highlight: String
    
    var body: some View {
        if highlight.isEmpty {
            Text(text)
        } else {
            Text(highlightedAttributedString)
        }
    }
    
    private var highlightedAttributedString: AttributedString {
        var result = AttributedString(text)
        if let range = result.range(of: highlight, options: .caseInsensitive) {
            result[range].backgroundColor = .yellow.opacity(0.3)
        }
        return result
    }
}

struct HistoryItemRow: View {
    let item: HistoryItem
    let searchText: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(Self.timeFormatter.string(from: item.visitDate))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 2) {
                    HighlightedText(
                        text: item.title ?? "Untitled",
                        highlight: searchText
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    
                    HighlightedText(
                        text: item.url.absoluteString,
                        highlight: searchText
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 20)
            .background(backgroundColor)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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
