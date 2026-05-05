import SwiftUI

struct MapView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "map")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Map")
                    .font(.title)
                Text("Explore nearby points of interest")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Map")
        }
    }
}

#Preview {
    MapView()
}
