import Foundation

enum DeviceIdentifier {
    private static let keychainKey = "device_identifier"

    static var current: String {
        if let data = KeychainService.load(key: keychainKey),
           let identifier = String(data: data, encoding: .utf8) {
            return identifier
        }
        let newIdentifier = "ios-\(UUID().uuidString)"
        if let data = newIdentifier.data(using: .utf8) {
            _ = KeychainService.save(key: keychainKey, data: data)
        }
        return newIdentifier
    }
}
