import SwiftUI

@main
struct AISuggestionAppApp: App {
    @State private var creditsViewModel = CreditsViewModel()
    @State private var attestService = AppAttestService()
    @State private var isCompromised = false
    @State private var isAuthenticating = true
    @State private var authError: String?

    var body: some Scene {
        WindowGroup {
            if isCompromised {
                ContentUnavailableView(
                    "Security Check Failed",
                    systemImage: "exclamationmark.shield.fill",
                    description: Text("This app cannot run on a modified device.")
                )
            } else if isAuthenticating {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Securing connection...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .task { await authenticate() }
            } else if let error = authError {
                ContentUnavailableView(
                    "Connection Failed",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error)
                )
            } else {
                TripFormView()
                    .environment(creditsViewModel)
            }
        }
    }

    init() {
        _isCompromised = State(initialValue: IntegrityCheck.isCompromised)
    }

    private func authenticate() async {
        do {
            try await attestService.ensureAuthenticated()
        } catch {
            authError = error.localizedDescription
        }
        isAuthenticating = false
    }
}
