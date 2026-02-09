//
//  SessionPersistence.swift
//  Swift Browser
//
//  Session persistence for saving and restoring tabs across app launches.
//  Private space tabs are intentionally NOT persisted.
//

import Foundation
import Combine
import SwiftUI

/// Represents a lightweight, serializable version of a tab
struct PersistedTab: Codable {
    let id: UUID
    let spaceId: UUID
    let title: String
    let url: String
    let lastUsedAt: Date
}

/// Represents the complete session state
struct PersistedSession: Codable {
    let tabs: [PersistedTab]
    let currentTabIndex: Int
    let activeSpaceId: UUID?
    let timestamp: Date
}

/// Manages saving and loading of browser sessions
class SessionPersistence {
    static let shared = SessionPersistence()

    private let fileManager = FileManager.default
    private var saveWorkItem: DispatchWorkItem?

    private init() {}

    /// Returns the URL for the session file in Application Support
    private var sessionFileURL: URL? {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let appFolder = appSupport.appendingPathComponent("SwiftBrowser", isDirectory: true)

        if !fileManager.fileExists(atPath: appFolder.path) {
            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }

        return appFolder.appendingPathComponent("session.json")
    }

    /// Saves the current session to disk (debounced)
    func saveSession(tabs: [BrowserTab], currentTab: BrowserTab?, activeSpaceId: UUID?) {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave(tabs: tabs, currentTab: currentTab, activeSpaceId: activeSpaceId)
        }

        saveWorkItem = workItem

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    /// Immediately saves the session (for app termination)
    func saveSessionImmediately(tabs: [BrowserTab], currentTab: BrowserTab?, activeSpaceId: UUID?) {
        saveWorkItem?.cancel()
        performSave(tabs: tabs, currentTab: currentTab, activeSpaceId: activeSpaceId)
    }

    private func performSave(tabs: [BrowserTab], currentTab: BrowserTab?, activeSpaceId: UUID?) {
        let privateSpaceIds = Set(SpaceManager.shared.spaces.filter { $0.isPrivate }.map { $0.id })
        let persistableTabs = tabs.filter { !privateSpaceIds.contains($0.spaceId) }

        let persistedTabs = persistableTabs.map { tab in
            PersistedTab(
                id: tab.id,
                spaceId: tab.spaceId,
                title: tab.title,
                url: tab.url,
                lastUsedAt: tab.lastUsedAt
            )
        }

        let currentTabIndex: Int = {
            guard let currentTab = currentTab else { return 0 }
            if privateSpaceIds.contains(currentTab.spaceId) {
                return 0
            }
            return persistableTabs.firstIndex { $0.id == currentTab.id } ?? 0
        }()

        let persistableActiveSpaceId: UUID? = {
            guard let activeSpaceId = activeSpaceId else { return nil }
            let space = SpaceManager.shared.spaces.first { $0.id == activeSpaceId }
            return space?.isPrivate == true ? nil : activeSpaceId
        }()

        let session = PersistedSession(
            tabs: persistedTabs,
            currentTabIndex: currentTabIndex,
            activeSpaceId: persistableActiveSpaceId,
            timestamp: Date()
        )

        guard let fileURL = sessionFileURL else { return }

        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: fileURL, options: .atomic)
            try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
            print("SessionPersistence: Saved \(persistedTabs.count) tabs")
        } catch {
            print("SessionPersistence: Failed to save session - \(error)")
        }
    }

    /// Loads the last saved session
    func loadSession() -> PersistedSession? {
        guard let fileURL = sessionFileURL,
              fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let session = try JSONDecoder().decode(PersistedSession.self, from: data)
            print("SessionPersistence: Restored \(session.tabs.count) tabs")
            return session
        } catch {
            print("SessionPersistence: Failed to load session - \(error)")
            return nil
        }
    }

    /// Clears the saved session
    func clearSession() {
        saveWorkItem?.cancel()

        if let fileURL = sessionFileURL {
            try? fileManager.removeItem(at: fileURL)
        }

        print("SessionPersistence: Session cleared")
    }
}
