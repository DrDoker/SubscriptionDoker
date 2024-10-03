//
//  SubscriptionDetailView.swift
//  SubscriptionDoker
//
//  Created by Serhii on 03.10.2024.
//


import SwiftUI
import StoreKit

struct SubscriptionDetailView: View {
    @ObservedObject var storeManager = StoreManager.shared
    let product: Product
    
    var body: some View {
        VStack(spacing: 20) {
            Text(product.displayName)
                .font(.largeTitle)
            
            Text(product.description)
                .font(.body)
                .padding()
            
            if storeManager.isPurchasing {
                ProgressView("Идёт покупка...")
            } else {
                Button(action: {
                    Task {
                        await storeManager.purchase(product)
                    }
                }) {
                    Text("Купить за \(product.displayPrice)")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if let errorMessage = storeManager.lastErrorMessage {
                Text("Ошибка: \(errorMessage)")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Подробности")
    }
}
