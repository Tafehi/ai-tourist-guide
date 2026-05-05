import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Library")
                    .font(.title)
                Text("Download and manage city packs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
