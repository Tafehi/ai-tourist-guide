import SwiftUI

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text(activity.time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(activity.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(activity.location, systemImage: "mappin")
                    if let cost = activity.costEstimate {
                        Label(cost, systemImage: "banknote")
                    }
                    if let duration = activity.durationMinutes {
                        Label("\(duration)min", systemImage: "clock")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
