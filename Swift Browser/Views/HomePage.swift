//
//  HomePage.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI

public struct GlassEffect: NSViewRepresentable {
    public var material: NSVisualEffectView.Material = .sidebar
    public var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    public init(material: NSVisualEffectView.Material = .sidebar, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct HomePage: View {
    var onSearch: (String) -> Void
    var bookmarks: [Bookmark]
    var isPrivate: Bool = false

    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    init(onSearch: @escaping (String) -> Void, bookmarks: [Bookmark], isPrivate: Bool = false) {
        self.onSearch = onSearch
        self.bookmarks = bookmarks
        self.isPrivate = isPrivate
    }

    public var body: some View {
        ZStack {
            if isPrivate {
                Color.purple.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)
            }
            GlassEffect(material: isPrivate ? .underWindowBackground : .headerView, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()

                if isPrivate {
                    PrivateBranding()
                } else {
                    DefaultBranding()
                }

                SearchField(searchText: $searchText, isSearchFieldFocused: $isSearchFieldFocused, onSearch: onSearch)
                
                if isPrivate {
                    PrivateNotice()
                } else if !bookmarks.isEmpty {
                    FavoritesGrid(bookmarks: bookmarks, onSearch: onSearch)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }
            }
        }
    }
}

struct DefaultBranding: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "swift")
                .font(AppFont.heroIcon)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Swift Browser")
                .font(AppFont.hero)
                .foregroundStyle(.primary)
        }
    }
}

struct PrivateBranding: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(.purple)
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Private Space")
                .font(AppFont.hero)
                .foregroundStyle(.primary)
        }
    }
}

struct PrivateNotice: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("You're in a Private Space")
                .font(AppFont.headline)
                .foregroundColor(.purple)
            
            Text("Swift Browser won't save your browsing history, cookies, or site data in this space. Everything is deleted when you close the tab or switch spaces.")
                .font(AppFont.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
        }
        .padding(24)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
    }
}

struct SearchField: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFieldFocused: Bool
    var onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(AppFont.searchField)
            
            TextField("Search or enter website", text: $searchText)
                .onSubmit {
                    if !searchText.isEmpty {
                        onSearch(searchText)
                    }
                }
                .textFieldStyle(.plain)
                .font(AppFont.searchField)
                .disableAutocorrection(true)
                .focused($isSearchFieldFocused)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                if !searchText.isEmpty {
                    onSearch(searchText)
                }
            }) {
                Text("Go")
            }
            .keyboardShortcut(.defaultAction)
            .opacity(0)
            .frame(width: 0, height: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .frame(maxWidth: 600)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FavoritesGrid: View {
    var bookmarks: [Bookmark]
    var onSearch: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Favorites")
                .font(AppFont.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 24) {
                ForEach(bookmarks.prefix(8)) { bm in
                    Button(action: { onSearch(bm.url) }) {
                        VStack(spacing: 12) {
                            ZStack {
                                FaviconView(urlString: bm.url, title: bm.title, size: 28)
                            }
                            .frame(width: 64, height: 64)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            
                            Text(bm.title)
                                .font(AppFont.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundColor(.primary.opacity(0.8))
                        }
                        .padding(8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: 600)
    }
}
