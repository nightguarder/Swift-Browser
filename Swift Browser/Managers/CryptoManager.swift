import Foundation
import CryptoKit

public final class CryptoManager {
    public static let shared = CryptoManager()
    
    private init() {}
    
    public func encrypt(_ data: Data, using keyData: Data) throws -> Data {
        let key = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        
        return combined
    }
    
    public func decrypt(_ encryptedData: Data, using keyData: Data) throws -> Data {
        let key = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
}

public enum CryptoError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidKey:
            return "Invalid encryption key"
        }
    }
}
