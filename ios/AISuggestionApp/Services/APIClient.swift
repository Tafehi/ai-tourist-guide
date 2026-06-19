import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let pinningDelegate = CertificatePinningDelegate()

    private init() {
        self.baseURL = AppConfiguration.apiBaseURL
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = AppConfiguration.requestTimeout
        config.timeoutIntervalForResource = AppConfiguration.requestTimeout
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        #if DEBUG
        self.session = URLSession(configuration: config)
        #else
        self.session = URLSession(configuration: config, delegate: pinningDelegate, delegateQueue: nil)
        #endif
    }

    func generateItinerary(_ request: TripRequest) async throws -> GenerateResponse {
        let url = baseURL.appendingPathComponent("itinerary/generate")
        var urlRequest = makeRequest(url: url, method: "POST")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        return try await perform(urlRequest)
    }

    func getCredits() async throws -> CreditsResponse {
        let url = baseURL.appendingPathComponent("itinerary/credits")
        let urlRequest = makeRequest(url: url, method: "GET")
        return try await perform(urlRequest)
    }

    func purchaseCredits(productId: String, transactionId: String) async throws -> CreditsResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("itinerary/credits/purchase"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "product_id", value: productId),
            URLQueryItem(name: "transaction_id", value: transactionId),
        ]
        let urlRequest = makeRequest(url: components.url!, method: "POST")
        return try await perform(urlRequest)
    }

    private func makeRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIdentifier.current, forHTTPHeaderField: "X-Device-ID")

        if let tokenData = KeychainService.load(key: "device_auth_token"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .serverCertificateUntrusted {
            throw APIError.certificatePinningFailed
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 402:
            throw APIError.noCredits
        case 400:
            if let errorBody = try? JSONDecoder().decode(ErrorDetail.self, from: data) {
                throw APIError.invalidRequest(errorBody.detail)
            }
            throw APIError.invalidRequest("Invalid request")
        default:
            throw APIError.serverError
        }
    }
}

private struct ErrorDetail: Decodable {
    let detail: String
}
