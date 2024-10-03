//
//  ActiveSubscriptionView.swift
//  SubscriptionDoker
//
//  Created by Serhii on 03.10.2024.
//


import SwiftUI
import StoreKit

struct ActiveSubscriptionView: View {
    @ObservedObject var storeManager = StoreManager.shared
    @State var isShowingSheet: Bool = false
    
    var body: some View {
        VStack {
            if storeManager.purchasedSubscriptions.isEmpty {
                Text("Нет активных подписок")
                    .font(.headline)
                    .padding()
                Button("Подписаться") {
                    isShowingSheet = true
                }
            } else {
                List(storeManager.purchasedSubscriptions, id: \.id) { product in
                    Text("\(product.displayName) — Активная")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            Test()
        }

        .navigationTitle("Активные подписки")
    }
}
