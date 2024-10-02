import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var isPurchasing = false  // Indicator for the purchasing process
    @State private var isLoading = true      // Indicator for loading subscriptions
    @State private var showAlert = false     // For showing errors
    @State private var alertMessage = ""     // Error message

    var body: some View {
        VStack {
            Text("Subscription Management")
                .font(.largeTitle)
                .padding(.top)

            if isLoading {
                ProgressView("Loading subscriptions...")
                    .font(.headline)
                    .padding()
            } else {
                // Displaying subscription status
                if let subscriptionStatus = purchaseManager.subscriptionStatus {
                    switch subscriptionStatus.state {
                    case .subscribed:
                        subscribedView(status: subscriptionStatus)
                    case .expired:
                        expiredView(status: subscriptionStatus)
                    case .inGracePeriod:
                        gracePeriodView(status: subscriptionStatus)
                    case .revoked:
                        revokedView(status: subscriptionStatus)
                    default:
                        notSubscribedView()
                    }
                } else {
                    notSubscribedView()
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            print(purchaseManager.subscriptionStatus?.state)
            Task {
                do {
                    try await purchaseManager.updateCustomerProductStatus()
                } catch {
                    alertMessage = "Error updating subscription status: \(error.localizedDescription)"
                    showAlert = true
                }
                isLoading = false  // Finished loading
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
        }
    }

    // View for active subscription
    private func subscribedView(status: Product.SubscriptionInfo.Status) -> some View {
        VStack {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
                .padding(.bottom)

            Text("Subscription is active!")
                .font(.title)
                .foregroundColor(.green)
                .padding(.bottom)

            if let expirationDate = getExpirationDate(from: status) {
                Text("Expiration date: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            } else {
                Text("Failed to retrieve subscription expiration date.")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.bottom)
            }

            Text("Thank you for your support!")
                .font(.subheadline)
                .padding()
        }
        .cardStyle()
    }

    // View for expired subscription
    private func expiredView(status: Product.SubscriptionInfo.Status) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
                .padding(.bottom)

            Text("Subscription has expired.")
                .font(.title)
                .foregroundColor(.red)
                .padding(.bottom)

            if let expirationDate = getExpirationDate(from: status) {
                Text("Expiration date: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            } else {
                Text("Failed to retrieve subscription expiration date.")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.bottom)
            }

            Text("Subscribe again to continue enjoying benefits.")
                .font(.subheadline)
                .padding(.bottom)

            purchaseButtons()
        }
        .cardStyle()
    }

    // View for grace period
    private func gracePeriodView(status: Product.SubscriptionInfo.Status) -> some View {
        VStack {
            Image(systemName: "clock.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.orange)
                .padding(.bottom)

            Text("Grace Period.")
                .font(.title)
                .foregroundColor(.orange)
                .padding(.bottom)

            Text("Your membership will be renewed soon.")
                .font(.subheadline)
                .padding(.bottom)

            if let expirationDate = getExpirationDate(from: status) {
                Text("Grace period ends: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            } else {
                Text("Failed to retrieve grace period end date.")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.bottom)
            }
        }
        .cardStyle()
    }

    // View for revoked subscription
    private func revokedView(status: Product.SubscriptionInfo.Status) -> some View {
        VStack {
            Image(systemName: "xmark.octagon.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
                .padding(.bottom)

            Text("Subscription has been revoked.")
                .font(.title)
                .foregroundColor(.red)
                .padding(.bottom)

            Text("Please contact support for assistance.")
                .font(.subheadline)
                .padding(.bottom)
        }
        .cardStyle()
    }

    // View for no subscription
    private func notSubscribedView() -> some View {
        VStack {
            Image(systemName: "questionmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
                .padding(.bottom)

            Text("No subscription found.")
                .font(.title)
                .foregroundColor(.gray)
                .padding(.bottom)

            Text("Would you like to subscribe?")
                .font(.subheadline)
                .padding(.bottom)

            purchaseButtons()
        }
        .cardStyle()
    }

    // Buttons for purchasing and restoring subscription
    private func purchaseButtons() -> some View {
        VStack {
            if isPurchasing {
                ProgressView()
                    .padding()
            } else {
                if !purchaseManager.subscriptions.isEmpty {
                    ForEach(purchaseManager.subscriptions) { product in
                        Button(action: {
                            Task {
                                isPurchasing = true
                                do {
                                    try await purchaseManager.purchase(product)
                                    try await purchaseManager.updateCustomerProductStatus()
                                } catch {
                                    alertMessage = "Error during purchase: \(error.localizedDescription)"
                                    showAlert = true
                                }
                                isPurchasing = false
                            }
                        }) {
                            Text("Buy \(product.displayName) for \(product.displayPrice)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 10)
                    }
                } else {
                    Text("No subscriptions found.")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    Task {
                        do {
                            try await purchaseManager.restore()
                            try await purchaseManager.updateCustomerProductStatus()
                        } catch {
                            alertMessage = "Error restoring purchases: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }) {
                    Text("Restore purchases")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    // Function to extract subscription expiration date
    private func getExpirationDate(from status: Product.SubscriptionInfo.Status) -> Date? {
        switch status.transaction {
        case .verified(let transaction):
            return transaction.expirationDate
        case .unverified(_):
            return nil
        }
    }
}

// Extension for general card style
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemGray6)))
            .shadow(radius: 5)
            .padding(.horizontal)
    }
}
