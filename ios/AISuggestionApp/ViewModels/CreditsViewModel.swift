import Foundation
import StoreKit

@Observable
final class CreditsViewModel {
    var credits: Int = 0
    var isLoading = false
    var showPurchaseSheet = false
    var errorMessage: String?

    let storeService = StoreKitService()
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = storeService.listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadCredits() async {
        isLoading = true
        do {
            let response = try await APIClient.shared.getCredits()
            credits = response.creditsRemaining
        } catch {
            credits = 0
        }
        isLoading = false
    }

    func loadProducts() async {
        await storeService.loadProducts()
    }

    func purchase(_ product: Product) async {
        do {
            guard let transaction = try await storeService.purchase(product) else { return }

            let response = try await APIClient.shared.purchaseCredits(
                productId: product.id,
                transactionId: String(transaction.id)
            )
            credits = response.creditsRemaining
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch let error as StoreError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
    }
}
