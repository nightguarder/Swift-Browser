//
//  DownloadsPopover.swift
//  Swift Browser
//
//  Popover view for managing downloads.
//

import SwiftUI
import AppKit

struct DownloadsPopover: View {
    @ObservedObject var downloadManager: DownloadManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Downloads")
                    .font(.headline)
                
                Spacer()
                
                if downloadManager.hasActiveDownloads {
                    Text("\(downloadManager.activeDownloadCount) downloading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { downloadManager.openDownloadsFolder() }) {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Open Downloads Folder")
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.05))
            
            Divider()
            
            // Downloads List
            if downloadManager.downloads.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No downloads")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(downloadManager.downloads) { download in
                            DownloadRow(download: download, downloadManager: downloadManager)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            
                            if download.id != downloadManager.downloads.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .frame(minWidth: 380, maxWidth: 380)
                .frame(minHeight: 200, maxHeight: 400)
            }
            
            Divider()
            
            // Footer
            HStack {
                if downloadManager.completedDownloadCount > 0 {
                    Button(action: { downloadManager.clearCompletedDownloads() }) {
                        Text("Clear Completed")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(downloadManager.downloads.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.03))
        }
        .frame(width: 380)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

struct DownloadRow: View {
    @ObservedObject var download: DownloadTask
    let downloadManager: DownloadManager
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon based on extension
            fileIcon
                .frame(width: 36, height: 36)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(download.suggestedFilename)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 6) {
                    switch download.state {
                    case .pending:
                        Text("Pending...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                    case .downloading:
                        Text(download.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                    case .completed:
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                    case .failed(let error):
                        Text("Failed: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    
                    case .cancelled:
                        Text("Cancelled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Progress or actions
            HStack(spacing: 8) {
                switch download.state {
                case .downloading:
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .trim(from: 0, to: download.progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))
                        
                        Button(action: { download.cancel() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                case .completed:
                    if isHovering {
                        HStack(spacing: 4) {
                            Button(action: { download.openFile() }) {
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .help("Open File")
                            
                            Button(action: { download.revealInFinder() }) {
                                Image(systemName: "folder")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .help("Show in Finder")
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                    }
                    
                case .failed, .cancelled:
                    Button(action: { downloadManager.removeDownload(download) }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                default:
                    ProgressView()
                        .scaleEffect(0.6)
                }
                
                // Remove button (always visible for completed/failed/cancelled)
                if !download.isActive {
                    Button(action: { downloadManager.removeDownload(download) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1 : 0.5)
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            if download.isCompleted {
                Button(action: { download.openFile() }) {
                    Label("Open", systemImage: "arrow.up.forward")
                }
                
                Button(action: { download.revealInFinder() }) {
                    Label("Show in Finder", systemImage: "folder")
                }
                
                Divider()
            }
            
            Button(action: { downloadManager.removeDownload(download) }) {
                Label("Remove from List", systemImage: "xmark")
            }
            
            if download.isActive {
                Button(action: { download.cancel() }) {
                    Label("Cancel Download", systemImage: "xmark.circle")
                }
            }
        }
    }
    
    private var fileIcon: some View {
        let ext = (download.suggestedFilename as NSString).pathExtension.lowercased()
        
        let iconName: String
        let iconColor: Color
        
        switch ext {
        case "pdf":
            iconName = "doc.text"
            iconColor = .red
        case "jpg", "jpeg", "png", "gif", "bmp", "webp", "heic":
            iconName = "photo"
            iconColor = .blue
        case "mp4", "mov", "avi", "mkv", "webm":
            iconName = "film"
            iconColor = .purple
        case "mp3", "aac", "wav", "flac", "m4a":
            iconName = "music.note"
            iconColor = .pink
        case "zip", "rar", "7z", "tar", "gz":
            iconName = "archivebox"
            iconColor = .orange
        case "dmg", "pkg", "app":
            iconName = "archivebox.fill"
            iconColor = .gray
        case "txt", "md", "rtf":
            iconName = "doc.text"
            iconColor = .primary
        case "swift", "py", "js", "html", "css", "json", "xml":
            iconName = "chevron.left.forwardslash.chevron.right"
            iconColor = .green
        default:
            iconName = "doc"
            iconColor = .primary
        }
        
        return Image(systemName: iconName)
            .font(.system(size: 18))
            .foregroundColor(iconColor)
    }
}
