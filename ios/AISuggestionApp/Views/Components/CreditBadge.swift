import SwiftUI

struct CreditBadge: View {
    let credits: Int

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: "airplane.circle.fill")
                Text("\(credits)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
        }
    }
}
