import Foundation
import Security
import LocalAuthentication

public final class KeychainManager {
    public static let shared = KeychainManager()
    
    private let service = "com.swiftbrowser.encryption"
    private let account = "root-encryption-key"
    private var cachedKey: Data?
    
    private init() {}
    
    public func isBiometricAvailable() -> (available: Bool, biometryType: LABiometryType) {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return (canEvaluate, context.biometryType)
    }
    
    public func keyExists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func generateAndStoreKey() throws -> Data {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, 32, pointer.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw KeychainError.keyGenerationFailed
        }
        
        try storeKeyWithBiometricProtection(keyData)
        return keyData
    }
    
    public func storeKeyWithBiometricProtection(_ key: Data) throws {
        try deleteKey()
        
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .userPresence,
            &accessControlError
        ) else {
            throw KeychainError.accessControlCreationFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key,
            kSecAttrAccessControl as String: accessControl
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    public func storeKey(_ key: Data) throws {
        try storeKeyWithBiometricProtection(key)
    }
    
    public func retrieveKeyWithBiometricAuth() async throws -> Data {
        if let cached = cachedKey {
            return cached
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecUseOperationPrompt as String: "Authenticate to unlock Swift Browser"
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }
        
        cachedKey = data
        return data
    }
    
    public func retrieveKey() throws -> Data {
        if let cached = cachedKey {
            return cached
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }
        
        cachedKey = data
        return data
    }
    
    public func deleteKey() throws {
        cachedKey = nil
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    public func clearCachedKey() {
        cachedKey = nil
    }
}

public enum KeychainError: Error, LocalizedError {
    case keyGenerationFailed
    case accessControlCreationFailed
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .accessControlCreationFailed:
            return "Failed to create access control for keychain"
        case .storeFailed(let status):
            return "Failed to store key in keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve key from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete key from keychain: \(status)"
        }
    }
}
