import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "gear")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.title)
                Text("Configure your tour guide experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
