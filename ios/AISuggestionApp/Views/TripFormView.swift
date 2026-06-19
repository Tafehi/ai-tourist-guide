import SwiftUI

struct TripFormView: View {
    @State private var viewModel = TripFormViewModel()
    @Environment(CreditsViewModel.self) private var creditsVM

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination") {
                    HStack {
                        TextField("Where do you want to go?", text: $viewModel.destination)
                            .textContentType(.location)
                        VoiceInputButton(text: $viewModel.destination)
                    }
                    HStack {
                        TextField("Departing from (optional)", text: $viewModel.origin)
                            .textContentType(.location)
                        VoiceInputButton(text: $viewModel.origin)
                    }
                }

                Section("Dates") {
                    DatePicker("Start", selection: $viewModel.startDate, in: Date()..., displayedComponents: .date)
                    DatePicker("End", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                    Text("\(viewModel.durationDays) day\(viewModel.durationDays == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }

                Section("Budget & Style") {
                    Picker("Budget", selection: $viewModel.budget) {
                        ForEach(BudgetLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    Picker("Pace", selection: $viewModel.travelStyle) {
                        ForEach(TravelStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                }

                Section("Interests") {
                    FlowLayout(items: viewModel.availableInterests) { interest in
                        ChipView(
                            title: interest,
                            isSelected: viewModel.interests.contains(interest)
                        ) {
                            if viewModel.interests.contains(interest) {
                                viewModel.interests.remove(interest)
                            } else {
                                viewModel.interests.insert(interest)
                            }
                        }
                    }
                }

                Section("Dietary") {
                    FlowLayout(items: viewModel.availableDietary) { item in
                        ChipView(
                            title: item,
                            isSelected: viewModel.dietaryRestrictions.contains(item)
                        ) {
                            if viewModel.dietaryRestrictions.contains(item) {
                                viewModel.dietaryRestrictions.remove(item)
                            } else {
                                viewModel.dietaryRestrictions.insert(item)
                            }
                        }
                    }
                }

                Section("Notes") {
                    HStack(alignment: .top) {
                        TextField("Any special requests?", text: $viewModel.notes, axis: .vertical)
                            .lineLimit(3...6)
                        VoiceInputButton(text: $viewModel.notes)
                    }
                }

                Section {
                    Button(action: { Task { await viewModel.generate() } }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Generate Itinerary")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .listRowBackground(
                        viewModel.isFormValid ? Color.accentColor : Color.gray.opacity(0.3)
                    )
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("Plan a Trip")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CreditBadge(credits: creditsVM.credits)
                }
            }
            .navigationDestination(item: $viewModel.generatedItinerary) { itinerary in
                ItineraryView(itinerary: itinerary)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await creditsVM.loadCredits()
            }
        }
    }
}

struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: View {
    let items: [String]
    let content: (String) -> ChipView

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
