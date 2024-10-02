import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

@MainActor
final class PurchaseManager: ObservableObject {

    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionStatus: Product.SubscriptionInfo.Status?

    private var updateListenerTask: Task<Void, Error>? = nil

    init() {
        // Loading products from Products.plist
        Config.loadProductsFromPlist()

        self.updateListenerTask = self.listenForTransactions()
        Task {
            await self.fetchProducts()
            do {
                try await self.updateCustomerProductStatus()
            } catch {
                print("Error updating product status: \(error)")
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    print("Transaction update: \(transaction)")
                    try await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    deinit {
        self.updateListenerTask?.cancel()
    }

    func fetchProducts() async {
        let productIDs = Array(Config.productIdentifiers.keys)
//        print("Product IDs: \(productIDs)")
        do {
            let storeProducts = try await Product.products(for: productIDs)
//            print("Fetched Products: \(storeProducts)")
            for product in storeProducts {
                switch product.type {
                case .autoRenewable:
                    self.subscriptions.append(product)
                default: continue
                }
            }
//            print("Subscriptions: \(self.subscriptions)")
        } catch {
            print("Error fetching products: \(error)")
        }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        print("Initiating purchase for product: \(product.id)")
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            print("Purchase successful, transaction: \(transaction)")
            await transaction.finish()
            return transaction
        case .userCancelled:
            print("User canceled the purchase.")
            return nil
        case .pending:
            print("Purchase is pending.")
            return nil
        @unknown default:
            print("Unknown purchase result.")
            return nil
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    func updateCustomerProductStatus() async throws {
        var purchasedSubscriptions: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try self.checkVerified(result)

                if transaction.productType == .autoRenewable {
                    if let subscription = self.subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                }
            } catch {
                print("Error verifying transaction: \(error)")
            }
        }

        self.purchasedSubscriptions = purchasedSubscriptions

        // Fetching subscription statuses
        if !self.subscriptions.isEmpty {
            var allStatuses: [Product.SubscriptionInfo.Status] = []

            for product in self.subscriptions {
                do {
                    if let statuses = try await product.subscription?.status {
                        allStatuses.append(contentsOf: statuses)
//                        print("Statuses for product \(product.id): \(statuses)")
                    }
                } catch {
                    print("Error fetching subscription status for product \(product.id): \(error)")
                }
            }

            // Finding the most recent status
            if let latestStatus = allStatuses.max(by: { status1, status2 in
                let date1 = getExpirationDate(from: status1) ?? Date.distantPast
                let date2 = getExpirationDate(from: status2) ?? Date.distantPast
                return date1 < date2
            }) {
                self.subscriptionStatus = latestStatus
//                print("Latest subscription status: \(latestStatus)")
            } else {
                self.subscriptionStatus = nil
                print("No active subscription statuses found.")
            }
        } else {
            self.subscriptionStatus = nil
            print("Subscription array is empty.")
        }
    }

    // Function to extract subscription expiration date from status
    private func getExpirationDate(from status: Product.SubscriptionInfo.Status) -> Date? {
        switch status.transaction {
        case .verified(let transaction):
            return transaction.expirationDate
        case .unverified(_):
            return nil
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        try await self.updateCustomerProductStatus()
    }
}
