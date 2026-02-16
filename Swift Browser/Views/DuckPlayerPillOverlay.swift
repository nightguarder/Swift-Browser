//
//  DuckPlayerPillOverlay.swift
//  Swift Browser
//
//  Native SwiftUI pill overlay for Duck Player on YouTube pages.
//  Replaces the JavaScript-injected DOM button with a native overlay.
//

import SwiftUI

/// A native SwiftUI pill overlay that appears on YouTube video pages
/// when Duck Player is in "Ask Every Time" mode.
struct DuckPlayerPillOverlay: View {
    @ObservedObject var manager: DuckPlayerManager
    @State private var isHovered = false
    
    var body: some View {
        Group {
            if manager.shouldShowOverlay, let videoID = manager.overlayVideoID {
                VStack(spacing: 6) {
                    // Main pill button
                    Button(action: {
                        manager.openOverlayVideo()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 18))
                            Text("Open in Duck Player")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#de5833"))
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
                    .onHover { hovering in
                        isHovered = hovering
                    }
                    .accessibilityLabel("Open video in Duck Player")
                    .accessibilityHint("Opens the current YouTube video in Duck Player for privacy protection")
                    .accessibilityIdentifier("duckPlayerPillButton")
                    
                    // Dismiss link
                    Button(action: {
                        manager.dismissOverlay()
                    }) {
                        Text("Don't show this again")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Don't show Duck Player button again")
                }
                .padding(.bottom, 20)
                .padding(.trailing, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity
                ))
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
