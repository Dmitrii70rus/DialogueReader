import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let premiumProductID = "dialoguereader.premium.unlock"
    static let freePlayLimit = 3

    @Published private(set) var product: Product?
    @Published private(set) var isPremiumUnlocked = false
    @Published private(set) var isLoading = false
    @Published private(set) var storeMessage: String?

    private var updatesTask: Task<Void, Never>?

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        isLoading = true
        defer { isLoading = false }

        await refreshProducts()
        await refreshPurchasedState()
        startListeningForTransactions()
    }

    func refreshProducts() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
            if product == nil {
                storeMessage = "Premium purchase is currently unavailable."
            }
        } catch {
            storeMessage = "Could not load purchase options. Please try again."
        }
    }

    func purchasePremium() async {
        guard let product else {
            storeMessage = "Premium purchase is currently unavailable."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                isPremiumUnlocked = true
                storeMessage = "Premium unlocked successfully."
            case .userCancelled:
                storeMessage = "Purchase cancelled."
            case .pending:
                storeMessage = "Purchase pending approval."
            @unknown default:
                storeMessage = "Unable to complete purchase."
            }
        } catch {
            storeMessage = "Purchase failed. Please try again."
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedState()
            storeMessage = isPremiumUnlocked ? "Purchases restored." : "No purchases to restore."
        } catch {
            storeMessage = "Restore failed. Please try again."
        }
    }

    private func refreshPurchasedState() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                isPremiumUnlocked = true
                return
            }
        }

        isPremiumUnlocked = false
    }

    private func startListeningForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    if transaction.productID == Self.premiumProductID {
                        isPremiumUnlocked = transaction.revocationDate == nil
                    }
                    await transaction.finish()
                } catch {
                    storeMessage = "Transaction verification failed."
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.unverified
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
