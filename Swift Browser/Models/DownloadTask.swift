//
//  DownloadTask.swift
//  Swift Browser
//
//  Model representing a single download task.
//

import Foundation
import WebKit
import Combine
import AppKit

/// Represents the state of a download
public enum DownloadState: Equatable {
    case pending
    case downloading(progress: Double)
    case completed(URL)
    case failed(Error)
    case cancelled
    
    public static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending),
             (.completed, .completed),
             (.failed, .failed),
             (.cancelled, .cancelled):
            return true
        case (.downloading(let l), .downloading(let r)):
            return l == r
        default:
            return false
        }
    }
}

/// Model representing a single download task
public final class DownloadTask: Identifiable, ObservableObject {
    public let id: UUID
    public let originalURL: URL
    public let suggestedFilename: String
    
    @Published public var state: DownloadState = .pending
    @Published public var bytesReceived: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var localFileURL: URL?
    
    public var progress: Double {
        switch state {
        case .downloading(let prog):
            return prog
        case .completed:
            return 1.0
        default:
            return 0.0
        }
    }
    
    public var isActive: Bool {
        switch state {
        case .pending, .downloading:
            return true
        default:
            return false
        }
    }
    
    public var isCompleted: Bool {
        if case .completed = state {
            return true
        }
        return false
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        if totalBytes > 0 {
            return formatter.string(fromByteCount: bytesReceived) + " / " + formatter.string(fromByteCount: totalBytes)
        } else {
            return formatter.string(fromByteCount: bytesReceived)
        }
    }
    
    public var formattedProgress: String {
        String(format: "%.0f%%", progress * 100)
    }
    
    private weak var download: WKDownload?
    private var resumeData: Data?
    
    public init(id: UUID = UUID(), originalURL: URL, suggestedFilename: String) {
        self.id = id
        self.originalURL = originalURL
        self.suggestedFilename = suggestedFilename
    }
    
    func associate(with download: WKDownload) {
        self.download = download
    }
    
    func updateProgress(bytesReceived: Int64, totalBytes: Int64) {
        self.bytesReceived = bytesReceived
        self.totalBytes = totalBytes
        
        if totalBytes > 0 {
            let progress = Double(bytesReceived) / Double(totalBytes)
            state = .downloading(progress: min(progress, 1.0))
        } else {
            // Indeterminate progress
            state = .downloading(progress: 0.0)
        }
    }
    
    func complete(at localURL: URL) {
        self.localFileURL = localURL
        self.state = .completed(localURL)
    }
    
    func fail(with error: Error) {
        self.state = .failed(error)
    }
    
    func cancel() {
        download?.cancel { [weak self] resumeData in
            self?.resumeData = resumeData
            self?.state = .cancelled
        }
    }
    
    /// Reveal the downloaded file in Finder
    public func revealInFinder() {
        guard let localFileURL = localFileURL else { return }
        NSWorkspace.shared.selectFile(localFileURL.path, inFileViewerRootedAtPath: "")
    }
    
    /// Open the downloaded file
    public func openFile() {
        guard let localFileURL = localFileURL else { return }
        NSWorkspace.shared.open(localFileURL)
    }
}
