import Foundation

struct CreditsResponse: Codable {
    let creditsRemaining: Int

    enum CodingKeys: String, CodingKey {
        case creditsRemaining = "credits_remaining"
    }
}
