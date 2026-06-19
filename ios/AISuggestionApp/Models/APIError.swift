import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case noCredits
    case invalidRequest(String)
    case serverError
    case networkError(Error)
    case decodingError(Error)
    case certificatePinningFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid request URL"
        case .unauthorized:
            "Authentication failed. Please restart the app."
        case .noCredits:
            "No trip credits remaining. Purchase a trip pack to continue."
        case .invalidRequest(let message):
            message
        case .serverError:
            "Something went wrong. Please try again."
        case .networkError:
            "Network connection failed. Check your internet and try again."
        case .decodingError:
            "Received an unexpected response. Please try again."
        case .certificatePinningFailed:
            "Secure connection could not be established."
        }
    }
}
