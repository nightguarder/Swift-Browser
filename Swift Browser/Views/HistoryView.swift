import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @ObservedObject var tabManager: TabManager
    @State private var searchText = ""
    @State private var selectedItemID: UUID?
    @FocusState private var isSearchFocused: Bool
    @State private var selectedPeriod: TimePeriod = .all
    @State private var showingClearHistoryDialog = false
    @State private var addressSuggestions: [HistorySuggestion] = []
    @State private var addressBarWidth: CGFloat = 320
    @State private var showingDeletePeriodDialog = false
    @State private var periodToDelete: TimePeriod?
    
    struct HistorySuggestion: Identifiable {
        let id = UUID()
        let text: String
    }

    enum TimePeriod: String, CaseIterable {
        case all = "All History"
        case today = "Today"
        case yesterday = "Yesterday"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"

        var icon: String {
            switch self {
            case .all: return "clock"
            case .today: return "calendar.badge.clock"
            case .yesterday: return "arrow.uturn.backward"
            case .last7Days: return "calendar"
            case .last30Days: return "calendar.circle"
            }
        }

        func deleteItems(from manager: HistoryManager) {
            let now = Date()
            let calendar = Calendar.current

            switch self {
            case .all:
                manager.clearHistory()
            case .today:
                let itemsToDelete = manager.history.filter { calendar.isDateInToday($0.visitDate) }
                itemsToDelete.forEach { manager.deleteItem($0) }
            case .yesterday:
                let itemsToDelete = manager.history.filter { calendar.isDateInYesterday($0.visitDate) }
                itemsToDelete.forEach { manager.deleteItem($0) }
            case .last7Days:
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                let itemsToDelete = manager.history.filter { $0.visitDate >= sevenDaysAgo }
                itemsToDelete.forEach { manager.deleteItem($0) }
            case .last30Days:
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
                let itemsToDelete = manager.history.filter { $0.visitDate >= thirtyDaysAgo }
                itemsToDelete.forEach { manager.deleteItem($0) }
            }
        }

        var dateFilter: (HistoryItem) -> Bool {
            let now = Date()
            let calendar = Calendar.current
            switch self {
            case .all: return { _ in true }
            case .today: return { calendar.isDateInToday($0.visitDate) }
            case .yesterday: return { calendar.isDateInYesterday($0.visitDate) }
            case .last7Days:
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                return { $0.visitDate >= sevenDaysAgo }
            case .last30Days:
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
                return { $0.visitDate >= thirtyDaysAgo }
            }
        }

        func itemCount(from manager: HistoryManager) -> Int {
            manager.history.filter(dateFilter).count
        }
    }

    var filteredHistory: [HistoryItem] {
        var items = historyManager.history

        items = items.filter(selectedPeriod.dateFilter)

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter { item in
                (item.title?.lowercased().contains(query) ?? false) ||
                item.url.absoluteString.lowercased().contains(query)
            }
        }

        return items
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
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("History")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    KeyboardShortcutHint("⌘Y")
                }
                .padding(.horizontal, 12)
                .padding(.top, 20)

                ForEach(TimePeriod.allCases, id: \.self) { period in
                    HistoryPeriodRow(
                        period: period,
                        isSelected: selectedPeriod == period,
                        itemCount: itemCount(for: period)
                    ) {
                        selectedPeriod = period
                    } onDelete: {
                        if period == .all {
                            showingClearHistoryDialog = true
                        } else {
                            periodToDelete = period
                            showingDeletePeriodDialog = true
                        }
                    }
                }

                Spacer()

                Button(action: { showingClearHistoryDialog = true }) {
                    Label("Clear History", systemImage: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(12)
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text(selectedPeriod.rawValue)
                        .font(.system(size: 24, weight: .bold))

                    Spacer()

                    TextField("Search History", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                        .focused($isSearchFocused)
                        .onExitCommand {
                            isSearchFocused = false
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
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if historyManager.history.isEmpty {
                                Text("No history yet.")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 40)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else if filteredHistory.isEmpty {
                                Text("No history for this period.")
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
                                                isSelected: selectedItemID == item.id,
                                                action: {
                                                    tabManager.addressBarText = item.url.absoluteString
                                                    tabManager.loadCurrent()
                                                },
                                                onDelete: {
                                                    historyManager.deleteItem(item)
                                                }
                                            )
                                            .id(item.id)
                                            .contextMenu {
                                                Button {
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(item.url.absoluteString, forType: .string)
                                                } label: {
                                                    Label("Copy URL", systemImage: "doc.on.doc")
                                                }
                                                .keyboardShortcut("c", modifiers: .command)

                                                Button {
                                                    tabManager.addressBarText = item.url.absoluteString
                                                    tabManager.loadCurrent()
                                                } label: {
                                                    Label("Open", systemImage: "arrow.right")
                                                }
                                                .keyboardShortcut("o", modifiers: .command)

                                                Divider()

                                                Button(role: .destructive) {
                                                    historyManager.deleteItem(item)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                .keyboardShortcut(.delete, modifiers: .command)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, minHeight: 400, alignment: .topLeading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isSearchFocused = false
                        }
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
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isSearchFocused = true
        }
        .onTapGesture {
            isSearchFocused = false
        }
        .alert("Clear All History?", isPresented: $showingClearHistoryDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Clear History", role: .destructive) {
                historyManager.clearHistory()
            }
        } message: {
            Text("This will permanently delete all your browsing history. This action cannot be undone.")
        }
        .alert("Delete \(periodToDelete?.rawValue ?? "") History?", isPresented: $showingDeletePeriodDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let period = periodToDelete {
                    period.deleteItems(from: historyManager)
                }
            }
        } message: { 
            Text("This will permanently delete all history from this time period. This action cannot be undone.")
        }
    }

    private func itemCount(for period: TimePeriod) -> Int {
        period.itemCount(from: historyManager)
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

    private func deleteSelected() {
        guard let id = selectedItemID,
              let item = flatItems.first(where: { $0.item.id == id }) else { return }
        historyManager.deleteItem(item.item)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

struct HistoryItemRow: View {
    let item: HistoryItem
    let searchText: String
    let isSelected: Bool
    let action: () -> Void
    let onDelete: () -> Void
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
                FaviconView(urlString: item.url.absoluteString, title: item.title ?? "Untitled", size: 20)

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

                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
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

struct HistoryPeriodRow: View {
    let period: HistoryView.TimePeriod
    let isSelected: Bool
    let itemCount: Int
    let action: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: period.icon)
                    .frame(width: 16)

                Text(period.rawValue)
                    .lineLimit(1)

                if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isHovered && period != .all {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
