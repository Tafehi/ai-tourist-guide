import Foundation

struct GenerateResponse: Codable {
    let success: Bool
    let itinerary: Itinerary?
    let error: String?
    let cached: Bool
    let modelUsed: String?
    let creditsRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case success, itinerary, error, cached
        case modelUsed = "model_used"
        case creditsRemaining = "credits_remaining"
    }
}

struct Itinerary: Codable, Identifiable, Hashable {
    var id: String { "\(destination)-\(durationDays)" }

    let destination: String
    let durationDays: Int
    let budgetLevel: String
    let summary: String
    let hotels: [HotelSuggestion]
    let days: [DayPlan]
    let packingTips: [String]
    let estimatedTotalCost: String?

    enum CodingKeys: String, CodingKey {
        case destination, summary, hotels, days
        case durationDays = "duration_days"
        case budgetLevel = "budget_level"
        case packingTips = "packing_tips"
        case estimatedTotalCost = "estimated_total_cost"
    }
}

struct DayPlan: Codable, Identifiable, Hashable {
    var id: Int { dayNumber }

    let dayNumber: Int
    let date: String
    let activities: [Activity]

    enum CodingKeys: String, CodingKey {
        case date, activities
        case dayNumber = "day_number"
    }
}

struct Activity: Codable, Identifiable, Hashable {
    var id: String { "\(time)-\(title)" }

    let time: String
    let title: String
    let description: String
    let location: String
    let costEstimate: String?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case time, title, description, location
        case costEstimate = "cost_estimate"
        case durationMinutes = "duration_minutes"
    }
}

struct HotelSuggestion: Codable, Identifiable, Hashable {
    var id: String { name }

    let name: String
    let area: String
    let priceRange: String

    enum CodingKeys: String, CodingKey {
        case name, area
        case priceRange = "price_range"
    }
}
