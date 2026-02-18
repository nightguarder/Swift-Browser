import SwiftUI
import WebKit

struct CookieItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresDate: Date?
    let wkCookie: HTTPCookie
}

struct CookiesView: View {
    @State private var cookies: [CookieItem] = []
    @State private var searchText = ""
    @State private var selectedDomain: String? = nil
    @State private var selectedItemID: UUID?
    @FocusState private var isSearchFocused: Bool
    @State private var showingClearCookiesDialog = false
    @State private var showingDeleteDomainDialog = false
    @State private var domainToDelete: String?
    @State private var isLoading = false
    
    let dataStore: WKWebsiteDataStore
    let spaceId: UUID
    
    init(dataStore: WKWebsiteDataStore, spaceId: UUID) {
        self.dataStore = dataStore
        self.spaceId = spaceId
    }
    
    var filteredCookies: [CookieItem] {
        var items = cookies
        
        // Filter by selected domain
        if let domain = selectedDomain {
            items = items.filter { $0.domain == domain }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter { item in
                item.name.lowercased().contains(query) ||
                item.value.lowercased().contains(query) ||
                item.domain.lowercased().contains(query)
            }
        }
        
        return items
    }
    
    var groupedCookies: [String: [CookieItem]] {
        Dictionary(grouping: filteredCookies) { $0.domain }
    }
    
    var sortedDomains: [String] {
        groupedCookies.keys.sorted()
    }
    
    var allDomains: [String] {
        Dictionary(grouping: cookies) { $0.domain }.keys.sorted()
    }
    
    var flatItems: [(domain: String, item: CookieItem)] {
        sortedDomains.flatMap { domain in
            (groupedCookies[domain] ?? []).map { (domain, $0) }
        }
    }
    
    var selectedIndex: Int? {
        guard let id = selectedItemID else { return nil }
        return flatItems.firstIndex { $0.item.id == id }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Cookies")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 20)
                
                // All Cookies option
                CookieDomainRow(
                    domain: "All Cookies",
                    icon: "globe",
                    isSelected: selectedDomain == nil,
                    itemCount: cookies.count
                ) {
                    selectedDomain = nil
                } onDelete: {
                    showingClearCookiesDialog = true
                }
                
                Divider()
                    .padding(.horizontal, 12)
                
                // Domain list
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(allDomains, id: \.self) { domain in
                            CookieDomainRow(
                                domain: domain,
                                icon: "globe",
                                isSelected: selectedDomain == domain,
                                itemCount: cookies.filter { $0.domain == domain }.count
                            ) {
                                selectedDomain = domain
                            } onDelete: {
                                domainToDelete = domain
                                showingDeleteDomainDialog = true
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { showingClearCookiesDialog = true }) {
                    Label("Clear All Cookies", systemImage: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(12)
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Main content
            VStack(spacing: 0) {
                HStack {
                    Text(selectedDomain ?? "All Cookies")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    TextField("Search Cookies", text: $searchText)
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
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if cookies.isEmpty {
                    Spacer()
                    Text("No cookies for this space.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else if filteredCookies.isEmpty {
                    Spacer()
                    Text("No cookies found.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 20) {
                                ForEach(sortedDomains, id: \.self) { domain in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(domain)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(groupedCookies[domain] ?? []) { item in
                                            CookieItemRow(
                                                item: item,
                                                searchText: searchText,
                                                isSelected: selectedItemID == item.id,
                                                action: {
                                                    // Copy cookie value
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(item.value, forType: .string)
                                                },
                                                onDelete: {
                                                    deleteCookie(item)
                                                }
                                            )
                                            .id(item.id)
                                            .contextMenu {
                                                Button {
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(item.value, forType: .string)
                                                } label: {
                                                    Label("Copy Value", systemImage: "doc.on.doc")
                                                }
                                                .keyboardShortcut("c", modifiers: .command)
                                                
                                                Button {
                                                    NSPasteboard.general.clearContents()
                                                    NSPasteboard.general.setString(item.domain, forType: .string)
                                                } label: {
                                                    Label("Copy Domain", systemImage: "doc.on.doc")
                                                }
                                                
                                                Divider()
                                                
                                                Button(role: .destructive) {
                                                    deleteCookie(item)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                .keyboardShortcut(.delete, modifiers: .command)
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
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            isSearchFocused = true
            loadCookies()
        }
        .onTapGesture {
            isSearchFocused = false
        }
        .alert("Clear All Cookies?", isPresented: $showingClearCookiesDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                deleteAllCookies()
            }
        } message: {
            Text("This will permanently delete all cookies for this space. This action cannot be undone.")
        }
        .alert("Delete Cookies for \(domainToDelete ?? "")?", isPresented: $showingDeleteDomainDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let domain = domainToDelete {
                    deleteCookiesForDomain(domain)
                }
            }
        } message: {
            Text("This will permanently delete all cookies from this domain. This action cannot be undone.")
        }
    }
    
    private func loadCookies() {
        isLoading = true
        
        if let cachedCookies = CookiePersistenceManager.shared.getCachedCookies(for: spaceId), !cachedCookies.isEmpty {
            let group = DispatchGroup()
            for cookie in cachedCookies {
                group.enter()
                dataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.fetchCookiesFromDataStore()
            }
        } else {
            fetchCookiesFromDataStore()
        }
    }
    
    private func fetchCookiesFromDataStore() {
        dataStore.httpCookieStore.getAllCookies { allCookies in
            DispatchQueue.main.async {
                self.cookies = allCookies.map { cookie in
                    CookieItem(
                        name: cookie.name,
                        value: cookie.value,
                        domain: cookie.domain,
                        path: cookie.path,
                        expiresDate: cookie.expiresDate,
                        wkCookie: cookie
                    )
                }.sorted { $0.domain < $1.domain }
                self.isLoading = false
            }
        }
    }
    
    private func deleteCookie(_ item: CookieItem) {
        dataStore.httpCookieStore.delete(item.wkCookie) {
            DispatchQueue.main.async {
                self.cookies.removeAll { $0.id == item.id }
            }
        }
    }
    
    private func deleteCookiesForDomain(_ domain: String) {
        let cookiesToDelete = cookies.filter { $0.domain == domain }
        let group = DispatchGroup()
        
        for cookie in cookiesToDelete {
            group.enter()
            dataStore.httpCookieStore.delete(cookie.wkCookie) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.cookies.removeAll { $0.domain == domain }
            if self.selectedDomain == domain {
                self.selectedDomain = nil
            }
        }
    }
    
    private func deleteAllCookies() {
        let group = DispatchGroup()
        
        for cookie in cookies {
            group.enter()
            dataStore.httpCookieStore.delete(cookie.wkCookie) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.cookies.removeAll()
        }
    }
    
    private func moveSelection(direction: Int) {
        guard !flatItems.isEmpty else { return }
        let current = selectedIndex ?? -1
        let newIndex = max(0, min(flatItems.count - 1, current + direction))
        selectedItemID = flatItems[newIndex].item.id
    }
}

struct CookieItemRow: View {
    let item: CookieItem
    let searchText: String
    let isSelected: Bool
    let action: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "ladybug.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    HighlightedText(
                        text: item.name,
                        highlight: searchText
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    
                    Text(item.value)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let expires = item.expiresDate {
                        Text("Expires: \(Self.dateFormatter.string(from: expires))")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
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

struct CookieDomainRow: View {
    let domain: String
    let icon: String
    let isSelected: Bool
    let itemCount: Int
    let action: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                
                Text(domain)
                    .lineLimit(1)
                
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isHovered && domain != "All Cookies" {
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


