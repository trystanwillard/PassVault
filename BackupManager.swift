//
//  BackupManager.swift
//  PlainKey
//
//  Created by Trystan Willard on 8/1/26.
//



import Foundation
import CryptoKit

struct BackupEntry: Codable {
    let id: UUID
    let site: String
    let username: String
    let password: String
}

enum BackupError: Error {
    case noEntries
    case encryptionFailed
    case decryptionFailed
    case wrongPasswordOrCorrupted
}

enum BackupManager {
    private static let saltSize = 16
    
    static func createBackup(entries: [PasswordEntry], exportPassword: String) throws -> Data {
        guard !entries.isEmpty else { throw BackupError.noEntries }
        
        let backupEntries = try entries.map { entry -> BackupEntry in
            let password = try KeychainManager.shared.readPassword(for: entry.id)
            return BackupEntry(id: entry.id, site: entry.site, username: entry.username, password: password)
        }
        
        let jsonData = try JSONEncoder().encode(backupEntries)
        
        var salt = Data(count:saltSize)
        let result = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, saltSize, $0.baseAddress!)
        }
        guard result == errSecSuccess else { throw BackupError.encryptionFailed }
        
        let key = deriveKey(from: exportPassword, salt: salt)
        
        guard let sealedBox = try? AES.GCM.seal(jsonData, using: key),
              let combined = sealedBox.combined else {
            throw BackupError.encryptionFailed
        }
        
        // Output: [salt][encrypted payload] - salt is needed again to derive the same key on import
        return salt + combined
    }
    
    static func restoreBackup(data: Data, exportPassword: String) throws -> [BackupEntry] {
        guard data.count > saltSize else { throw BackupError.wrongPasswordOrCorrupted }
        let salt = Data(data.prefix(saltSize))
        let combined = data.suffix(from: saltSize)
        
        let key = deriveKey(from: exportPassword, salt: salt)
        
        guard let sealedBox = try? AES.GCM.SealedBox(combined: combined),
              let decrypted = try? AES.GCM.open(sealedBox, using: key) else {
            throw BackupError.wrongPasswordOrCorrupted
        }
        
        guard let entries = try? JSONDecoder().decode([BackupEntry].self, from: decrypted) else {
            throw BackupError.decryptionFailed
        }
        
        return entries
    }
    
    private static func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordKey = SymmetricKey(data: Data(password.utf8))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: passwordKey,
            salt: salt,
            info: Data("PlainKeyBackup".utf8),
            outputByteCount: 32
        )
    }
}
