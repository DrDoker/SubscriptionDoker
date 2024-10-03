//
//  SubscriptionListView.swift
//  SubscriptionDoker
//
//  Created by Serhii on 03.10.2024.
//


import SwiftUI
import StoreKit

struct SubscriptionListView: View {
    @ObservedObject var storeManager = StoreManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if storeManager.subscriptions.isEmpty {
                    Text("Загрузка подписок...")
                        .font(.headline)
                        .padding()
                } else {
                    List(storeManager.subscriptions, id: \.id) { product in
                        NavigationLink(destination: SubscriptionDetailView(product: product)) {
                            SubscriptionRow(product: product)
                        }
                    }
                }
                
                if let errorMessage = storeManager.lastErrorMessage {
                    Text("Ошибка: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
                
                // Восстановление покупок
                Button(action: {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }) {
                    Text("Восстановить покупки")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .navigationTitle("Подписки")
        }
    }
}


struct SubscriptionRow: View {
    let product: Product
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.subheadline)
            }
            
            Spacer()
            
            Text("\(product.displayPrice)")
                .font(.headline)
            
        }

    }
}
