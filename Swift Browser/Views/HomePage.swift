//
//  HomePage.swift
//  Swift Browser
//
//  Created by Nightguarder on 02/02/26.
//

import SwiftUI

// Integrated GlassEffect here to avoid modifying project file manually
struct GlassEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct HomePage: View {
    var onSearch: (String) -> Void
    var bookmarks: [Bookmark]

    @State private var searchText: String = ""

    var body: some View {
        ZStack {
            // Glassmorphic background
            GlassEffect(material: .headerView, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()

                // Hero Section
                HStack(spacing: 16) {
                    Image(systemName: "swift")
                        .font(.system(size: 50, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Swift Browser")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.title3)
                    
                    TextField("Search or enter website", text: $searchText)
                        .onSubmit {
                            if !searchText.isEmpty {
                                onSearch(searchText)
                            }
                        }
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Fix for macOS system beep: Explicitly capture the Enter key
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

                // Speed Dial / Favorites
                if !bookmarks.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Favorites")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 24) {
                            ForEach(bookmarks.prefix(8)) { bm in
                                Button(action: { onSearch(bm.url) }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Color.primary.opacity(0.05))
                                                .frame(width: 64, height: 64)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                            
                                            // Fallback icon until we have favicon fetching
                                            Image(systemName: "safari")
                                                .font(.system(size: 28))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        
                                        Text(bm.title)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .foregroundColor(.primary.opacity(0.8))
                                    }
                                    .padding(8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .onHover { hovering in
                                    // Could add hover effect here later
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 600)
                }

                Spacer()
            }
            .padding()
        }
    }
}
