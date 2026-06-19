import SwiftUI

struct DaySection: View {
    let day: DayPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Day \(day.dayNumber)")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(day.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(day.activities) { activity in
                ActivityCard(activity: activity)
            }
        }
        .padding(.top, 8)
    }
}
