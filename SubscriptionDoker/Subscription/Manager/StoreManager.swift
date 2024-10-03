//
//  StoreManager.swift
//  SubscriptionDoker
//
//  Created by Serhii on 02.10.2024.
//


import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    
    // Singleton для глобального доступа
    static let shared = StoreManager()
    
    // Продукты для подписки
    @Published private(set) var subscriptions: [Product] = []
    
    // Приобретенные подписки пользователя
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    // Указатель на то, что покупка выполняется
    @Published private(set) var isPurchasing: Bool = false
    
    // Сообщение об ошибке для UI
    @Published private(set) var lastErrorMessage: String? = nil
    
    // Слушатель транзакций
    private var transactionListenerTask: Task<Void, Never>? = nil
    
    // Список идентификаторов продуктов
    private let productIDs: Set<String>
    
    // Инициализация с передачей списка product IDs
    private init(productIDs: Set<String> = ["com.tsodev.SubscriptionDoker.premiumMonth", "com.tsodev.SubscriptionDoker.premiumYear"]) {
        self.productIDs = productIDs
        transactionListenerTask = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchasedSubscriptions()
        }
    }
    
    deinit {
        transactionListenerTask?.cancel()
    }
    
    // Загрузка продуктов из App Store
    func fetchProducts() async {
        do {
            let products = try await Product.products(for: Array(productIDs))
            subscriptions = products
        } catch {
            handleError(error, message: "Не удалось загрузить продукты. Попробуйте позже.")
        }
    }
    
    // Покупка выбранного продукта
    func purchase(_ product: Product) async {
        guard !isPurchasing else {
            lastErrorMessage = "Покупка уже выполняется."
            return
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            try await handlePurchaseResult(result)
        } catch {
            handleError(error, message: "Не удалось завершить покупку. Попробуйте снова.")
        }
    }
    
    // Восстановление покупок пользователя
    func restorePurchases() async {
        do {
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                await transaction.finish()
            }
            await updatePurchasedSubscriptions()
        } catch {
            handleError(error, message: "Не удалось восстановить покупки. Попробуйте позже.")
        }
    }
    
    // Обработка результата покупки
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async throws {
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedSubscriptions()
            await transaction.finish()
        case .pending:
            lastErrorMessage = "Покупка в ожидании. Пожалуйста, подождите."
        case .userCancelled:
            lastErrorMessage = "Покупка отменена."
        @unknown default:
            lastErrorMessage = "Произошла неизвестная ошибка при покупке."
        }
    }
    
    // Проверка подлинности транзакции
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let signedType):
            return signedType
        }
    }
    
    // Обновление списка приобретенных подписок
    private func updatePurchasedSubscriptions() async {
        var newPurchasedSubscriptions: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable,
                   let product = subscriptions.first(where: { $0.id == transaction.productID }) {
                    newPurchasedSubscriptions.append(product)
                }
            } catch {
                handleError(error, message: "Не удалось обновить подписки.")
            }
        }
        
        purchasedSubscriptions = newPurchasedSubscriptions
    }
    
    // Слушатель для транзакций
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    if transaction?.productType == .autoRenewable {
                        await self?.updatePurchasedSubscriptions()
                    }
                    await transaction?.finish()
                } catch {
                    await self?.handleError(error, message: "Не удалось подтвердить транзакцию.")
                }
            }
        }
    }
    
    // Обработка ошибок
    private func handleError(_ error: Error, message: String) {
        print("Error: \(error.localizedDescription)")
        lastErrorMessage = message
    }
    
    // Проверка, есть ли активная подписка на продукт
    func isSubscribed(to productID: String) -> Bool {
        return purchasedSubscriptions.contains(where: { $0.id == productID })
    }
}
