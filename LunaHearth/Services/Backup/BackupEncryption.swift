import Foundation
import CryptoKit
import CommonCrypto
import Security

/// Standard primitives only; wire format is specified in docs/PORTABLE_BACKUP_FORMAT.md.
/// Actor keeps password derivation and encryption off the main actor.
actor BackupEncryption: BackupEncryptionService {
    static let maximumBytes = 96_000_000
    private static let magic = Data("NLHBK001".utf8)
    private static let rounds: UInt32 = 600_000

    func encrypt(_ plaintext: Data, password: String) throws -> Data {
        guard password.count >= 12, password.utf8.count <= 1024 else { throw PortableBackupError.password }
        guard plaintext.count <= Self.maximumBytes - 56 else { throw PortableBackupError.tooLarge }
        let salt = try random(count: 16)
        let nonce = try random(count: 12)
        var header = Self.magic
        header.append(salt)
        header.append(nonce)
        header.append(contentsOf: [0x00, 0x09, 0x27, 0xC0]) // 600,000, unsigned big-endian
        let key = try derive(password: password, salt: salt)
        let sealed = try AES.GCM.seal(plaintext, using: key, nonce: AES.GCM.Nonce(data: nonce), authenticating: header)
        return header + sealed.ciphertext + sealed.tag
    }

    func decrypt(_ encrypted: Data, password: String) throws -> Data {
        guard encrypted.count <= Self.maximumBytes else { throw PortableBackupError.tooLarge }
        guard encrypted.count >= 56, encrypted.prefix(8) == Self.magic,
              encrypted.subdata(in: 36..<40) == Data([0x00, 0x09, 0x27, 0xC0]) else { throw PortableBackupError.invalid }
        guard !password.isEmpty, password.utf8.count <= 1024 else { throw PortableBackupError.unlock }
        let key = try derive(password: password, salt: encrypted.subdata(in: 8..<24))
        do {
            let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: encrypted.subdata(in: 24..<36)),
                ciphertext: encrypted.subdata(in: 40..<(encrypted.count - 16)), tag: encrypted.suffix(16))
            return try AES.GCM.open(box, using: key, authenticating: encrypted.prefix(40))
        } catch { throw PortableBackupError.unlock }
    }

    private func derive(password: String, salt: Data) throws -> SymmetricKey {
        // UTF-8 bytes exactly as entered: no trimming or platform-specific normalization.
        var input = Array(password.utf8)
        var key = [UInt8](repeating: 0, count: 32)
        defer { _ = input.withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) }; _ = key.withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) } }
        let result = input.withUnsafeBytes { pass in
            salt.withUnsafeBytes { saltBytes in
                key.withUnsafeMutableBytes { output in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), pass.baseAddress?.assumingMemoryBound(to: Int8.self), input.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), Self.rounds,
                        output.baseAddress?.assumingMemoryBound(to: UInt8.self), 32)
                }
            }
        }
        guard result == kCCSuccess else { throw PortableBackupError.invalid }
        return SymmetricKey(data: key)
    }

    private func random(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        guard SecRandomCopyBytes(kSecRandomDefault, count, &bytes) == errSecSuccess else { throw PortableBackupError.invalid }
        return Data(bytes)
    }
}
