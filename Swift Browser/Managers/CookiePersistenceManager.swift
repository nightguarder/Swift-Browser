import Foundation
import WebKit
import Combine

public final class CookiePersistenceManager: ObservableObject {
    public static let shared = CookiePersistenceManager()
    
    private let fileManager = FileManager.default
    private var encryptionKey: Data?
    private var cookieCache: [UUID: [HTTPCookie]] = [:]
    
    private var encryptedCookiesDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let browserDir = appSupport.appendingPathComponent("Swift Browser", isDirectory: true)
        return browserDir.appendingPathComponent("encrypted-cookies", isDirectory: true)
    }
    
    private init() {
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: encryptedCookiesDirectory.path) {
            try? fileManager.createDirectory(at: encryptedCookiesDirectory, withIntermediateDirectories: true)
        }
    }
    
    public func setEncryptionKey(_ key: Data) {
        self.encryptionKey = key
    }
    
    public func hasEncryptionKey() -> Bool {
        return encryptionKey != nil
    }
    
    public func saveCookiesSync(_ cookies: [HTTPCookie], for spaceId: UUID) {
        cookieCache[spaceId] = cookies
        
        guard let key = encryptionKey else {
            #if DEBUG
            print("DEBUG: No encryption key, skipping cookie save")
            #endif
            return
        }
        
        do {
            let cookieData = serializeCookies(cookies)
            let encryptedData = try CryptoManager.shared.encrypt(cookieData, using: key)
            try encryptedData.write(to: cookieFileURL(for: spaceId))
            
            #if DEBUG
            print("DEBUG: Saved \(cookies.count) cookies for space \(spaceId)")
            #endif
        } catch {
            #if DEBUG
            print("DEBUG: Failed to save cookies: \(error)")
            #endif
        }
    }
    
    public func loadCookiesSync(for spaceId: UUID) -> [HTTPCookie] {
        if let cached = cookieCache[spaceId] {
            return cached
        }
        
        guard let key = encryptionKey else {
            #if DEBUG
            print("DEBUG: No encryption key, returning empty cookies")
            #endif
            return []
        }
        
        let fileURL = cookieFileURL(for: spaceId)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            #if DEBUG
            print("DEBUG: No encrypted cookie file for space \(spaceId)")
            #endif
            return []
        }
        
        do {
            let encryptedData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let decryptedData = try CryptoManager.shared.decrypt(encryptedData, using: key)
            let cookies = deserializeCookies(decryptedData)
            
            cookieCache[spaceId] = cookies
            
            #if DEBUG
            print("DEBUG: Loaded \(cookies.count) cookies for space \(spaceId)")
            #endif
            
            return cookies
        } catch {
            #if DEBUG
            print("DEBUG: Failed to load cookies: \(error)")
            #endif
            return []
        }
    }
    
    public func hasCache(for spaceId: UUID) -> Bool {
        return cookieCache[spaceId] != nil
    }
    
    public func getCachedCookies(for spaceId: UUID) -> [HTTPCookie]? {
        return cookieCache[spaceId]
    }
    
    private func cookieFileURL(for spaceId: UUID) -> URL {
        return encryptedCookiesDirectory.appendingPathComponent("\(spaceId.uuidString).enc")
    }
    
    public func saveCookies(_ cookies: [HTTPCookie], for spaceId: UUID) {
        cookieCache[spaceId] = cookies
        
        guard let key = encryptionKey else {
            #if DEBUG
            print("DEBUG: No encryption key, skipping cookie save")
            #endif
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let cookieData = self.serializeCookies(cookies)
                let encryptedData = try CryptoManager.shared.encrypt(cookieData, using: key)
                try encryptedData.write(to: self.cookieFileURL(for: spaceId))
                
                #if DEBUG
                print("DEBUG: Saved \(cookies.count) cookies for space \(spaceId)")
                #endif
            } catch {
                #if DEBUG
                print("DEBUG: Failed to save cookies: \(error)")
                #endif
            }
        }
    }
    
    public func loadCookies(for spaceId: UUID, completion: @escaping ([HTTPCookie]) -> Void) {
        if let cached = cookieCache[spaceId] {
            completion(cached)
            return
        }
        
        guard let key = encryptionKey else {
            #if DEBUG
            print("DEBUG: No encryption key, returning empty cookies")
            #endif
            completion([])
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            let fileURL = self.cookieFileURL(for: spaceId)
            
            guard self.fileManager.fileExists(atPath: fileURL.path) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                let encryptedData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                let decryptedData = try CryptoManager.shared.decrypt(encryptedData, using: key)
                let cookies = self.deserializeCookies(decryptedData)
                
                self.cookieCache[spaceId] = cookies
                
                #if DEBUG
                print("DEBUG: Loaded \(cookies.count) cookies for space \(spaceId)")
                #endif
                
                DispatchQueue.main.async {
                    completion(cookies)
                }
            } catch {
                #if DEBUG
                print("DEBUG: Failed to load cookies: \(error)")
                #endif
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    public func preloadAllCookies(for spaces: [Space], completion: @escaping () -> Void) {
        guard let key = encryptionKey else {
            completion()
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion() }
                return
            }
            
            for space in spaces where !space.isPrivate && !space.blockAllCookies {
                let fileURL = self.cookieFileURL(for: space.id)
                
                guard self.fileManager.fileExists(atPath: fileURL.path) else {
                    continue
                }
                
                do {
                    let encryptedData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                    let decryptedData = try CryptoManager.shared.decrypt(encryptedData, using: key)
                    let cookies = self.deserializeCookies(decryptedData)
                    
                    self.cookieCache[space.id] = cookies
                    
                    #if DEBUG
                    print("DEBUG: Preloaded \(cookies.count) cookies for space \(space.id)")
                    #endif
                } catch {
                    #if DEBUG
                    print("DEBUG: Failed to preload cookies for space \(space.id): \(error)")
                    #endif
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    public func injectCookiesIntoDataStore(for space: Space, dataStore: WKWebsiteDataStore, completion: (() -> Void)? = nil) {
        guard !space.isPrivate && !space.blockAllCookies else {
            completion?()
            return
        }
        
        if let cookies = cookieCache[space.id], !cookies.isEmpty {
            let group = DispatchGroup()
            
            for cookie in cookies {
                group.enter()
                dataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    public func deleteCookies(for spaceId: UUID) {
        cookieCache.removeValue(forKey: spaceId)
        
        let fileURL = cookieFileURL(for: spaceId)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            
            #if DEBUG
            print("DEBUG: Deleted encrypted cookies for space \(spaceId)")
            #endif
        }
    }
    
    public func deleteAllCookies() {
        cookieCache.removeAll()
        
        if let contents = try? fileManager.contentsOfDirectory(at: encryptedCookiesDirectory, includingPropertiesForKeys: nil) {
            for file in contents {
                try? fileManager.removeItem(at: file)
            }
        }
        
        #if DEBUG
        print("DEBUG: Deleted all encrypted cookie files")
        #endif
    }
    
    private func serializeCookies(_ cookies: [HTTPCookie]) -> Data {
        var cookieDicts: [[String: Any]] = []
        
        for cookie in cookies {
            let properties = cookie.properties ?? [:]
            var dict: [String: Any] = [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
                "secure": cookie.isSecure,
                "session": cookie.isSessionOnly
            ]
            
            if let expiresDate = cookie.expiresDate {
                dict["expires"] = expiresDate.timeIntervalSince1970
            }
            
            if let version = properties[.version] as? Int {
                dict["version"] = version
            }
            
            cookieDicts.append(dict)
        }
        
        return (try? JSONSerialization.data(withJSONObject: cookieDicts, options: [])) ?? Data()
    }
    
    private func deserializeCookies(_ data: Data) -> [HTTPCookie] {
        guard let cookieDicts = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            return []
        }
        
        var cookies: [HTTPCookie] = []
        
        for dict in cookieDicts {
            guard let name = dict["name"] as? String,
                  let value = dict["value"] as? String,
                  let domain = dict["domain"] as? String,
                  let path = dict["path"] as? String else {
                continue
            }
            
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
                .secure: (dict["secure"] as? Bool) ?? false,
                .discard: (dict["session"] as? Bool) ?? true
            ]
            
            if let expiresInterval = dict["expires"] as? TimeInterval {
                let expiresDate = Date(timeIntervalSince1970: expiresInterval)
                properties[.expires] = expiresDate
            }
            
            if let version = dict["version"] as? Int {
                properties[.version] = version
            }
            
            if let cookie = HTTPCookie(properties: properties) {
                cookies.append(cookie)
            }
        }
        
        return cookies
    }
}
