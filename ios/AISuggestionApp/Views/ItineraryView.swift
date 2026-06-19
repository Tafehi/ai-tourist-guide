import SwiftUI

struct ItineraryView: View {
    let itinerary: Itinerary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if !itinerary.hotels.isEmpty { hotelsSection }
                daysSection
                if !itinerary.packingTips.isEmpty { packingSection }
                if let cost = itinerary.estimatedTotalCost { costSection(cost) }
            }
            .padding()
        }
        .navigationTitle(itinerary.destination)
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(itinerary.durationDays) days", systemImage: "calendar")
                Spacer()
                Label(itinerary.budgetLevel.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "banknote")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(itinerary.summary)
                .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var hotelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hotels")
                .font(.headline)
            ForEach(itinerary.hotels) { hotel in
                HStack {
                    VStack(alignment: .leading) {
                        Text(hotel.name).font(.subheadline).fontWeight(.medium)
                        Text(hotel.area).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(hotel.priceRange).font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var daysSection: some View {
        ForEach(itinerary.days) { day in
            DaySection(day: day)
        }
    }

    private var packingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Packing Tips")
                .font(.headline)
            ForEach(itinerary.packingTips, id: \.self) { tip in
                Label(tip, systemImage: "checkmark.circle")
                    .font(.subheadline)
            }
        }
    }

    private func costSection(_ cost: String) -> some View {
        HStack {
            Text("Estimated Total")
                .font(.headline)
            Spacer()
            Text(cost)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
