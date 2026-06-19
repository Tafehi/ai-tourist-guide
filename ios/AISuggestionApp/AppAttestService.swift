import CryptoKit
import DeviceCheck
import Foundation

@Observable
final class AppAttestService {
    private(set) var isAuthenticated = false
    private(set) var isAttesting = false
    private let keychainTokenKey = "device_auth_token"
    private let keychainKeyIdKey = "app_attest_key_id"

    var deviceToken: String? {
        guard let data = KeychainService.load(key: keychainTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func ensureAuthenticated() async throws {
        if deviceToken != nil {
            isAuthenticated = true
            return
        }
        try await attestAndRegister()
    }

    private func attestAndRegister() async throws {
        isAttesting = true
        defer { isAttesting = false }

        let service = DCAppAttestService.shared
        guard service.isSupported else {
            throw AttestError.notSupported
        }

        // Step 1: Generate or retrieve attestation key
        let keyId = try await getOrCreateKeyId(service: service)

        // Step 2: Get challenge from backend
        let challenge = try await fetchChallenge()

        // Step 3: Create client data hash
        let clientData = Data(challenge.utf8)
        let clientDataHash = Data(SHA256.hash(data: clientData))

        // Step 4: Attest with Apple
        let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)
        let attestationBase64 = attestation.base64EncodedString()

        // Step 5: Send attestation to backend, receive device token
        let token = try await registerWithBackend(attestation: attestationBase64)

        // Step 6: Store token in Keychain
        if let tokenData = token.data(using: .utf8) {
            _ = KeychainService.save(key: keychainTokenKey, data: tokenData)
        }

        isAuthenticated = true
    }

    private func getOrCreateKeyId(service: DCAppAttestService) async throws -> String {
        if let data = KeychainService.load(key: keychainKeyIdKey),
           let existingKeyId = String(data: data, encoding: .utf8) {
            return existingKeyId
        }

        let keyId = try await service.generateKey()
        if let keyData = keyId.data(using: .utf8) {
            _ = KeychainService.save(key: keychainKeyIdKey, data: keyData)
        }
        return keyId
    }

    private func fetchChallenge() async throws -> String {
        let url = AppConfiguration.apiBaseURL.appendingPathComponent("auth/challenge")
        var request = URLRequest(url: url)
        request.setValue(DeviceIdentifier.current, forHTTPHeaderField: "X-Device-ID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AttestError.challengeFailed
        }

        let decoded = try JSONDecoder().decode(ChallengeResponse.self, from: data)
        return decoded.challenge
    }

    private func registerWithBackend(attestation: String) async throws -> String {
        let url = AppConfiguration.apiBaseURL.appendingPathComponent("auth/attest")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIdentifier.current, forHTTPHeaderField: "X-Device-ID")

        let body = ["attestation": attestation]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AttestError.registrationFailed
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        return decoded.deviceToken
    }
}

enum AttestError: LocalizedError {
    case notSupported
    case challengeFailed
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .notSupported: "App Attest is not supported on this device"
        case .challengeFailed: "Failed to get authentication challenge"
        case .registrationFailed: "Device registration failed"
        }
    }
}

private struct ChallengeResponse: Decodable {
    let challenge: String
}

private struct TokenResponse: Decodable {
    let deviceToken: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
    }
}
