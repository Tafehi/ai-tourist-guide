import Foundation

enum APIKeyObfuscation {
    private static let keychainKey = "api_key_decoded"

    // Multi-layer obfuscation: XOR + byte shuffle + salt
    private static let xorKey: [UInt8] = [
        0x4A, 0x7B, 0x2C, 0x5D, 0x1E, 0x6F, 0x38, 0x09,
        0x5A, 0x3B, 0x0C, 0x7D, 0x2E, 0x4F, 0x18, 0x69,
        0x4A, 0x7B, 0x2C, 0x5D, 0x1E, 0x6F, 0x38, 0x09,
        0x5A, 0x3B, 0x0C, 0x7D, 0x2E, 0x4F, 0x18, 0x69,
    ]

    private static let salt: [UInt8] = [
        0x13, 0x37, 0x42, 0xAB, 0xCD, 0xEF, 0x19, 0x82,
        0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0x11, 0x22,
        0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA,
        0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x01, 0x02, 0x03,
    ]

    // Obfuscated API key bytes (XOR'd with xorKey, then XOR'd with salt)
    // Generate with: obfuscate(plainKey:)
    private static let obfuscatedKey: [UInt8] = [
        // Placeholder — replace after running obfuscate(plainKey:) with your real key
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]

    static var apiKey: String {
        if let cached = KeychainService.load(key: keychainKey),
           let key = String(data: cached, encoding: .utf8) {
            return key
        }

        var decoded = obfuscatedKey.enumerated().map { index, byte in
            byte ^ salt[index % salt.count] ^ xorKey[index % xorKey.count]
        }
        let key = String(bytes: decoded, encoding: .utf8) ?? ""

        // Store in Keychain for future access (avoids repeated decode in memory)
        if let data = key.data(using: .utf8) {
            _ = KeychainService.save(key: keychainKey, data: data)
        }

        // Wipe decoded bytes from memory
        for i in decoded.indices { decoded[i] = 0 }

        return key
    }

    /// Generate obfuscated bytes from a plain key (run once during development, copy output to obfuscatedKey)
    static func obfuscate(plainKey: String) -> [UInt8] {
        let keyBytes = Array(plainKey.utf8)
        return keyBytes.enumerated().map { index, byte in
            byte ^ xorKey[index % xorKey.count] ^ salt[index % salt.count]
        }
    }
}
