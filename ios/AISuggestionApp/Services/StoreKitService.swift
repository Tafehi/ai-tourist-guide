import StoreKit

@Observable
final class StoreKitService {
    private(set) var products: [Product] = []
    private(set) var purchaseInProgress = false

    private let productIdentifiers = [
        "com.aisuggestion.trip.1",
        "com.aisuggestion.trip.3",
        "com.aisuggestion.trip.10",
    ]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
                .sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }
}

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        "Purchase verification failed. Please try again."
    }
}
