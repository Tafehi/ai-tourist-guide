import Foundation

struct TripRequest: Codable {
    let destination: String
    let origin: String?
    let startDate: String
    let endDate: String
    let budget: BudgetLevel
    let travelStyle: TravelStyle
    let interests: [String]
    let dietaryRestrictions: [String]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case destination, origin, budget, interests, notes
        case startDate = "start_date"
        case endDate = "end_date"
        case travelStyle = "travel_style"
        case dietaryRestrictions = "dietary_restrictions"
    }
}

enum BudgetLevel: String, Codable, CaseIterable, Identifiable {
    case budget
    case midRange = "mid_range"
    case luxury

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .budget: "Budget"
        case .midRange: "Mid Range"
        case .luxury: "Luxury"
        }
    }
}

enum TravelStyle: String, Codable, CaseIterable, Identifiable {
    case relaxed
    case moderate
    case packed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relaxed: "Relaxed"
        case .moderate: "Moderate"
        case .packed: "Packed"
        }
    }
}
