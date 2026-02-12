//
//  DownloadsButton.swift
//  Swift Browser
//

import SwiftUI

struct DownloadsButton: View {
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var isShowingPopover = false
    @State private var closeTimer: Timer?
    
    var body: some View {
        Button(action: {
            closeTimer?.invalidate()
            closeTimer = nil
            isShowingPopover.toggle()
        }) {
            ZStack {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16, weight: .medium))
                
                if downloadManager.hasActiveDownloads {
                    // Small dot indicator for active downloads
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
        .help("Downloads")
        .popover(isPresented: $isShowingPopover) {
            DownloadsPopover(downloadManager: downloadManager, isPresented: $isShowingPopover)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleDownloadsPopover)) { _ in
            if !isShowingPopover {
                isShowingPopover = true
                closeTimer?.invalidate()
                closeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    isShowingPopover = false
                }
            }
        }
        .onDisappear {
            closeTimer?.invalidate()
            closeTimer = nil
        }
    }
}
