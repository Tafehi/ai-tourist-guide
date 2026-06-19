import Foundation
import SwiftUI

@Observable
final class TripFormViewModel {
    var destination = ""
    var origin = ""
    var startDate = Date()
    var endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    var budget: BudgetLevel = .midRange
    var travelStyle: TravelStyle = .moderate
    var interests: Set<String> = []
    var dietaryRestrictions: Set<String> = []
    var notes = ""

    var isLoading = false
    var generatedItinerary: Itinerary?
    var errorMessage: String?
    var showError = false

    let availableInterests = [
        "Food", "History", "Nature", "Art", "Nightlife",
        "Shopping", "Adventure", "Culture", "Architecture", "Beach",
    ]

    let availableDietary = [
        "Vegetarian", "Vegan", "Halal", "Kosher", "Gluten-Free",
    ]

    var isFormValid: Bool {
        !destination.isEmpty && endDate > startDate && startDate >= Calendar.current.startOfDay(for: Date())
    }

    var durationDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return days + 1
    }

    func generate() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = TripRequest(
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            origin: origin.isEmpty ? nil : origin.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            budget: budget,
            travelStyle: travelStyle,
            interests: Array(interests),
            dietaryRestrictions: Array(dietaryRestrictions),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try InputValidator.validate(request: request)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
            return
        }

        do {
            let response = try await APIClient.shared.generateItinerary(request)
            if response.success, let itinerary = response.itinerary {
                generatedItinerary = itinerary
            } else {
                errorMessage = response.error ?? "Failed to generate itinerary"
                showError = true
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = "An unexpected error occurred"
            showError = true
        }

        isLoading = false
    }
}
