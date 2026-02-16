//
//  DownloadManager.swift
//  Swift Browser
//
//  Singleton manager for handling all download operations.
//

import Foundation
import WebKit
import Combine
import AppKit

/// Singleton manager for handling all downloads
public final class DownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    public static let shared = DownloadManager()
    
    @Published public var downloads: [DownloadTask] = []
    @Published public var hasActiveDownloads: Bool = false
    @Published public var activeDownloadCount: Int = 0
    @Published public var completedDownloadCount: Int = 0
    @Published public var overallProgress: Double = 0.0
    
    /// The default download directory (Downloads folder)
    public let defaultDownloadDirectory: URL
    
    // Mapping of active WKDownload objects to their tasks to keep them alive and handle delegates
    private var activeDownloads: [WKDownload: DownloadTask] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        // Set default download directory to user's Downloads folder
        let fileManager = FileManager.default
        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            self.defaultDownloadDirectory = downloadsURL
        } else {
            // Fallback to documents directory
            self.defaultDownloadDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        super.init()
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Monitor downloads array for changes
        $downloads
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAggregatedState()
            }
            .store(in: &cancellables)
    }
    
    private func updateAggregatedState() {
        // Update counts
        let activeTasks = downloads.filter { $0.isActive }
        let completedTasks = downloads.filter { $0.isCompleted }
        
        hasActiveDownloads = !activeTasks.isEmpty
        activeDownloadCount = activeTasks.count
        completedDownloadCount = completedTasks.count
        
        // Calculate overall progress
        if activeTasks.isEmpty {
            overallProgress = 0.0
        } else {
            let totalProgress = activeTasks.reduce(0.0) { $0 + $1.progress }
            overallProgress = totalProgress / Double(activeTasks.count)
        }
    }
    
    /// Start a new download from a WKDownload object
    @discardableResult
    public func startDownload(from download: WKDownload, suggestedFilename: String) -> DownloadTask {
        let task = DownloadTask(
            originalURL: download.originalRequest?.url ?? URL(string: "about:blank")!,
            suggestedFilename: suggestedFilename
        )
        
        // Set self as delegate for the download
        download.delegate = self
        activeDownloads[download] = task
        
        task.associate(with: download)
        
        DispatchQueue.main.async { [weak self] in
            self?.downloads.append(task)
            self?.updateAggregatedState()
            NotificationCenter.default.post(name: .toggleDownloadsPopover, object: nil)
        }
        
        return task
    }
    
    // MARK: - WKDownloadDelegate
    
    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let destinationURL = defaultDownloadDirectory.appendingPathComponent(suggestedFilename)
        
        // Handle file name conflicts by appending a number
        var finalURL = destinationURL
        var counter = 1
        let fileManager = FileManager.default
        
        while fileManager.fileExists(atPath: finalURL.path) {
            let fileExtension = destinationURL.pathExtension
            let fileNameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
            finalURL = defaultDownloadDirectory
                .appendingPathComponent("\(fileNameWithoutExtension) (\(counter))")
                .appendingPathExtension(fileExtension)
            counter += 1
        }
        
        // Store the final destination in the task
        if let task = activeDownloads[download] {
            DispatchQueue.main.async {
                task.localFileURL = finalURL
            }
        }
        
        completionHandler(finalURL)
    }
    
    public func download(_ download: WKDownload, didReceiveTotalBytes totalBytes: Int64, bytesReceived: Int64) {
        if let task = activeDownloads[download] {
            DispatchQueue.main.async {
                task.updateProgress(bytesReceived: bytesReceived, totalBytes: totalBytes)
                self.updateAggregatedState()
            }
        }
    }
    
    public func downloadDidFinish(_ download: WKDownload) {
        if let task = activeDownloads[download] {
            DispatchQueue.main.async {
                if let destinationURL = task.localFileURL {
                    task.complete(at: destinationURL)
                } else {
                    // Fallback if destination wasn't stored (shouldn't happen)
                    task.state = .failed(NSError(domain: "DownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Destination URL missing"]))
                }
                self.activeDownloads.removeValue(forKey: download)
                self.updateAggregatedState()
            }
        }
    }
    
    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        if let task = activeDownloads[download] {
            DispatchQueue.main.async {
                task.fail(with: error)
                self.activeDownloads.removeValue(forKey: download)
                self.updateAggregatedState()
            }
        }
    }
    
    public func download(_ download: WKDownload, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, decisionHandler: @escaping (WKDownload.RedirectPolicy) -> Void) {
        decisionHandler(.allow)
    }

    // MARK: - Actions
    
    public func clearCompletedDownloads() {
        DispatchQueue.main.async { [weak self] in
            self?.downloads.removeAll { $0.isCompleted || $0.state == .cancelled }
        }
    }
    
    public func clearAllDownloads() {
        downloads.filter { $0.isActive }.forEach { $0.cancel() }
        
        DispatchQueue.main.async { [weak self] in
            self?.downloads.removeAll()
            self?.activeDownloads.removeAll()
        }
    }
    
    public func cancelDownload(_ task: DownloadTask) {
        task.cancel()
    }
    
    public func removeDownload(_ task: DownloadTask) {
        DispatchQueue.main.async { [weak self] in
            self?.downloads.removeAll { $0.id == task.id }
        }
    }
    
    public func openDownloadsFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: defaultDownloadDirectory.path)
    }
}
