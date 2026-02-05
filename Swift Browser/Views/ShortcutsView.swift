import SwiftUI

struct ShortcutItem: Identifiable {
    let id = UUID()
    let title: String
    let keys: String
    let category: String
}

struct ShortcutsView: View {
    @ObservedObject var tabManager: TabManager
    @State private var searchText = ""
    
    private let allShortcuts: [ShortcutItem] = [
        // Tabs
        ShortcutItem(title: "New Tab", keys: "⌘ T", category: "Tabs"),
        ShortcutItem(title: "Close Tab", keys: "⌘ W", category: "Tabs"),
        ShortcutItem(title: "Next Tab", keys: "⌘ ⇧ ]", category: "Tabs"),
        ShortcutItem(title: "Previous Tab", keys: "⌘ ⇧ [", category: "Tabs"),
        ShortcutItem(title: "Switch to Tab 1-9", keys: "⌘ 1-9", category: "Tabs"),
        
        // Navigation
        ShortcutItem(title: "Focus Address Bar", keys: "⌘ L", category: "Navigation"),
        ShortcutItem(title: "Reload Page", keys: "⌘ R", category: "Navigation"),
        ShortcutItem(title: "Go Back", keys: "⌘ [", category: "Navigation"),
        ShortcutItem(title: "Go Forward", keys: "⌘ ]", category: "Navigation"),
        
        // Zoom
        ShortcutItem(title: "Zoom In", keys: "⌘ +", category: "Zoom"),
        ShortcutItem(title: "Zoom Out", keys: "⌘ -", category: "Zoom"),
        ShortcutItem(title: "Reset Zoom", keys: "⌘ 0", category: "Zoom"),
        
        // Tools
        ShortcutItem(title: "Toggle Find in Page", keys: "⌘ F", category: "Tools"),
        ShortcutItem(title: "Toggle Tab Search", keys: "⌘ K", category: "Tools"),
        ShortcutItem(title: "Copy Page URL", keys: "⇧ ⌘ C", category: "Tools"),
    ]
    
    private var filteredShortcuts: [ShortcutItem] {
        if searchText.isEmpty {
            return allShortcuts
        } else {
            return allShortcuts.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.keys.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedShortcuts: [String: [ShortcutItem]] {
        Dictionary(grouping: filteredShortcuts) { $0.category }
    }
    
    private var sortedCategories: [String] {
        groupedShortcuts.keys.sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shortcuts")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                TextField("Search Shortcuts", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if filteredShortcuts.isEmpty {
                        Text("No shortcuts found.")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(sortedCategories, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 20)
                                
                                ForEach(groupedShortcuts[category] ?? []) { item in
                                    HStack(spacing: 12) {
                                        Text(item.title)
                                            .font(.system(size: 14, weight: .medium))
                                        
                                        Spacer()
                                        
                                        Text(item.keys)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.primary.opacity(0.08))
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
