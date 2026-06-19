import SwiftUI
import StoreKit

struct CreditsView: View {
    @Environment(CreditsViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                creditsHeader

                if viewModel.storeService.products.isEmpty {
                    ProgressView("Loading products...")
                } else {
                    productsList
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Trip Credits")
            .task {
                await viewModel.loadProducts()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var creditsHeader: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.credits)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
            Text("trips remaining")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var productsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.storeService.products, id: \.id) { product in
                ProductRow(product: product) {
                    Task { await viewModel.purchase(product) }
                }
            }
        }
    }
}

struct ProductRow: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: action) {
                Text(product.displayPrice)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
